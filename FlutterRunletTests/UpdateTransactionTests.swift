import Darwin
import Foundation
import XCTest
@testable import FlutterRunlet

final class UpdateTransactionTests: XCTestCase {
    func testAtomicExchangeAndRollbackKeepBothDirectoryIdentities() throws {
        let directory = try temporaryUpdateDirectory()
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

    func testPreparationCleanupFindsPendingRenamedBeforeDirectorySyncFailed() throws {
        try withJournal { recovery, stage, record in
            try stage.write(record, to: UpdateJournal.intent)
            XCTAssertThrowsError(try recovery.write(record, to: UpdateJournal.pending) {
                throw UpdateDirectory.Issue.durability
            })
            XCTAssertEqual(try recovery.read(UpdateJournal.pending), record)
            try UpdateJournal.discardPreparation(id: record.id, recovery: recovery, staging: stage)
            XCTAssertNil(try recovery.read(UpdateJournal.pending, as: UpdateJournal.self))
            XCTAssertFalse(FileManager.default.fileExists(atPath: stage.url.path))
        }
    }

    func testPreparationCleanupKeepsStageWhilePendingCannotBeSafelyCleared() throws {
        try withJournal { recovery, stage, record in
            try recovery.write(record, to: UpdateJournal.pending)
            XCTAssertThrowsError(try UpdateJournal.discardPreparation(id: UUID(), recovery: recovery, staging: stage))
            XCTAssertEqual(try recovery.read(UpdateJournal.pending), record)
            try recovery.write("unreadable journal", to: UpdateJournal.pending)
            XCTAssertThrowsError(try UpdateJournal.discardPreparation(id: record.id, recovery: recovery, staging: stage))
            XCTAssertNoThrow(try stage.verify())
        }
    }

    func testCancelClosesHandshakeBeforeReapingDirectChild() throws {
        try withJournal { _, stage, _ in
            var sockets = [Int32](repeating: -1, count: 2)
            XCTAssertEqual(socketpair(AF_UNIX, SOCK_STREAM, 0, &sockets), 0)
            defer { if sockets[1] >= 0 { close(sockets[1]) } }
            let channel = try UpdateChannel(taking: sockets[0])
            let marker = stage.url.appending(path: "handshake-closed")
            let pid = try SessionSpawn.spawn("/bin/sh", arguments: ["-c", """
                if IFS= read -r message; then exit 64; fi
                printf closed > "$1"
                """, "helper", marker.path], environment: [:], flags: Int16(POSIX_SPAWN_CLOEXEC_DEFAULT)) { actions in
                    posix_spawn_file_actions_adddup2(&actions, sockets[1], STDIN_FILENO)
                }.get()
            close(sockets[1])
            sockets[1] = -1
            XCTAssertTrue(UpdateHelperChild(pid: pid).cancel(on: channel))
            XCTAssertEqual(try String(contentsOf: marker, encoding: .utf8), "closed")
            var status: Int32 = 0
            let reaped = waitpid(pid, &status, WNOHANG)
            let waitError = errno
            XCTAssertEqual(reaped, -1)
            XCTAssertEqual(waitError, ECHILD)
        }
    }

    func testTerminalHandoffRequiresReleasedInitializationLockAndMatchingAttempt() throws {
        for phase: UpdateJournal.Phase in [.committed, .restored] {
            try withJournal { recovery, stage, record in
                var terminal = record
                terminal.phase = phase
                terminal.helperProcess = record.oldProcess
                terminal.attemptedProcess = record.oldProcess
                try recovery.write(terminal, to: UpdateJournal.pending)
                try stage.write(terminal, to: UpdateJournal.intent)

                let initialization = try UpdateActivityLease.lock("installation.lock", in: recovery.descriptor, LOCK_EX)
                XCTAssertThrowsError(try terminal.acknowledgeStartup(process: record.oldProcess, phase: phase,
                                                                     recovery: recovery, staging: stage))
                close(initialization)
                let wrongPhase: UpdateJournal.Phase = phase == .committed ? .restored : .committed
                XCTAssertThrowsError(try terminal.acknowledgeStartup(process: record.oldProcess, phase: wrongPhase,
                                                                     recovery: recovery, staging: stage))
                XCTAssertEqual(try recovery.read(UpdateJournal.pending), terminal)
                XCTAssertEqual(try stage.read(UpdateJournal.intent), terminal)

                // Another process can resume using only the records that survived.
                let resumed: UpdateJournal = try XCTUnwrap(recovery.read(UpdateJournal.pending))
                try resumed.acknowledgeStartup(process: record.oldProcess, phase: phase, recovery: recovery, staging: stage)
                XCTAssertNil(try recovery.read(UpdateJournal.pending, as: UpdateJournal.self))
                let acknowledged: UpdateJournal = try XCTUnwrap(stage.read(UpdateJournal.intent))
                XCTAssertEqual(acknowledged.phase, phase)
                XCTAssertEqual(acknowledged.acknowledgedProcess, terminal.attemptedProcess)
            }
        }
    }

    private func withJournal(_ work: (UpdateDirectory, UpdateDirectory, UpdateJournal) throws -> Void) throws {
        let temporary = try temporaryUpdateDirectory()
        let parent = try temporary.createPrivateDirectory(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: parent.url) }
        let stage = try parent.createPrivateDirectory(".update-fixture")
        let recovery = try parent.createPrivateDirectory("Recovery")
        _ = try ProjectRecoveryStore(directory: recovery.url)
        let original = try parent.createPrivateDirectory(UpdateJournal.appName)
        let candidate = try stage.createPrivateDirectory(UpdateJournal.appName)
        func signed(_ version: String) -> PreparedUpdate.SignedIdentity {
            .init(app: .init(productID: "test.FlutterRunlet", version: version, build: version),
                  appCodeHashes: [:], workerCodeHashes: [:], helperCodeHashes: [:])
        }
        let record = UpdateJournal(id: UUID(), target: original.url, stage: stage.url, parentIdentity: parent.identity,
                                   stageIdentity: stage.identity, recoveryIdentity: recovery.identity,
                                   originalObject: original.identity, candidateObject: candidate.identity,
                                   oldProcess: try XCTUnwrap(UpdateProcessIdentity(getpid())), original: signed("1.0"),
                                   candidate: signed("1.1"), releaseTag: "v1.1", language: "en")
        try work(recovery, stage, record)
    }

    private func temporaryUpdateDirectory() throws -> UpdateDirectory {
        let path = try XCTUnwrap(realpath(FileManager.default.temporaryDirectory.path, nil))
        defer { free(path) }
        return try UpdateDirectory(URL(filePath: String(cString: path), directoryHint: .isDirectory))
    }
}
