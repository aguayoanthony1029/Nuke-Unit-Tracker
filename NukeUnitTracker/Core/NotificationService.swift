import Foundation
import UserNotifications
import UIKit

@MainActor
enum NotificationService {
    static func requestFreePickAuthorization() async -> Bool {
        do { return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) }
        catch { return false }
    }

    static func registerForRemoteNotifications() {
        UIApplication.shared.registerForRemoteNotifications()
    }
}

enum DeviceRegistration {
    private static let tokenKey = "apnsDeviceToken"

    static func store(token: String) { UserDefaults.standard.set(token, forKey: tokenKey) }

    static func registerIfAvailable(quietStart: Int, quietEnd: Int) async {
        guard let token = UserDefaults.standard.string(forKey: tokenKey), let baseURL = CommunityAPIConfiguration.baseURL else { return }
        var request = URLRequest(url: baseURL.appending(path: "v1/device-tokens"))
        request.httpMethod = "POST"; request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(Payload(token: token, timezone: TimeZone.current.identifier, quietStart: quietStart, quietEnd: quietEnd))
        _ = try? await URLSession.shared.data(for: request)
    }

    private struct Payload: Encodable { let token: String; let timezone: String; let quietStart: Int; let quietEnd: Int }
}
