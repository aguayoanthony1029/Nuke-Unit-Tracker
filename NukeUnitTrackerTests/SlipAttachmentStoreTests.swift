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

    func testStorageLimitPreventsAdditionalSlipPhotos() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "SlipAttachmentStoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = try SlipAttachmentStore(directory: directory, maximumStorageBytes: 1)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image { context in
            UIColor.systemCyan.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        let imageData = try XCTUnwrap(image.jpegData(compressionQuality: 1))

        XCTAssertThrowsError(try store.save(imageData: imageData, for: UUID())) { error in
            XCTAssertEqual(error as? SlipAttachmentStoreError, .storageLimitReached)
        }
        XCTAssertEqual(store.storageUsageBytes, 0)
    }
}
