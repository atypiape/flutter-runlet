import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class ProjectSelectionTests: XCTestCase {
    func testBrokenReloadRetainsStaleSelectionAndDeletingOrDuplicatingNameClearsIt() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let session = fixture.session(store: try ProjectRecoveryStore(directory: fixture.storage))
        try fixture.select("prod", in: session)
        let oldNames = session.choices.map(\.name)
        try fixture.writeLaunch("{ broken")
        session.reload()
        XCTAssertTrue(session.configurationIsStale)
        XCTAssertEqual(session.selection?.name, "sample-flutter-app(prod)")
        XCTAssertEqual(session.choices.map(\.name), oldNames)
        XCTAssertFalse(session.canRun)
        session.select("sample-flutter-app(test)")
        XCTAssertEqual(session.selection?.name, "sample-flutter-app(prod)")

        try fixture.writeLaunch(names: ["other"])
        session.reload()
        XCTAssertFalse(session.configurationIsStale)
        XCTAssertNil(session.selection)
        XCTAssertTrue(session.message?.contains("不存在") == true)
        session.select("other")
        try fixture.writeLaunch(names: ["other", "other"])
        session.reload()
        XCTAssertNil(session.selection)
        XCTAssertEqual(session.choices.map(\.name), ["other", "other"])
        XCTAssertTrue(session.choices.allSatisfy { $0.launch == nil })
    }

    func testOpeningValidFlutterProjectWithMissingLaunchAndInitialChoiceRules() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let session = fixture.session(store: try ProjectRecoveryStore(directory: fixture.storage))
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertNil(session.selection)
        try FileManager.default.removeItem(at: fixture.config("launch"))
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertNotNil(session.project)
        XCTAssertTrue(session.displayMessage?.contains("launch.json") == true)
        XCTAssertFalse(session.canRun)
        try fixture.writeLaunch(names: ["唯一配置"])
        session.reload()
        XCTAssertEqual(session.selection?.name, "唯一配置")
        try fixture.writeLaunch(names: [])
        XCTAssertTrue(session.open(fixture.project))
        XCTAssertNil(session.selection)
    }

    func testRunRequiresSecondClickAfterEffectiveChangeButIgnoresCommentAndUnrelatedTask() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = fixture.session(store: store)
        try fixture.select("prod", in: session)
        let launch = try String(contentsOf: fixture.config("launch"), encoding: .utf8)
        let changed = launch.replacingOccurrences(of: "APP_ENV=prod", with: "APP_ENV=changed")
        try fixture.writeLaunch(changed)
        session.run()
        await session.waitUntilIdle()
        XCTAssertTrue(session.message?.contains("再次") == true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        XCTAssertNil(try store.read(project: fixture.project))

        let tasks = try String(contentsOf: fixture.config("tasks"), encoding: .utf8)
        try fixture.writeLaunch("// comment\n" + changed)
        try tasks.replacingOccurrences(of: "select-dev", with: "unrelated-task").write(
            to: fixture.config("tasks"), atomically: true, encoding: .utf8
        )
        session.run()
        await session.waitUntilIdle()
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.state("debug-started").path))
        XCTAssertEqual(try fixture.marker(), "test\n")
    }

    func testRecentProjectPreferenceReadsDiskAndNeverRunsTasks() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let name = "FlutterRunletTests.\(UUID())"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { preferences.removePersistentDomain(forName: name) }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertTrue(session.open(fixture.project))
        try fixture.writeLaunch(names: ["重新读取"])
        let restarted = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertEqual(restarted.project?.path, session.project?.path)
        XCTAssertEqual(restarted.selection?.name, "重新读取")
        restarted.rememberRecentProject = false
        XCTAssertNotNil(restarted.project)
        let disabled = SessionController(store: store, runner: .bundled, preferences: preferences)
        XCTAssertNil(disabled.project)
        XCTAssertNil(try store.read(project: fixture.project))
        XCTAssertEqual(try fixture.marker(), "test\n")
    }
}

extension SessionFixture {
    func writeLaunch(_ source: String) throws {
        try source.write(to: config("launch"), atomically: true, encoding: .utf8)
    }

    func writeLaunch(names: [String]) throws {
        let items = names.map { ["name": $0, "type": "dart", "request": "launch"] }
        try JSONSerialization.data(withJSONObject: ["configurations": items]).write(to: config("launch"))
    }
}
