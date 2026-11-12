import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class SessionLifecycleTests: XCTestCase {
    func testPublicProdRunsPreWaitsForGroupExitAndRestoresOriginalPost() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let original = try fixture.configurationBytes()
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let debug = SessionCommand(executable: "/bin/sh", arguments: ["-c", """
            test -f "$1" || exit 91
            trap 'exit 0' TERM
            : > .runlet-fixture/debug-started
            while :; do /bin/sleep 0.05; done
            """, "fixture", try store.recordURL(for: fixture.project).path], directory: fixture.project.path, environment: fixture.environment)
        let session = SessionController(store: store, runner: .bundled, debugCommand: { _ in debug })
        try fixture.select("prod", in: session)
        XCTAssertTrue(session.canRun, session.displayMessage ?? "无有效配置")
        session.run()
        session.run()
        do {
            try await fixture.waitFor("debug-started")
        } catch {
            XCTFail("\(session.status) / \(session.displayMessage ?? "") / \(session.logs)")
            session.stop()
            await session.waitUntilIdle()
            return
        }
        XCTAssertEqual(try fixture.marker(), "prod\n")
        XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
        session.stop()
        await session.waitUntilIdle()
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(try fixture.configurationBytes(), original)
    }

    func testFixtureAssemblyRequiresExactFlagAndRejectsOutsideProjectAlias() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let root = fixture.base.appending(path: "projects")
        let alias = root.appending(path: "outside alias")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: fixture.project)
        XCTAssertFalse(SessionController.fixtureEnabled(arguments: ["--phase-02-fixture=1"]))
        XCTAssertTrue(SessionController.fixtureEnabled(arguments: ["--phase-02-fixture"]))
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, allowedRoot: root, debugCommand: { _ in
            XCTFail("越界项目不得准备进程")
            return nil
        })
        XCTAssertFalse(session.open(fixture.project))
        XCTAssertFalse(session.open(alias))
        session.run()
        XCTAssertNil(session.project)
        XCTAssertEqual(try fixture.marker(), "test\n")
        XCTAssertNil(try store.read(project: fixture.project))
    }
}

@MainActor
struct SessionFixture {
    let base: URL
    let project: URL
    let storage: URL
    let environment = ["PATH": "/usr/bin:/bin"]

    init() throws {
        base = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appending(path: "Runlet \(UUID())")
        project = base.appending(path: "Public Flutter Sample")
        storage = base.appending(path: "storage")
        let files = FileManager.default
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "docs/examples/sample-flutter-app")
        for name in [".vscode", "scripts", "lib", ".runlet-fixture"] {
            try files.createDirectory(at: project.appending(path: name), withIntermediateDirectories: true)
        }
        for name in ["launch", "tasks"] {
            try files.copyItem(at: source.appending(path: "\(name).jsonc"), to: config(name))
        }
        try files.copyItem(at: source.appending(path: "scripts/simulate-firebase-switch.sh"),
                           to: project.appending(path: "scripts/simulate-firebase-switch.sh"))
        try "name: sample\ndependencies:\n  flutter:\n    sdk: flutter\n".write(to: project.appending(path: "pubspec.yaml"), atomically: true, encoding: .utf8)
        try "void main() {}\n".write(to: project.appending(path: "lib/main.dart"), atomically: true, encoding: .utf8)
        try "test\n".write(to: state("firebase-environment"), atomically: true, encoding: .utf8)
    }

    func config(_ name: String) -> URL { project.appending(path: ".vscode/\(name).json") }
    func state(_ name: String) -> URL { project.appending(path: ".runlet-fixture/\(name)") }
    func configurationBytes() throws -> [Data] { try ["launch", "tasks"].map { try Data(contentsOf: config($0)) } }
    func marker() throws -> String { try String(contentsOf: state("firebase-environment"), encoding: .utf8) }
    func remove() { try? FileManager.default.removeItem(at: base) }

    func select(_ mode: String, in session: SessionController) throws {
        XCTAssertTrue(session.open(project))
        session.select("sample-flutter-app(\(mode))")
    }

    func waitFor(_ name: String) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !FileManager.default.fileExists(atPath: state(name).path) {
            guard ContinuousClock.now < deadline else {
                throw NSError(domain: "Fixture timeout: \(name)", code: 1)
            }
            try await Task.sleep(for: .milliseconds(20))
        }
    }
}
