import Foundation
import CloudKit
import UIKit

enum SlipAttachmentStoreError: LocalizedError, Equatable {
    case storageLimitReached

    var errorDescription: String? {
        switch self {
        case .storageLimitReached:
            "Slip photo storage is full. Delete an older bet or its photos before adding more."
        }
    }
}

@MainActor
final class SlipAttachmentStore {
    static let shared = SlipAttachmentStore()
    static let defaultMaximumStorageBytes: Int64 = 400 * 1_024 * 1_024

    private let directory: URL
    private let maximumStorageBytes: Int64

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = appSupport.appending(path: "SlipAttachments", directoryHint: .isDirectory)
        maximumStorageBytes = Self.defaultMaximumStorageBytes
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    init(directory: URL, maximumStorageBytes: Int64) throws {
        self.directory = directory
        self.maximumStorageBytes = maximumStorageBytes
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    var storageUsageBytes: Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        guard let files = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        return files.compactMap { $0 as? URL }.reduce(into: Int64(0)) { total, file in
            guard let values = try? file.resourceValues(forKeys: keys), values.isRegularFile == true else { return }
            total += Int64(values.fileSize ?? 0)
        }
    }

    var storageUsageDescription: String {
        "\(Self.formattedSize(storageUsageBytes)) of \(Self.formattedSize(maximumStorageBytes))"
    }

    var storageLimitDescription: String {
        Self.formattedSize(maximumStorageBytes)
    }

    func save(imageData: Data, for betID: UUID) throws -> SlipAttachment {
        guard let image = UIImage(data: imageData), let compressed = image.resized(maxDimension: 1_280)?.jpegData(compressionQuality: 0.72) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        guard storageUsageBytes + Int64(compressed.count) <= maximumStorageBytes else {
            throw SlipAttachmentStoreError.storageLimitReached
        }

        let name = "\(UUID().uuidString).jpg"
        let destination = directory.appending(path: name)
        try compressed.write(to: destination, options: .atomic)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: destination.path
        )
        return SlipAttachment(betID: betID, localRelativePath: name)
    }

    func image(for attachment: SlipAttachment) -> UIImage? {
        UIImage(contentsOfFile: directory.appending(path: attachment.localRelativePath).path)
    }

    /// New photos remain device-local. This only restores a photo that an
    /// earlier app version had already saved to the user's private iCloud.
    func imageForDisplay(for attachment: SlipAttachment) async -> UIImage? {
        if let localImage = image(for: attachment) { return localImage }
        guard let recordName = attachment.cloudRecordName else { return nil }

        do {
            let record = try await CKContainer.default().privateCloudDatabase.record(for: CKRecord.ID(recordName: recordName))
            guard let asset = record["image"] as? CKAsset, let source = asset.fileURL else { return nil }
            let sourceSize = Int64((try? source.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            guard storageUsageBytes + sourceSize <= maximumStorageBytes else { return nil }

            let destination = directory.appending(path: attachment.localRelativePath)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: source, to: destination)
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: destination.path
            )
            return UIImage(contentsOfFile: destination.path)
        } catch {
            return nil
        }
    }

    func removeLocalFile(for attachment: SlipAttachment) {
        removeLocalFile(relativePath: attachment.localRelativePath)
    }

    func removeLocalFile(relativePath: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: relativePath))
    }

    private static func formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1)
        let target = CGSize(width: size.width * ratio, height: size.height * ratio)
        return UIGraphicsImageRenderer(size: target).image { _ in draw(in: CGRect(origin: .zero, size: target)) }
    }
}
