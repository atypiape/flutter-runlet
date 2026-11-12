import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class ProjectRecoveryTests: XCTestCase {
    func testFirstPostUsesSnapshotEvenAfterTasksChange() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: """
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """)
        try fixture.select("prod", in: session)
        session.run()
        try await fixture.waitFor("debug-started")
        let tasks = try fixture.taskSource()
        try fixture.writeTasks(tasks.replacingOccurrences(of: #", "test", "--quiet""#, with: #", "dev", "--quiet""#))
        session.stop()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
    }

    func testAutomaticPostBlocksWhenOriginalProjectDirectoryIsReplaced() async throws {
        let fixture = try SessionFixture()
        let replacement = try SessionFixture()
        defer { fixture.remove(); replacement.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store, script: """
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """)
        try fixture.select("prod", in: session)
        session.run()
        try await fixture.waitFor("debug-started")
        let original = fixture.base.appending(path: "Moved project", directoryHint: .isDirectory)
        try FileManager.default.moveItem(at: fixture.project, to: original)
        try FileManager.default.moveItem(at: replacement.project, to: fixture.project)
        try "dev\n".write(to: fixture.state("firebase-environment"), atomically: true, encoding: .utf8)
        session.stop()
        await session.waitUntilIdle()
        XCTAssertTrue(session.message?.contains("身份") == true)
        XCTAssertNotNil(session.recovery)
        XCTAssertEqual(try store.allRecords().count, 1)
        XCTAssertEqual(try fixture.marker(), "dev\n")
        XCTAssertEqual(try String(contentsOf: original.appending(path: ".runlet-fixture/firebase-environment"), encoding: .utf8), "prod\n")
    }

    func testSecondInstanceRefreshesRecordClearedByFirstInstance() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let producer = fixture.session(store: store)
        try Data().write(to: fixture.state("fail-before-test"))
        try fixture.select("prod", in: producer)
        producer.run()
        await producer.waitUntilIdle()
        let other = fixture.session(store: store)
        XCTAssertTrue(other.openRecoveryProject())
        try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
        producer.retryRecovery()
        await producer.waitUntilIdle()
        XCTAssertNil(producer.recovery)
        XCTAssertNotNil(other.recovery)
        other.retryRecovery()
        await other.waitUntilIdle()
        XCTAssertNil(other.recovery)
        XCTAssertTrue(other.canTerminate)
        XCTAssertEqual(try fixture.marker(), "test\n")
    }

    func testFailedPostRestartAndExplicitRetryUseOriginalLabelAndDefinition() async throws {
        let fixture = try SessionFixture()
        let other = try SessionFixture()
        defer { fixture.remove(); other.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let name = "FlutterRunletTests.\(UUID())"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { preferences.removePersistentDomain(forName: name) }
        let recent = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertTrue(recent.open(other.project))

        try Data().write(to: fixture.state("fail-before-test"))
        let session = fixture.session(store: store)
        try fixture.select("prod", in: session)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertEqual(session.recovery?.taskLabel, "sample:select-test")

        let restarted = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertEqual(restarted.project?.path, recent.project?.path)
        XCTAssertEqual(restarted.recovery?.taskLabel, "sample:select-test")
        restarted.retryRecovery()
        await restarted.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertTrue(restarted.openRecoveryProject())
        XCTAssertEqual(restarted.project?.path, session.project?.path)

        let tasks = try fixture.taskSource()
        for changed in [
            tasks.replacingOccurrences(of: "sample:select-test", with: "wrong-label"),
            tasks.replacingOccurrences(of: #", "test", "--quiet""#, with: #", "dev", "--quiet""#),
            tasks.replacingOccurrences(of: #"options": { "cwd":"#, with: #"options": { "env":{"EXTRA":"changed"}, "cwd":"#)
        ] {
            try fixture.writeTasks(changed)
            restarted.retryRecovery()
            await restarted.waitUntilIdle()
            XCTAssertNotNil(restarted.recovery)
            XCTAssertEqual(try fixture.marker(), "prod\n")
        }
        try fixture.writeTasks("// comments are not part of the definition\n" + tasks)
        try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
        restarted.retryRecovery()
        await restarted.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(restarted.recovery)
        XCTAssertNil(try store.read(project: fixture.project))
    }

    func testChangedAndMissingExplicitEnvironmentValuesAreNeverShownOrStored() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let tasks = try fixture.taskSource().replacingOccurrences(
            of: #"options": { "cwd":"#,
            with: #"options": { "env":{"ONE":"${env:FIRST}","TWO":"${env:SECOND}"}, "cwd":"#
        )
        try fixture.writeTasks(tasks)
        let original = ["PATH": "/usr/bin:/bin", "FIRST": "old-secret-one", "SECOND": "old-secret-two"]
        let canonical = try ProjectLocation.directory(fixture.project)
        let config = ProjectConfiguration(project: canonical, environment: original, restricted: false)
        let task = try config.prepareTask("sample:select-test")
        do {
            let lease = try store.lease(for: canonical)
            _ = try store.write(task: task, lease: lease)
        }
        let risk = try store.recordURL(for: canonical)
        let envelope = try JSONSerialization.jsonObject(with: Data(contentsOf: risk)) as? [String: String]
        let encoded = try XCTUnwrap(envelope?["payload"])
        let payload = try XCTUnwrap(Data(base64Encoded: encoded))
        XCTAssertFalse(String(decoding: payload, as: UTF8.self).contains("old-secret"))
        XCTAssertFalse(String(decoding: payload, as: UTF8.self).contains(task.command.executable))

        try "prod\n".write(to: fixture.state("firebase-environment"), atomically: true, encoding: .utf8)
        let changed = SessionController(store: store, runner: .bundled,
                                        environment: ["PATH": "/usr/bin:/bin", "FIRST": "new-secret"])
        XCTAssertNil(changed.project)
        XCTAssertTrue(changed.openRecoveryProject())
        changed.retryRecovery()
        await changed.waitUntilIdle()
        let reason = try XCTUnwrap(changed.message)
        XCTAssertTrue(reason.contains("FIRST") && reason.contains("SECOND"))
        XCTAssertFalse(reason.contains("secret"))
        XCTAssertEqual(try fixture.marker(), "prod\n")

        let recovered = SessionController(store: store, runner: .bundled, environment: original)
        XCTAssertTrue(recovered.openRecoveryProject())
        recovered.retryRecovery()
        await recovered.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(recovered.recovery)
    }

    func testInvalidRecordAndFailedRemovalKeepRecoveryBlocked() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage) { point in
            if point == .removal { throw SessionIssue("注入清除同步失败") }
        }
        let session = fixture.session(store: store)
        try fixture.select("prod", in: session)
        session.run()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNotNil(session.recovery)
        XCTAssertNotNil(try store.read(project: fixture.project))

        let record = try store.recordURL(for: fixture.project)
        try Data("tampered".utf8).write(to: record)
        let restarted = fixture.session(store: store)
        XCTAssertNotNil(restarted.recoveryStoreIssue)
        XCTAssertTrue(restarted.open(fixture.project))
        restarted.select("sample-flutter-app(prod)")
        XCTAssertFalse(restarted.canRun)
        restarted.run()
        await restarted.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
    }
}

extension SessionFixture {
    func taskSource() throws -> String { try String(contentsOf: config("tasks"), encoding: .utf8) }
    func writeTasks(_ source: String) throws { try source.write(to: config("tasks"), atomically: true, encoding: .utf8) }
}
