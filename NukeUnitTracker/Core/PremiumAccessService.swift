import Foundation
import Security
import SwiftData

enum PremiumAccessState: Equatable {
    case free
    case connecting
    case verifying
    case verified
    case expired
    case unavailable

    var isWorking: Bool {
        switch self {
        case .connecting, .verifying: true
        default: false
        }
    }
}

/// Coordinates the optional Discord verification flow. The backend owns the
/// Discord OAuth client secret and decides whether a verified member has VIP
/// access. The app stores only its opaque session token in the iOS Keychain.
@MainActor
final class PremiumAccessManager: ObservableObject {
    @Published private(set) var state: PremiumAccessState = .free
    @Published private(set) var lastError: String?

    private let callbackScheme = "nukeunittracker"
    private let callbackHost = "discord-auth"
    private let pendingStateKey = "nuke.discord.pending-state"

    var hasSession: Bool { NukeCredentialStore.accessToken != nil }
    var contentAccessToken: String? { NukeCredentialStore.accessToken }

    func configure(from profile: UserProfile) {
        if profile.premiumAccess == .vip, !profile.hasActiveVIPAccess {
            state = .expired
        } else if profile.hasActiveVIPAccess {
            state = .verified
        } else {
            state = .free
        }
    }

    /// The OAuth flow is opened outside the app. If the user dismisses that
    /// browser instead of completing the callback, make the connect control
    /// available again when the app becomes active.
    func resumeAfterExternalBrowser() {
        guard state == .connecting else { return }
        state = .free
    }

    /// Starts a browser-based Discord login. The caller opens the returned URL;
    /// callback completion is handled through AppEntryView.onOpenURL.
    func beginDiscordVerification() async -> URL? {
        guard let baseURL = CommunityAPIConfiguration.baseURL else {
            lastError = "Discord verification will be available when the Nuke service URL is configured."
            state = .unavailable
            return nil
        }

        state = .connecting
        lastError = nil
        let clientState = UUID().uuidString
        UserDefaults.standard.set(clientState, forKey: pendingStateKey)

        var request = URLRequest(url: baseURL.appending(path: "v1/auth/discord/starts"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(DiscordStartRequest(
            appRedirectURI: "\(callbackScheme)://\(callbackHost)",
            clientState: clientState
        ))

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  (200...299).contains(statusCode) else { throw PremiumAccessError.requestFailed }
            let start = try NukeJSON.makeDecoder().decode(DiscordStartResponse.self, from: data)
            return start.authorizationURL
        } catch {
            state = .unavailable
            lastError = "Discord verification could not start. Check your connection and try again."
            return nil
        }
    }

    func handleCallback(url: URL, profile: UserProfile, in modelContext: ModelContext) async {
        guard url.scheme == callbackScheme, url.host == callbackHost else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let receivedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
              let expectedState = UserDefaults.standard.string(forKey: pendingStateKey),
              receivedState == expectedState else {
            state = .free
            lastError = "That Discord verification link is no longer valid. Please try again."
            return
        }

        if components.queryItems?.contains(where: { $0.name == "error" }) == true {
            UserDefaults.standard.removeObject(forKey: pendingStateKey)
            state = .free
            lastError = "Discord verification was canceled or could not be completed. Please try again when you are ready."
            return
        }

        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            state = .free
            lastError = "Discord verification did not return a secure code. Please try again."
            return
        }

        state = .verifying
        lastError = nil
        UserDefaults.standard.removeObject(forKey: pendingStateKey)

        guard let baseURL = CommunityAPIConfiguration.baseURL else {
            state = .unavailable
            lastError = "The Nuke service URL is missing."
            return
        }

        var request = URLRequest(url: baseURL.appending(path: "v1/auth/discord/exchange"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(DiscordExchangeRequest(code: code))

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                  (200...299).contains(statusCode) else { throw PremiumAccessError.requestFailed }
            let exchange = try NukeJSON.makeDecoder().decode(DiscordExchangeResponse.self, from: data)
            guard NukeCredentialStore.save(accessToken: exchange.accessToken) else { throw PremiumAccessError.keychainFailed }
            apply(exchange.entitlement, to: profile, in: modelContext)
        } catch {
            state = .free
            lastError = "We could not verify your Nuke membership. Please try again."
        }
    }

    func refresh(profile: UserProfile, in modelContext: ModelContext) async {
        guard let token = NukeCredentialStore.accessToken else {
            configure(from: profile)
            return
        }
        guard let baseURL = CommunityAPIConfiguration.baseURL else {
            configure(from: profile)
            return
        }

        var request = URLRequest(url: baseURL.appending(path: "v1/entitlement"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw PremiumAccessError.requestFailed }
            if http.statusCode == 401 {
                signOut(profile: profile, in: modelContext)
                return
            }
            guard http.statusCode == 200 else { throw PremiumAccessError.requestFailed }
            let entitlement = try NukeJSON.makeDecoder().decode(PremiumEntitlement.self, from: data)
            apply(entitlement, to: profile, in: modelContext)
        } catch {
            // Preserve the last known verified state during a temporary outage.
            state = profile.hasActiveVIPAccess ? .verified : .unavailable
            lastError = "Nuke Vault status could not be refreshed right now."
        }
    }

    func signOut(profile: UserProfile, in modelContext: ModelContext) {
        NukeCredentialStore.removeAccessToken()
        profile.premiumAccessRaw = PremiumAccessLevel.free.rawValue
        profile.discordUserID = nil
        profile.discordDisplayName = nil
        profile.premiumVerifiedAt = nil
        profile.premiumExpiresAt = nil
        try? modelContext.save()
        state = .free
        lastError = nil
    }

    /// Revokes the server-issued opaque token when possible, then always clears
    /// the device's Discord session and cached entitlement. The free tracker is
    /// not affected by disconnecting.
    func disconnect(profile: UserProfile, in modelContext: ModelContext) async {
        if let token = NukeCredentialStore.accessToken,
           let baseURL = CommunityAPIConfiguration.baseURL {
            var request = URLRequest(url: baseURL.appending(path: "v1/auth/revoke"))
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
        signOut(profile: profile, in: modelContext)
    }

    private func apply(_ entitlement: PremiumEntitlement, to profile: UserProfile, in modelContext: ModelContext) {
        if !entitlement.authenticated {
            NukeCredentialStore.removeAccessToken()
            profile.discordDisplayName = nil
        }
        profile.premiumAccessRaw = entitlement.authenticated ? entitlement.access.rawValue : PremiumAccessLevel.free.rawValue
        profile.discordUserID = entitlement.discordUserID
        profile.premiumVerifiedAt = entitlement.verifiedAt
        profile.premiumExpiresAt = entitlement.expiresAt
        try? modelContext.save()
        configure(from: profile)
        lastError = nil
    }
}

private enum PremiumAccessError: Error {
    case requestFailed
    case keychainFailed
}

private struct DiscordStartRequest: Encodable {
    let appRedirectURI: String
    let clientState: String
}

private struct DiscordStartResponse: Decodable {
    let authorizationURL: URL
    let expiresAt: Date?
}

private struct DiscordExchangeRequest: Encodable {
    let code: String
}

private struct DiscordExchangeResponse: Decodable {
    let accessToken: String
    let expiresAt: Date?
    let entitlement: PremiumEntitlement
}

private enum NukeCredentialStore {
    private static let service = "com.nukesportsbets.nukeunittracker"
    private static let account = "community-access-token"

    static var accessToken: String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(accessToken: String) -> Bool {
        removeAccessToken()
        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(accessToken.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    static func removeAccessToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
