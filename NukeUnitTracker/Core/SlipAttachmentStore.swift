import Foundation
import UIKit
import CloudKit

@MainActor
final class SlipAttachmentStore {
    static let shared = SlipAttachmentStore()
    private let directory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = appSupport.appending(path: "SlipAttachments", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func save(imageData: Data, for betID: UUID) throws -> SlipAttachment {
        guard let image = UIImage(data: imageData), let compressed = image.resized(maxDimension: 1600)?.jpegData(compressionQuality: 0.82) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        let name = "\(UUID().uuidString).jpg"
        try compressed.write(to: directory.appending(path: name), options: .atomic)
        return SlipAttachment(betID: betID, localRelativePath: name)
    }

    func image(for attachment: SlipAttachment) -> UIImage? {
        UIImage(contentsOfFile: directory.appending(path: attachment.localRelativePath).path)
    }

    func downloadIfNeeded(_ attachment: SlipAttachment) async -> UIImage? {
        if let local = image(for: attachment) { return local }
        guard let recordName = attachment.cloudRecordName else { return nil }
        do {
            let record = try await CKContainer.default().privateCloudDatabase.record(for: CKRecord.ID(recordName: recordName))
            guard let asset = record["image"] as? CKAsset, let source = asset.fileURL else { return nil }
            let destination = directory.appending(path: attachment.localRelativePath)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: source, to: destination)
            return UIImage(contentsOfFile: destination.path)
        } catch { return nil }
    }

    func uploadToPrivateCloud(_ attachment: SlipAttachment) async throws -> String {
        let url = directory.appending(path: attachment.localRelativePath)
        let recordID = CKRecord.ID(recordName: attachment.cloudRecordName ?? attachment.id.uuidString)
        // Keep binary assets separate from SwiftData's generated SlipAttachment records.
        let record = CKRecord(recordType: "SlipAsset", recordID: recordID)
        record["betID"] = attachment.betID.uuidString as CKRecordValue
        record["image"] = CKAsset(fileURL: url)
        _ = try await CKContainer.default().privateCloudDatabase.save(record)
        return recordID.recordName
    }

    func retryPendingUploads(_ attachments: [SlipAttachment]) async {
        for attachment in attachments where attachment.cloudRecordName == nil {
            if let recordName = try? await uploadToPrivateCloud(attachment) { attachment.cloudRecordName = recordName }
        }
    }

    func removeLocalFile(for attachment: SlipAttachment) {
        try? FileManager.default.removeItem(at: directory.appending(path: attachment.localRelativePath))
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1)
        let target = CGSize(width: size.width * ratio, height: size.height * ratio)
        return UIGraphicsImageRenderer(size: target).image { _ in draw(in: CGRect(origin: .zero, size: target)) }
    }
}
