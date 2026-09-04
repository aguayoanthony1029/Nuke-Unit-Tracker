import UIKit
import XCTest
@testable import NukeUnitTracker

@MainActor
final class SlipAttachmentStoreTests: XCTestCase {
    func testSavedSlipUsesLocalFileProtection() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        let imageData = try XCTUnwrap(image.jpegData(compressionQuality: 1))

        let attachment = try SlipAttachmentStore.shared.save(imageData: imageData, for: UUID())
        defer { SlipAttachmentStore.shared.removeLocalFile(for: attachment) }

        let path = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "SlipAttachments")
            .appending(path: attachment.localRelativePath)

        XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
        XCTAssertNotNil(SlipAttachmentStore.shared.image(for: attachment))
        let attributes = try FileManager.default.attributesOfItem(atPath: path.path)
        if let protection = attributes[.protectionKey] as? FileProtectionType {
            XCTAssertEqual(protection, .complete)
        }
    }
}
