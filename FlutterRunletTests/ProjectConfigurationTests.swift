import Foundation
import XCTest
@testable import FlutterRunlet

@MainActor
final class ProjectConfigurationTests: XCTestCase {
    func testPublicLaunchesKeepNamesArgumentsAndSeparateEnvironments() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let config = configuration(fixture)
        XCTAssertNil(config.launchIssue)
        XCTAssertNil(config.taskIssue)
        XCTAssertEqual(config.choices.map(\.name), ["dev", "physical", "test", "prod"].map { "sample-flutter-app(\($0))" })
        XCTAssertEqual(config.choices.compactMap { $0.launch?.pre?.label },
                       ["sample:select-dev", "sample:select-dev", "sample:select-test", "sample:select-prod"])
        let prod = try XCTUnwrap(config.choices.last?.launch)
        XCTAssertEqual(prod.toolArguments, ["--dart-define=APP_ENV=prod", "--dart-define=ENABLE_SAMPLE_FEATURE=false",
                                             "--dart-define=DEMO_BUILD_NUMBER=1001"])
        XCTAssertEqual(prod.applicationArguments, [])
        XCTAssertEqual(prod.environment["PATH"], "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin")
        XCTAssertEqual(prod.pre?.command.environment["PATH"], "/usr/bin:/bin")
        XCTAssertEqual(prod.pre?.command.arguments,
                       [prod.project.appending(path: "scripts/simulate-firebase-switch.sh").path, "prod", "--quiet"])
    }

    func testJSONCKeepsStringBytesAndReportsOriginalLineAndColumn() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        try writeLaunch(#"""
            {
              "configurations": [
                {"name":"甲 // /* \" \u002f","type":"dart","request":"launch",},
              ],
            }
            """#, fixture)
        XCTAssertEqual(configuration(fixture).choices.first?.name, "甲 // /* \" /")

        for (source, location) in [
            ("{\r\n  \"🍎\": ?,\r\n}", "第 2 行第 8 列"),
            ("{\r\n  \"configurations\": [1,,],\r\n}", "第 2 行"),
            ("{\r\n  /* 未闭合", "第 2 行第 3 列"),
        ] {
            try writeLaunch(source, fixture)
            let issue = configuration(fixture).launchIssue ?? ""
            XCTAssertTrue(issue.contains("launch.json") && issue.contains(location), issue)
        }
    }

    func testDefineConflictModesAndOverridesRemainVisibleButUnavailable() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        try writeLaunch(#"""
        {"configurations":[
          {"name":"可用","type":"dart","request":"launch","deviceId":"设备 1",
           "toolArgs":["--flavor=dev","--dart-define","TOOL=a=b"],
           "args":["--dart-define=LEGACY=x=y","--application",""]},
          {"name":"非 Debug","type":"dart","request":"launch","flutterMode":"release"},
          {"name":"错类型","type":"other","request":"launch"},
          {"name":"空入口","type":"dart","request":"launch","program":""},
          {"name":"冲突","type":"dart","request":"launch",
           "toolArgs":["--dart-define","APP=old"],"args":["--dart-define=APP=new"]},
          {"name":"模式覆盖","type":"dart","request":"launch","toolArgs":["--release"]},
          {"name":"入口覆盖","type":"dart","request":"launch","toolArgs":["-tlib/main.dart"]},
          {"name":"设备覆盖","type":"dart","request":"launch","toolArgs":["--device-id=other"]},
          {"name":"不完整","type":"dart","request":"launch","args":["--dart-define=X"]},
          {"name":"重名","type":"dart","request":"launch"},
          {"name":"重名","type":"dart","request":"launch"}
        ]}
        """#, fixture)
        let choices = configuration(fixture).choices
        let usable = try XCTUnwrap(choices.first?.launch)
        XCTAssertEqual(usable.toolArguments, ["--flavor=dev", "--dart-define", "TOOL=a=b", "--dart-define=LEGACY=x=y"])
        XCTAssertEqual(usable.applicationArguments, ["--application", ""])
        XCTAssertEqual(usable.deviceID, "设备 1")
        XCTAssertEqual(choices.compactMap(\.launch).map(\.name), ["可用"])
        XCTAssertEqual(choices.suffix(2).map(\.name), ["重名", "重名"])
        XCTAssertTrue(choices.suffix(2).allSatisfy { $0.issue?.contains("重名") == true })
    }

    func testRealTaskArgumentsDirectoryEnvironmentAndExitStatus() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let capture = fixture.project.appending(path: "scripts/capture arguments.sh")
        try """
            #!/bin/sh
            printf '%s\\0' "$#" "$PWD" "$RUNLET_VALUE" "$@"
            exit 7
            """.write(to: capture, atomically: true, encoding: .utf8)
        let variables = ["PATH": "/usr/bin:/bin", "SOURCE": "来自父进程"]
        let vector = ["", "空 格", "e\u{301}", "';\"&|$(printf bad)", "line\nnext"]
        let root = try ProjectLocation.directory(fixture.project)
        let lease = try store.lease(for: root)
        let options = ["cwd": "$" + "{workspaceFolder}/scripts", "env": ["RUNLET_VALUE": "$" + "{env:SOURCE}"]] as [String: Any]
        for type in ["shell", "process"] {
            let input = ["label": "capture", "type": type, "command": "/bin/sh",
                         "args": [capture.path] + vector, "options": options] as [String: Any]
            try writeTasks([input], fixture)
            let project = ProjectConfiguration(project: root, environment: variables, restricted: false)
            let task = try project.prepareTask("capture")
            let process = try SessionProcessRunner.bundled.start(task.command, lease: lease)
            let result = await process.wait()
            XCTAssertEqual(result.exit, .exited(7))
            let expected = ["5", root.appending(path: "scripts").path, "来自父进程"] + vector
            XCTAssertEqual(Array(result.stdout.utf8), Array((expected.joined(separator: "\0") + "\0").utf8))
            XCTAssertEqual(task.references, ["SOURCE": "来自父进程"])
        }
    }

    func testZeroAndNullArgumentsAndUnsupportedTasksHaveDistinctResults() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let root = try ProjectLocation.directory(fixture.project)
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let lease = try store.lease(for: root)
        let command: [String: Any] = ["label": "task", "type": "shell", "command": "printf '%s' ok"]
        for args in [nil, [] as [String]?] {
            var entry = command
            if let args { entry["args"] = args }
            try writeTasks([entry], fixture)
            let task = try configuration(fixture).prepareTask("task")
            let process = try SessionProcessRunner.bundled.start(task.command, lease: lease)
            let result = await process.wait()
            XCTAssertEqual(result.exit, .exited(0))
            XCTAssertEqual(result.stdout, "ok")
        }
        for extra in [
            ["args": NSNull()], ["dependsOn": "other"], ["isBackground": true],
            ["type": "extension"], ["command": "$" + "{command:select}"],
            ["options": ["shell": ["executable": "/bin/bash"]]]
        ] as [[String: Any]] {
            try writeTasks([command.merging(extra, uniquingKeysWith: { _, replacement in replacement })], fixture)
            XCTAssertThrowsError(try configuration(fixture).prepareTask("task"))
        }
        try writeTasks([command, command], fixture)
        XCTAssertThrowsError(try configuration(fixture).prepareTask("task"))
    }

    func testBrokenTasksOnlyDisableReferencedLaunches() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        try writeLaunch(#"""
        {"configurations":[
          {"name":"可用","type":"dart","request":"launch"},
          {"name":"引用任务","type":"dart","request":"launch","postDebugTask":"task"}
        ]}
        """#, fixture)
        try "{broken".write(to: fixture.config("tasks"), atomically: true, encoding: .utf8)
        let broken = configuration(fixture)
        XCTAssertNotNil(broken.taskIssue)
        XCTAssertEqual(broken.choices.compactMap(\.launch).map(\.name), ["可用"])
        try FileManager.default.removeItem(at: fixture.config("tasks"))
        let missing = configuration(fixture)
        XCTAssertTrue(missing.taskIssue?.contains("缺失") == true)
        XCTAssertEqual(missing.choices.compactMap(\.launch).map(\.name), ["可用"])
    }

    private func writeTasks(_ tasks: [[String: Any]], _ fixture: SessionFixture) throws {
        let data = try JSONSerialization.data(withJSONObject: ["tasks": tasks])
        try data.write(to: fixture.config("tasks"))
    }

    private func configuration(_ fixture: SessionFixture) -> ProjectConfiguration {
        ProjectConfiguration(project: (try? ProjectLocation.directory(fixture.project)) ?? fixture.project, environment: fixture.environment, restricted: false)
    }

    private func writeLaunch(_ source: String, _ fixture: SessionFixture) throws {
        try source.write(to: fixture.config("launch"), atomically: true, encoding: .utf8)
    }
}
