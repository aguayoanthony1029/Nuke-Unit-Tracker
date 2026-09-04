import Foundation
import UIKit

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

    func removeLocalFile(for attachment: SlipAttachment) {
        removeLocalFile(relativePath: attachment.localRelativePath)
    }

    func removeLocalFile(relativePath: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: relativePath))
    }
}

private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage? {
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1)
        let target = CGSize(width: size.width * ratio, height: size.height * ratio)
        return UIGraphicsImageRenderer(size: target).image { _ in draw(in: CGRect(origin: .zero, size: target)) }
    }
}
