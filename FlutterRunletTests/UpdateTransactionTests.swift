import Darwin
import Foundation
import XCTest
@testable import FlutterRunlet

final class UpdateTransactionTests: XCTestCase {
    func testAtomicExchangeAndRollbackKeepBothDirectoryIdentities() throws {
        let path = try XCTUnwrap(realpath(FileManager.default.temporaryDirectory.path, nil))
        defer { free(path) }
        let directory = try UpdateDirectory(URL(filePath: String(cString: path), directoryHint: .isDirectory))
        let parent = try directory.createPrivateDirectory(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: parent.url) }
        try parent.requireLocalAPFS()
        let stage = try parent.createPrivateDirectory("stage")
        let original = try parent.createPrivateDirectory("app")
        let candidate = try stage.createPrivateDirectory("app")
        let target = parent.url.appending(path: "app")
        let retained = stage.url.appending(path: "app")
        try "A".write(to: target.appending(path: "identity"), atomically: false, encoding: .utf8)
        try "B".write(to: retained.appending(path: "identity"), atomically: false, encoding: .utf8)
        try parent.exchange("app", expected: original.identity, with: stage, name: "app", expected: candidate.identity)
        XCTAssertEqual(try String(contentsOf: target.appending(path: "identity"), encoding: .utf8), "B")
        XCTAssertEqual(try String(contentsOf: retained.appending(path: "identity"), encoding: .utf8), "A")
        XCTAssertThrowsError(try parent.exchange("app", expected: original.identity, with: stage, name: "app", expected: candidate.identity))
        try parent.exchange("app", expected: candidate.identity, with: stage, name: "app", expected: original.identity)
        XCTAssertEqual(try parent.directoryIdentity("app"), original.identity)
        XCTAssertEqual(try stage.directoryIdentity("app"), candidate.identity)
    }

    func testInstallReservationBlocksProjectActivityInAnotherStore() throws {
        let root = FileManager.default.temporaryDirectory.resolvingSymlinksInPath()
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: root) }
        let recovery = root.appending(path: "Recovery", directoryHint: .isDirectory)
        let project = root.appending(path: "Project", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: false)
        let store = try ProjectRecoveryStore(directory: recovery)
        let peer = try ProjectRecoveryStore(directory: recovery)
        let lock = open(store.directory.appending(path: "update-activity.lock").path,
                        O_RDWR | O_CREAT | O_CLOEXEC | O_NOFOLLOW, 0o600)
        XCTAssertGreaterThanOrEqual(lock, 0)
        guard lock >= 0 else { return }
        defer { close(lock) }
        XCTAssertEqual(flock(lock, LOCK_EX | LOCK_NB), 0)
        XCTAssertThrowsError(try peer.lease(for: project), "An install reservation must block project activity")
        XCTAssertEqual(flock(lock, LOCK_UN), 0)
        XCTAssertNoThrow(try peer.lease(for: project))
    }
}
