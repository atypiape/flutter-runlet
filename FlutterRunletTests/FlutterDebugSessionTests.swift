import AppKit
import Foundation
import Network
import Observation
import os
import XCTest
@testable import FlutterRunlet

private struct ToolEventServer {
    let listener: NWListener
    let port: UInt16

    static func start(file: URL) async throws -> Self {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        parameters.defaultProtocolStack.applicationProtocols.insert(NWProtocolWebSocket.Options(), at: 0)
        let listener = try NWListener(using: parameters)
        let queue = DispatchQueue(label: "FlutterDebugSessionTests.toolEvents")
        let attempts = OSAllocatedUnfairLock(initialState: 0)
        listener.newConnectionHandler = { connection in
            connection.start(queue: queue)
            receive(on: connection, file: file, attempts: attempts)
        }
        let (states, updates) = AsyncThrowingStream<NWEndpoint.Port, Error>.makeStream()
        listener.stateUpdateHandler = { [weak listener] state in
            switch state {
            case .ready:
                if let port = listener?.port { updates.yield(port); updates.finish() }
                else { updates.finish(throwing: URLError(.cannotConnectToHost)) }
            case .failed(let error): updates.finish(throwing: error)
            default: break
            }
        }
        listener.start(queue: queue)
        var iterator = states.makeAsyncIterator()
        guard let port = try await iterator.next() else { throw URLError(.cannotConnectToHost) }
        return Self(listener: listener, port: port.rawValue)
    }

    private static func receive(on connection: NWConnection, file: URL, attempts: OSAllocatedUnfairLock<Int>) {
        connection.receiveMessage { data, _, _, error in
            guard error == nil, let data,
                  let request = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = request["id"] as? String else { connection.cancel(); return }
            reply(to: request["method"] as? String, id: id, on: connection, file: file, attempts: attempts)
            receive(on: connection, file: file, attempts: attempts)
        }
    }

    private static func reply(to method: String?, id: String, on connection: NWConnection, file: URL,
                              attempts: OSAllocatedUnfairLock<Int>) {
        switch method {
        case "getVersion":
            send(["jsonrpc": "2.0", "id": id, "result": ["type": "Version", "major": 4, "minor": 20]], on: connection)
        case "streamListen":
            let first = attempts.withLock { value in
                value += 1
                return value == 1
            }
            if first {
                send(["jsonrpc": "2.0", "id": id, "error": ["code": -32603, "message": "Temporary failure"]], on: connection)
            } else {
                send(["jsonrpc": "2.0", "id": id, "result": ["type": "Success"]], on: connection)
                let event: [String: Any] = [
                    "kind": "Extension", "extensionKind": "navigate",
                    "extensionData": ["source": "devtools.inspector", "fileUri": file.absoluteString,
                                      "line": 12, "column": 3]
                ]
                send(["jsonrpc": "2.0", "method": "streamNotify",
                      "params": ["streamId": "ToolEvent", "event": event]], on: connection)
            }
        default:
            connection.cancel()
        }
    }

    private static func send(_ message: [String: Any], on connection: NWConnection) {
        guard let data = try? JSONSerialization.data(withJSONObject: message) else { connection.cancel(); return }
        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(identifier: "reply", metadata: [metadata])
        connection.send(content: data, contentContext: context, isComplete: true, completion: .idempotent)
    }
}

@MainActor
final class FlutterDebugSessionTests: XCTestCase {
    private let chinese = Locale(identifier: "zh-Hans")

    private let device = FlutterDevice(id: "ios-fixture", name: "iPhone 测试模拟器",
                                       platform: "ios", isSimulator: true)

    func testInspectorNavigationTargetsAnExistingDartFileInTheActiveProject() throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let file = fixture.project.appending(path: "页面 #1.dart").resolvingSymlinksInPath()
        try Data().write(to: file)
        try FileManager.default.createDirectory(at: fixture.storage, withIntermediateDirectories: true)
        let outside = fixture.storage.appending(path: "outside.dart")
        try Data().write(to: outside)
        let link = fixture.project.appending(path: "linked.dart")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)

        func event(_ uri: String, source: String = "devtools.inspector", line: Any = 12) -> [String: Any] {
            [
                "jsonrpc": "2.0", "method": "streamNotify",
                "params": [
                    "streamId": "ToolEvent",
                    "event": [
                        "kind": "Extension", "extensionKind": "navigate",
                        "extensionData": ["source": source, "fileUri": uri, "line": line, "column": 3]
                    ]
                ]
            ]
        }

        let location = try XCTUnwrap(InspectorSourceLocation(notification: event(file.absoluteString),
                                                             project: fixture.project, opensOnSelection: false))
        let filePosition = file.path + ":12:3"
        XCTAssertEqual(InspectorEditor.vsCode.arguments(for: location), ["--goto", filePosition])
        XCTAssertEqual(InspectorEditor.cursor.arguments(for: location), ["--goto", filePosition])
        XCTAssertEqual(InspectorEditor.zed.arguments(for: location), [filePosition])
        let selection = event(file.absoluteString, source: "flutter.inspector")
        XCTAssertNotNil(InspectorSourceLocation(notification: selection, project: fixture.project, opensOnSelection: true))
        XCTAssertNil(InspectorSourceLocation(notification: selection, project: fixture.project, opensOnSelection: false))
        for invalid in [
            event(outside.absoluteString), event(link.absoluteString), event("https://localhost/main.dart"),
            event(file.absoluteString, line: true), event(file.absoluteString, line: 0),
            event(file.absoluteString, source: "devtools.rebuildStats")
        ] {
            XCTAssertNil(InspectorSourceLocation(notification: invalid, project: fixture.project, opensOnSelection: true))
        }
    }

    func testF5ShortcutsHaveExactModifiersAndIgnoreRepeats() {
        let expected: [(NSEvent.ModifierFlags, DebugAction?)] = [
            ([], .run), ([.shift], .stop), ([.option], .reload), ([.shift, .command], .restart),
            ([.command], nil), ([.control], nil), ([.option, .shift], nil)
        ]
        for (flags, action) in expected {
            XCTAssertEqual(DebugAction(keyCode: 96, modifiers: flags, isRepeat: false), action, "F5 modifiers: \(flags)")
            XCTAssertNil(DebugAction(keyCode: 96, modifiers: flags, isRepeat: true))
        }
        XCTAssertNil(DebugAction(keyCode: 48, modifiers: [], isRepeat: false), "Tab is not a debug action")
    }

    func testCurrentMachineAppAndVMVerificationGateProdRecovery() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let original = try fixture.configurationBytes()
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: #"""
            printf '%s\n' "$@" > .runlet-fixture/flutter-args
            printf '%s\n' "$PWD" > .runlet-fixture/flutter-cwd
            printf '%s\n' '[{"event":"app.start","params":{"appId":"current","deviceId":"ios-fixture","mode":"debug"}}]'
            printf '%s\n' '[{"event":"app.debugPort","params":{"appId":"old","wsUri":"ws://127.0.0.1:8181/stale=/ws"}}]'
            printf '%s' 'VM Service: http://127.0.0.1:8181/priv'
            printf '%s\n' 'ate=/'
            printf '%s\n' '[{"event":"app.debugPort","params":{"appId":"current","wsUri":"ws://127.0.0.1:8181/private=/ws"}}]'
            : > .runlet-fixture/debug-started
            IFS= read -r command
            printf '%s\n' "$command" > .runlet-fixture/debug-command
            printf '%s\n' '[{"id":1,"result":true}]'
            (
                /bin/sleep 0.25
                /bin/cat .runlet-fixture/firebase-environment > .runlet-fixture/before-group-exit
            ) &
            exit 0
            """#)
        let session = controller(fixture, store: store, executable: executable) { url in
            XCTAssertEqual(url.absoluteString, "ws://127.0.0.1:8181/private=/ws")
            return FileManager.default.fileExists(atPath: fixture.state("verify-vm").path)
        }
        try fixture.select("prod", in: session)
        do {
            try await eventually { session.devices == [self.device] }
            session.selectDevice(device.id)
            XCTAssertTrue(session.canRun)
            session.run()
            session.run()
            try await fixture.waitFor("debug-started")
            XCTAssertNotEqual(session.status, .running)
            XCTAssertEqual(try fixture.marker(), "prod\n")
            XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
            try Data().write(to: fixture.state("verify-vm"))
            try await eventually { session.vmConnected }
            XCTAssertEqual(session.status, .running)
            // Log delivery is batched independently of VM verification.
            try await eventually { session.logs.contains("127.0.0.1:8181") }
            XCTAssertTrue(session.logs.contains("127.0.0.1:8181"))
            XCTAssertFalse(session.logs.contains("private="))
            XCTAssertFalse(session.logs.contains("stale="))
            session.stop()
            await session.waitUntilIdle()
            let stop = try String(contentsOf: fixture.state("debug-command"), encoding: .utf8)
            XCTAssertTrue(stop.contains("app.stop"))
            XCTAssertTrue(stop.contains("current"))
            let lastBeforeExit = try String(contentsOf: fixture.state("before-group-exit"), encoding: .utf8)
            XCTAssertEqual(lastBeforeExit, "prod\n")
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
            XCTAssertFalse(session.vmConnected)
            XCTAssertEqual(try fixture.configurationBytes(), original)
            let argv = try String(contentsOf: fixture.state("flutter-args"), encoding: .utf8).split(separator: "\n")
            XCTAssertEqual(argv.filter { $0.hasPrefix("--dart-define=") }, [
                "--dart-define=APP_ENV=prod", "--dart-define=ENABLE_SAMPLE_FEATURE=false",
                "--dart-define=DEMO_BUILD_NUMBER=1001",
            ])
            XCTAssertEqual(argv.filter { $0 == "--machine" }.count, 1)
            XCTAssertTrue(argv.contains("ios-fixture"))
            let directory = try ProjectLocation.directory(fixture.project)
            XCTAssertEqual(try String(contentsOf: fixture.state("flutter-cwd"), encoding: .utf8), directory.path + "\n")
        } catch {
            XCTFail("\(session.status) / \(session.displayMessage.map { chinese.appString($0) } ?? "") / \(session.logs)")
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testRunOpensOnlyTheSelectedIOSSimulatorAndContinuesIfOpeningFails() async throws {
        for isSimulator in [true, false] {
            let fixture = try SessionFixture()
            defer { fixture.remove() }
            let store = try ProjectRecoveryStore(directory: fixture.storage)
            let executable = try makeFlutter(in: fixture, script: #"""
                printf '%s\n' "$5" > .runlet-fixture/debug-device
                while [ ! -f .runlet-fixture/finish-debug ]; do /bin/sleep .02; done
                exit 42
                """#)
            let selected = FlutterDevice(id: "selected", name: "Selected iPhone", platform: "ios", isSimulator: isSimulator)
            let sdk = FlutterSDK(executable: executable, flutterVersion: "test", dartVersion: "test")
            var toolchain = FlutterToolchain(resolve: { _, _ in sdk }, discover: { [device] _, _ in [device, selected] })
            var opened: [String] = []
            toolchain.showSimulator = { id, _ in
                opened.append(id)
                XCTAssertEqual(try fixture.marker(), "prod\n")
                XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-device").path))
                throw SessionIssue("窗口打开失败")
            }
            let session = SessionController(store: store, runner: .bundled, environment: fixture.environment,
                                            toolchain: toolchain)
            try fixture.select("prod", in: session)
            try await eventually { !session.isRefreshingDevices && session.devices.contains(selected) }
            session.selectDevice(selected.id)
            XCTAssertTrue(opened.isEmpty)
            session.run()
            do {
                try await eventually {
                    FileManager.default.fileExists(atPath: fixture.state("debug-device").path)
                }
                XCTAssertEqual(session.feedback?.title.key,
                               isSimulator ? "Could not open the iOS simulator window" : nil)
                try Data().write(to: fixture.state("finish-debug"))
            } catch {
                session.stop()
                await session.waitUntilIdle()
                throw error
            }
            await session.waitUntilIdle()

            XCTAssertTrue(session.displayMessage.map { chinese.appString($0).contains("42") } ?? false)
            XCTAssertEqual(opened, isSimulator ? [selected.id] : [])
            XCTAssertEqual(try String(contentsOf: fixture.state("debug-device"), encoding: .utf8), "selected\n")
            XCTAssertEqual(try fixture.marker(), "test\n")

            let mainWindow = MainWindowView(presentation: .empty, session: session, run: {}, openSettings: nil)
            XCTAssertTrue(chinese.appString(mainWindow.statusMessage).contains("42"))
            session.run()
            XCTAssertEqual(session.status, .checkingToolchain)
            XCTAssertTrue(session.displayMessage.map { chinese.appString($0).contains("42") } ?? false)
            XCTAssertEqual(mainWindow.statusMessage, SessionStatus.checkingToolchain.title)
            session.stop()
            XCTAssertEqual(mainWindow.statusMessage, SessionStatus.stopping.title)
            await session.waitUntilIdle()
        }
    }

    func testInvalidPreflightLeavesEnvironmentAndRiskUntouched() async throws {
        for change in ["missing-sdk", "offline", "discovery-error", "conflict", "non-debug", "edited",
                       "application-args", "duplicate-machine"] {
            let fixture = try SessionFixture()
            defer { fixture.remove() }
            let executable = try makeFlutter(in: fixture, script: ": > .runlet-fixture/debug-started")
            let store = try ProjectRecoveryStore(directory: fixture.storage)
            let discovery = DeviceDiscovery([device])
            let toolchain = FlutterToolchain(
                resolve: { _, _ in
                    guard change != "missing-sdk" else { throw SessionIssue("SDK 不可用") }
                    return FlutterSDK(executable: executable, flutterVersion: "test", dartVersion: "test")
                },
                discover: { _, _ in
                    if discovery.fails { throw SessionIssue("扫描失败") }
                    return discovery.devices
                }
            )
            let session = SessionController(store: store, runner: .bundled, environment: fixture.environment,
                                            toolchain: toolchain)
            var source = try String(contentsOf: fixture.config("launch"), encoding: .utf8)
            let prod = #""name": "sample-flutter-app(prod)","#
            switch change {
            case "conflict":
                source = source.replacingOccurrences(of: prod, with: prod + #" "deviceId": "another","#)
            case "non-debug":
                source = source.replacingOccurrences(of: #""flutterMode": "debug""#, with: #""flutterMode": "release""#)
            case "application-args":
                source = source.replacingOccurrences(of: #""--dart-define=APP_ENV=prod","#,
                                                      with: #""ordinary-arg", "--dart-define=APP_ENV=prod","#)
            case "duplicate-machine":
                source = source.replacingOccurrences(of: prod, with: prod + #" "toolArgs": ["--machine"],"#)
            default: break
            }
            try source.write(to: fixture.config("launch"), atomically: true, encoding: .utf8)
            try fixture.select("prod", in: session)
            if change != "missing-sdk" {
                try await eventually { !session.isRefreshingDevices && session.devices == [self.device] }
                session.selectDevice(device.id)
            }
            if change == "offline" { discovery.devices = [] }
            if change == "discovery-error" { discovery.fails = true }
            if change == "edited" {
                let changed = source.replacingOccurrences(of: "--dart-define=APP_ENV=prod", with: "--dart-define=APP_ENV=changed")
                try changed.write(to: fixture.config("launch"), atomically: true, encoding: .utf8)
            }
            let original = try fixture.configurationBytes()
            session.run()
            await session.waitUntilIdle()
            XCTAssertNotNil(session.displayMessage, change)
            XCTAssertEqual(try fixture.marker(), "test\n", change)
            XCTAssertNil(try store.read(project: fixture.project), change)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path), change)
            XCTAssertEqual(try fixture.configurationBytes(), original, change)
        }
    }

    func testRecoveryContinuationRechecksConfigurationAndDeviceBeforeNewPreTask() async throws {
        for change in ["configuration", "device"] {
            let fixture = try SessionFixture()
            defer { fixture.remove() }
            let executable = try makeFlutter(in: fixture, script: ": > .runlet-fixture/debug-started")
            let store = try ProjectRecoveryStore(directory: fixture.storage)
            let discovery = DeviceDiscovery([device])
            let session = controller(fixture, store: store, executable: executable, discovery: discovery) { _ in false }
            try fixture.select("prod", in: session)
            try await eventually { session.canRun }
            try Data().write(to: fixture.state("fail-before-test"))
            session.run()
            await session.waitUntilIdle()
            XCTAssertEqual(session.status, .recoveryFailed)
            try FileManager.default.removeItem(at: fixture.state("debug-started"))
            try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
            session.select("sample-flutter-app(dev)")
            XCTAssertTrue(session.canRunAfterRecovery)

            if change == "configuration" {
                let url = fixture.config("launch")
                let source = try String(contentsOf: url, encoding: .utf8)
                try source.replacingOccurrences(of: "--dart-define=APP_ENV=dev", with: "--dart-define=APP_ENV=edited")
                    .write(to: url, atomically: true, encoding: .utf8)
            } else {
                discovery.devices = []
            }
            session.runAfterRecovery()
            await session.waitUntilIdle()
            XCTAssertEqual(try fixture.marker(), "test\n", change)
            XCTAssertNil(try store.read(project: fixture.project), change)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("debug-started").path), change)
            XCTAssertNotNil(session.displayMessage, change)
        }
    }

    func testRunAgainRestartsOriginalDeviceOnlyAfterSuccessfulRecovery() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let files = FileManager.default
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let pause = fixture.state("pause-after-test")
        let launches = fixture.state("launches")
        let secondDevice = FlutterDevice(id: "other", name: "Other", platform: "ios", isSimulator: false)
        let discovery = DeviceDiscovery([device, secondDevice])
        let executable = try makeFlutter(in: fixture, script: #"""
            printf '%s\n' "$5" >> .runlet-fixture/launches
            """# + "\n" + Self.machineReady + "\n" + #"""
            while IFS= read -r command; do
                case "$command" in *app.stop*) exit 0 ;; esac
            done
            """#)
        let session = controller(fixture, store: store, executable: executable, discovery: discovery) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { session.devices.count == 2 && !session.isRefreshingDevices }
        session.selectDevice(device.id)
        XCTAssertTrue(session.canRun)
        session.run()
        XCTAssertEqual(session.status, .checkingToolchain)
        let runAvailabilityChanged = OSAllocatedUnfairLock(initialState: false)
        XCTAssertFalse(withObservationTracking {
            session.canPerformDebugAction(.run, source: .menuBar)
        } onChange: {
            runAvailabilityChanged.withLock { $0 = true }
        })

        do {
            try await eventually { session.status == .running }
            XCTAssertTrue(runAvailabilityChanged.withLock { $0 }, "启动期间已打开的菜单须重新读取 Run 的启用状态")
            session.selectDevice(secondDevice.id)
            XCTAssertEqual(session.selectedDeviceID, secondDevice.id)
            XCTAssertTrue(session.performDebugAction(.run, source: .mainWindow) { launch in
                XCTAssertEqual(launch.configurationName, "sample-flutter-app(prod)")
                XCTAssertEqual(launch.device.id, self.device.id)
                return false
            })
            XCTAssertEqual(session.status, .running)
            XCTAssertEqual(try String(contentsOf: launches, encoding: .utf8), "\(device.id)\n")

            try Data().write(to: pause)
            XCTAssertTrue(session.performDebugAction(.run, source: .menuBar) { _ in true })
            try await fixture.waitFor("paused-after-test")
            XCTAssertEqual(session.status, .restoringEnvironment)
            XCTAssertFalse(session.canPerformDebugAction(.run))
            XCTAssertEqual(try String(contentsOf: launches, encoding: .utf8), "\(device.id)\n")
            try files.removeItem(at: pause)

            try await eventually { session.status == .running }
            XCTAssertEqual(try String(contentsOf: launches, encoding: .utf8), "\(device.id)\n\(device.id)\n")
            XCTAssertEqual(session.selectedDeviceID, secondDevice.id)

            try Data().write(to: fixture.state("fail-before-test"))
            XCTAssertTrue(session.performDebugAction(.run, source: .mainWindow) { _ in true })
            await session.waitUntilIdle()
            XCTAssertEqual(session.status, .recoveryFailed)
            XCTAssertNotNil(try store.read(project: fixture.project))
            XCTAssertEqual(try String(contentsOf: launches, encoding: .utf8), "\(device.id)\n\(device.id)\n")
        } catch {
            try? files.removeItem(at: pause)
            _ = await session.finishForTermination()
            throw error
        }
    }

    func testHotOperationsWaitForCurrentFlutterResultAndKeepStopAvailable() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            count=0
            while IFS= read -r command; do
                count=$((count + 1))
                printf '%s\n' "$command" > ".runlet-fixture/command-$count"
                case "$command" in
                    *app.stop*) exit 0 ;;
                esac
                if [ "$count" -eq 3 ]; then continue; fi
                printf '%s\n' '[{"id":999,"result":{"code":0}}]'
                while [ ! -f ".runlet-fixture/reply-$count" ]; do /bin/sleep .02; done
                /bin/cat ".runlet-fixture/reply-$count"
            done
            """#)
        let clock = ControlledDebugClock()
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        XCTAssertFalse(session.performDebugAction(.reload))
        XCTAssertFalse(session.performDebugAction(.stop))
        XCTAssertTrue(session.performDebugAction(.run))
        XCTAssertFalse(session.performDebugAction(.run))
        do {
            try await eventually { session.canHotOperate }
            XCTAssertTrue(session.canPerformDebugAction(.run))
            XCTAssertTrue(session.performDebugAction(.reload))
            XCTAssertFalse(session.performDebugAction(.restart))
            try await fixture.waitFor("command-1")
            XCTAssertFalse(session.canHotOperate)
            XCTAssertTrue(session.canStop)
            XCTAssertNil(session.feedback)
            let reload = try request(fixture, number: 1)
            XCTAssertEqual(reload.method, "app.restart")
            XCTAssertEqual(reload.appID, "current")
            XCTAssertEqual(reload.fullRestart, false)
            try reply(fixture, to: reload.id, number: 1, code: 0)
            try await eventually { session.feedback.map { self.chinese.appString($0.title) } == "已热重载" }
            XCTAssertTrue(session.canHotOperate)
            let preferences = try XCTUnwrap(UserDefaults(suiteName: "FlutterRunletTests.Feedback.\(UUID().uuidString)"))
            let language = AppLanguageSettings(defaults: preferences)
            defer { preferences.removeObject(forKey: AppLanguageSettings.preferenceKey) }
            language.selection = .simplifiedChinese
            let title = try XCTUnwrap(session.feedback?.title)
            let selectedID = session.selectedID
            let logs = session.logs
            XCTAssertEqual(language.locale.appString(title), "已热重载")
            language.selection = .english
            XCTAssertEqual(language.locale.appString(title), "Hot Reload Completed")
            XCTAssertEqual(session.selectedID, selectedID)
            XCTAssertEqual(session.logs, logs)
            XCTAssertTrue(session.vmConnected)
            XCTAssertTrue(session.canStop)
            session.dismissFeedback()

            XCTAssertTrue(session.performDebugAction(.restart))
            try await fixture.waitFor("command-2")
            let restart = try request(fixture, number: 2)
            XCTAssertEqual(restart.appID, reload.appID)
            XCTAssertEqual(restart.fullRestart, true)
            XCTAssertNotEqual(restart.id, reload.id)
            try reply(fixture, to: restart.id, number: 2, code: 1)
            try await eventually { session.feedback.map { self.chinese.appString($0.title) } == "热重启未完成" }
            let failure = try XCTUnwrap(session.feedback)
            let detail = try XCTUnwrap(failure.detail)
            XCTAssertEqual(language.locale.appString(failure.title), "Hot Restart Incomplete")
            XCTAssertEqual(language.locale.appString(detail), "Flutter returned error code 1. Check the current debug connection and try again.")
            language.selection = .simplifiedChinese
            XCTAssertEqual(language.locale.appString(failure.title), "热重启未完成")
            XCTAssertEqual(language.locale.appString(detail), "Flutter 返回错误码 1。请确认当前调试连接后重试。")
            XCTAssertTrue(session.vmConnected)
            session.dismissFeedback()

            XCTAssertTrue(session.performDebugAction(.reload))
            try await fixture.waitFor("command-3")
            try await eventually { clock.hasSleeper(.seconds(30)) }
            clock.advance(by: .seconds(30))
            try await eventually { session.feedback.map { self.chinese.appString($0.title) } == "热重载未完成" }
            XCTAssertTrue(session.canStop)
            XCTAssertTrue(session.performDebugAction(.stop))
            XCTAssertFalse(session.performDebugAction(.stop))
            await session.waitUntilIdle()
            XCTAssertNil(session.feedback)
            XCTAssertEqual(try fixture.marker(), "test\n")
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testWaitStartsAtWorkerSpawnAndRemainsStoppableAfterSixtySeconds() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let script = fixture.project.appending(path: "scripts/simulate-firebase-switch.sh")
        let original = try String(contentsOf: script, encoding: .utf8)
        try original.replacingOccurrences(of: "#!/bin/sh\n", with: #"""
            #!/bin/sh
            if [ "$1" = prod ]; then
                : > .runlet-fixture/pre-started
                while [ ! -f .runlet-fixture/pre-finish ]; do /bin/sleep .02; done
            fi

            """#).write(to: script, atomically: true, encoding: .utf8)
        let executable = try makeFlutter(in: fixture, script: #"""
            : > .runlet-fixture/debug-started
            IFS= read -r command
            """#)
        let clock = ControlledDebugClock()
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing) { _ in false }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        XCTAssertTrue(session.status.showsLaunchProgress)
        do {
            try await fixture.waitFor("pre-started")
            clock.advance(by: .seconds(80))
            XCTAssertEqual(session.status, .runningPreTask)
            XCTAssertTrue(session.status.showsLaunchProgress)
            XCTAssertFalse(session.canHotOperate)
            try Data().write(to: fixture.state("pre-finish"))
            try await fixture.waitFor("debug-started")
            try await eventually { session.status == .waitingForVM && clock.hasSleeper(.seconds(60)) }
            clock.advance(by: .seconds(59))
            XCTAssertEqual(session.status, .waitingForVM)
            XCTAssertTrue(session.status.showsLaunchProgress)
            clock.advance(by: .seconds(1))
            try await eventually { session.status == .waitingLonger }
            XCTAssertTrue(session.status.showsLaunchProgress)
            XCTAssertTrue(session.canStop)
            XCTAssertFalse(session.canHotOperate)
            session.stop()
            XCTAssertFalse(session.status.showsLaunchProgress)
            await session.waitUntilIdle()
            clock.advance(by: .seconds(60))
            XCTAssertEqual(session.status, .ready)
            XCTAssertEqual(try fixture.marker(), "test\n")
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testVMReconnectDoesNotStopUntilDeviceScanConfirmsDisconnect() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            IFS= read -r command
            printf '%s\n' "$command" > .runlet-fixture/command-1
            (
                /bin/sleep .15
                /bin/cat .runlet-fixture/firebase-environment > .runlet-fixture/before-group-exit
            ) &
            """#)
        let clock = ControlledDebugClock()
        let discovery = DeviceDiscovery([device])
        let vm = DeviceDiscovery([device])
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing,
                                 discovery: discovery) { _ in !vm.devices.isEmpty }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canHotOperate && clock.hasSleeper(.seconds(2)) }
            func scan() async throws {
                try await eventually { clock.hasSleeper(.seconds(5)) }
                clock.advance(by: .seconds(5))
                try await eventually { clock.hasSleeper(.seconds(5)) }
            }
            func assertStillRunning() throws {
                XCTAssertTrue(session.canStop)
                XCTAssertEqual(try fixture.marker(), "prod\n")
                XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("command-1").path))
            }

            // An aggregate query can succeed with an empty result when a platform probe fails.
            discovery.devices = []
            try await scan()
            XCTAssertTrue(session.vmConnected)
            try assertStillRunning()
            discovery.devices = [device]
            try await scan()
            XCTAssertTrue(session.canHotOperate)

            vm.devices = []
            discovery.fails = true
            try await scan()
            try await eventually { session.status == .connectionInterrupted }
            let mainWindow = MainWindowView(presentation: .empty, session: session, run: {}, openSettings: nil)
            XCTAssertEqual(mainWindow.statusMessage,
                           "The VM Service connection was interrupted. Reconnecting. You can stop the current session.")
            XCTAssertFalse(session.canHotOperate)
            try assertStillRunning()
            vm.devices = [device]
            try await eventually { clock.hasSleeper(.milliseconds(500)) }
            clock.advance(by: .milliseconds(500))
            try await eventually { session.canHotOperate }
            discovery.fails = false
            discovery.devices = []
            vm.devices = []
            try await eventually { clock.hasSleeper(.seconds(2)) }
            clock.advance(by: .seconds(2))
            try await eventually { session.status == .connectionInterrupted }
            try await scan()
            try assertStillRunning()
            discovery.fails = true
            try await scan()
            discovery.fails = false
            try await scan()
            try assertStillRunning()
            try await eventually { clock.hasSleeper(.seconds(5)) }
            clock.advance(by: .seconds(5))
            try await fixture.waitFor("command-1")
            await session.waitUntilIdle()
            XCTAssertTrue(session.displayMessage.map { chinese.appString($0) }?.contains("已断开") == true)
            XCTAssertTrue(session.deviceIsOffline)
            XCTAssertEqual(try request(fixture, number: 1).method, "app.stop")
            XCTAssertEqual(try String(contentsOf: fixture.state("before-group-exit"), encoding: .utf8), "prod\n")
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testNaturalExitKeepsItsReasonThroughFailedRecoveryAndLateVMProbe() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            while [ ! -f .runlet-fixture/natural-exit ]; do /bin/sleep .02; done
            exit 7
            """#)
        try Data().write(to: fixture.state("fail-before-test"))
        let clock = ControlledDebugClock()
        var initialProbe = true
        var lateProbe: CheckedContinuation<Bool, Never>?
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing) { _ in
            if initialProbe {
                initialProbe = false
                return true
            }
            return await withCheckedContinuation { lateProbe = $0 }
        }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canHotOperate && clock.hasSleeper(.seconds(2)) }
            XCTAssertFalse(session.status.showsLaunchProgress)
            clock.advance(by: .seconds(2))
            try await eventually { lateProbe != nil }
            try Data().write(to: fixture.state("natural-exit"))
            await session.waitUntilIdle()
            lateProbe?.resume(returning: true)
            lateProbe = nil
            XCTAssertEqual(session.status, .recoveryFailed)
            XCTAssertFalse(session.status.showsLaunchProgress)
            XCTAssertFalse(session.canHotOperate)
            XCTAssertFalse(session.canStop)
            XCTAssertEqual(try store.read(project: fixture.project)?.taskLabel, "sample:select-test")
            try FileManager.default.removeItem(at: fixture.state("fail-before-test"))
            session.retryRecovery()
            await session.waitUntilIdle()
            XCTAssertEqual(session.status, .ready)
            XCTAssertTrue(session.displayMessage.map { chinese.appString($0) }?.contains("退出码 7") == true)
            XCTAssertFalse(session.vmConnected)
            XCTAssertEqual(try fixture.marker(), "test\n")
            XCTAssertNil(try store.read(project: fixture.project))
        } catch {
            lateProbe?.resume(returning: false)
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testStandaloneDevToolsStartsOnDemandReusesServerAndStopsWithSession() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\nIFS= read -r command")
        let directory = try makeStandaloneDevTools(in: fixture)

        var opened: [URL] = []
        var focused: [URL] = []
        var inspectorStillOpen = true
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = controller(fixture, store: store, executable: executable,
                                 openURL: { opened.append($0); return true },
                                 focusInspector: { focused.append($0); return inspectorStillOpen }) { _ in true }
        try fixture.select("test", in: session)
        session.selectStandaloneDevTools(directory)
        XCTAssertEqual(session.standaloneDevToolsVersion, "2.61.0")
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canOpenBrowser }
            XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.state("devtools-args").path))
            session.openBrowser(.devTools)
            session.openBrowser(.inspector)
            session.openBrowser(.inspector)
            try await fixture.waitFor("devtools-pid")
            XCTAssertTrue(opened.isEmpty)
            try Data().write(to: fixture.state("devtools-ready"))
            try await eventually { opened.count == 1 }
            session.openBrowser(.inspector)
            try await eventually { focused.count == 1 }
            XCTAssertEqual(focused, opened)
            inspectorStillOpen = false
            session.openBrowser(.inspector)
            try await eventually { opened.count == 2 }
            XCTAssertEqual(opened[0], opened[1])
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.map(\.path), ["/inspector", "/inspector", "/"])
            XCTAssertEqual(opened.map(\.port), [9123, 9123, 9123])
            for url in opened {
                XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                               [URLQueryItem(name: "uri", value: "ws://127.0.0.1:8181/private=/ws")])
            }
            let arguments = try String(contentsOf: fixture.state("devtools-args"), encoding: .utf8)
            XCTAssertEqual(arguments.split(separator: "\n"),
                           ["devtools", "--no-launch-browser", "--machine", "--host=127.0.0.1", "--port=0"])
            let pid = try XCTUnwrap(Int32(String(contentsOf: fixture.state("devtools-pid"), encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)))
            session.stop()
            await session.waitUntilIdle()
            XCTAssertEqual(kill(pid, 0), -1)
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testInspectorFocusDoesNotReopenAnExitedStandaloneServer() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\nIFS= read -r command")
        let directory = try makeStandaloneDevTools(in: fixture)
        var opened: [URL] = []
        var finishFocus: CheckedContinuation<Bool, Never>?
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let session = controller(fixture, store: store, executable: executable,
                                 openURL: { opened.append($0); return true }, focusInspector: { _ in
                                     await withCheckedContinuation { finishFocus = $0 }
                                 }) { _ in true }
        try fixture.select("test", in: session)
        session.selectStandaloneDevTools(directory)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.inspector)
            try Data().write(to: fixture.state("devtools-ready"))
            try await eventually { opened.count == 1 }
            session.openBrowser(.inspector)
            try await eventually { finishFocus != nil }
            try Data().write(to: fixture.state("devtools-exit"))
            try await eventually { session.feedback?.title.key == "Standalone DevTools stopped" }
            finishFocus?.resume(returning: false)
            finishFocus = nil
            try FileManager.default.removeItem(at: fixture.state("devtools-exit"))
            session.openBrowser(.inspector)
            try await eventually { opened.count >= 2 }
            XCTAssertEqual(opened.count, 2)
            let arguments = try String(contentsOf: fixture.state("devtools-args"), encoding: .utf8)
            XCTAssertEqual(arguments.split(separator: "\n").filter { $0 == "devtools" }.count, 2)
            session.stop()
            await session.waitUntilIdle()
        } catch {
            finishFocus?.resume(returning: false)
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testInspectorSourceSubscriptionRecoversWhileVMStaysConnected() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let file = fixture.project.appending(path: "main.dart")
        try Data().write(to: file)
        let server = try await ToolEventServer.start(file: file)
        defer { server.listener.cancel() }
        var connections: [Bool] = []
        var locations: [InspectorSourceLocation] = []
        let debug = FlutterDebugSession(deviceID: device.id, verifyVM: nil, timing: .continuous, sdk: nil,
                                        connectionChanged: { connections.append($0) }, browserAvailabilityChanged: { _ in },
                                        openSource: { event, _ in
                                            if let location = InspectorSourceLocation(notification: event, project: fixture.project,
                                                                                      opensOnSelection: false) {
                                                locations.append(location)
                                            }
                                        })
        defer { debug.finish() }
        debug.receive(#"[{"event":"app.start","params":{"appId":"current","deviceId":"ios-fixture","mode":"debug"}}]"#,
                      isError: false, output: { _, _ in })
        debug.receive(#"[{"event":"app.debugPort","params":{"appId":"current","wsUri":"ws://127.0.0.1:\#(server.port)/ws"}}]"#,
                      isError: false, output: { _, _ in })
        try await eventually { locations.count == 1 }
        XCTAssertEqual(connections, [true])
        XCTAssertEqual(locations[0].file, file.resolvingSymlinksInPath())
        XCTAssertEqual(locations[0].line, 12)
        XCTAssertEqual(locations[0].column, 3)
    }

    func testInspectorTabMatchingIgnoresBrowserOptionsButNotSessionOrPage() throws {
        let origin = "http://127.0.0.1:9100"
        let inspector = try XCTUnwrap(URL(string: origin + "/inspector?uri=ws://127.0.0.1:8181/current=/ws"))
        let encoded = try XCTUnwrap(URL(string: origin + "/inspector?compiler=wasm&uri=ws%3A%2F%2F127.0.0.1%3A8181%2Fcurrent%3D%2Fws"))
        XCTAssertTrue(InspectorBrowserTabs.matches(encoded, inspector: inspector))
        for other in [
            origin + "/inspector?uri=ws://127.0.0.1:8181/previous=/ws",
            origin + "/inspector?uri=ws://127.0.0.1:8181/current=/ws&uri=other",
            origin + "/memory?uri=ws://127.0.0.1:8181/current=/ws",
            "http://127.0.0.1:9101/inspector?uri=ws://127.0.0.1:8181/current=/ws"
        ] {
            XCTAssertFalse(InspectorBrowserTabs.matches(try XCTUnwrap(URL(string: other)), inspector: inspector))
        }
    }

    func testBrowserUsesOnlyCurrentBoundAddressAndReconnectsBeforeOpeningAgain() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"old","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"https://example.test/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/stale=/ws"}}]'
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/other=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            printf '%s\n' 'DevTools http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws'
            printf '%s\n' 'invalid reports consumed'
            while [ ! -f .runlet-fixture/browser-ready ]; do /bin/sleep .02; done
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws%3A%2F%2F127.0.0.1%3A8181%2Fprivate%3D%2Fws"}}]'
            IFS= read -r command
            """#)
        let clock = ControlledDebugClock()
        var vmOnline = true
        var opened: [URL] = []
        var canLaunchBrowser = false
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing,
                                 flutterVersion: "3.47.4", devToolsVersion: "2.60.0",
                                 openURL: { opened.append($0); return canLaunchBrowser }) { _ in vmOnline }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.vmConnected && session.logs.contains("invalid reports consumed") }
            XCTAssertFalse(session.canOpenBrowser)
            session.openBrowser(.inspector)
            XCTAssertTrue(opened.isEmpty)
            try Data().write(to: fixture.state("browser-ready"))
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.devTools)
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "无法打开 DevTools")
            canLaunchBrowser = true
            session.openBrowser(.inspector)
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "已打开 Inspector")
            let inspector = try XCTUnwrap(opened.last)
            XCTAssertTrue(inspector.path.hasSuffix("/devtools/inspector"))
            XCTAssertEqual(URLComponents(url: inspector, resolvingAgainstBaseURL: false)?
                .queryItems?.first?.value, "ws://127.0.0.1:8181/private=/ws")
            XCTAssertFalse(session.logs.contains("private="))

            vmOnline = false
            try await eventually { clock.hasSleeper(.seconds(2)) }
            clock.advance(by: .seconds(2))
            try await eventually { !session.vmConnected }
            XCTAssertFalse(session.canOpenBrowser)
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.count, 2)
            vmOnline = true
            try await eventually { clock.hasSleeper(.milliseconds(500)) }
            clock.advance(by: .milliseconds(500))
            try await eventually { session.canOpenBrowser }

            session.stop()
            await session.waitUntilIdle()
            XCTAssertFalse(session.canOpenBrowser)
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.count, 2)
            let next = Self.machineReady.replacingOccurrences(of: "8181/private=", with: "8182/next=")
            _ = try makeFlutter(in: fixture, script: next + "\n" + #"""
                printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
                printf '%s\n' 'old report consumed'
                while [ ! -f .runlet-fixture/next-browser ]; do /bin/sleep .02; done
                printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8182/next=/devtools/?uri=ws://127.0.0.1:8182/next=/ws"}}]'
                IFS= read -r command
                """#)
            session.run()
            try await eventually { session.vmConnected && session.logs.contains("old report consumed") }
            XCTAssertFalse(session.canOpenBrowser)
            try Data().write(to: fixture.state("next-browser"))
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.last?.port, 8182)
            XCTAssertTrue(opened.last?.path.contains("/next=/devtools") == true)
            session.stop()
            await session.waitUntilIdle()
        } catch {
            try? Data().write(to: fixture.state("browser-ready"))
            try? Data().write(to: fixture.state("next-browser"))
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testChangingNextDeviceKeepsRunningSessionAndItsToolsOnOriginalDevice() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let next = FlutterDevice(id: "ios-next", name: "Next iPhone", platform: "ios", isSimulator: true)
        let discovery = DeviceDiscovery([device, next])
        let executable = try makeFlutter(in: fixture, script: #"""
            case "$5" in
              ios-fixture) app=first; port=8181 ;;
              ios-next) app=second; port=8182 ;;
              *) exit 2 ;;
            esac
            printf '%s\n' "$5" >> .runlet-fixture/launch-devices
            printf '[{"event":"app.start","params":{"appId":"%s","deviceId":"%s","mode":"debug","supportsRestart":true}}]\n' "$app" "$5"
            printf '[{"event":"app.debugPort","params":{"appId":"%s","wsUri":"ws://127.0.0.1:%s/private=/ws"}}]\n' "$app" "$port"
            printf '[{"event":"app.devTools","params":{"appId":"%s","uri":"http://127.0.0.1:%s/private=/devtools/?uri=ws://127.0.0.1:%s/private=/ws"}}]\n' "$app" "$port" "$port"
            while IFS= read -r command; do
                case "$command" in
                  *app.restart*)
                    printf '%s\n' "$command" > .runlet-fixture/command-1
                    while [ ! -f .runlet-fixture/reply-1 ]; do /bin/sleep .02; done
                    /bin/cat .runlet-fixture/reply-1
                    ;;
                  *app.stop*) break ;;
                esac
            done
            """#)
        let clock = ControlledDebugClock()
        var opened: [URL] = []
        let session = controller(fixture, store: store, executable: executable, timing: clock.timing,
                                 discovery: discovery, flutterVersion: "3.47.4", devToolsVersion: "2.61.0",
                                 openURL: { opened.append($0); return true }) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { !session.isRefreshingDevices }
        session.selectDevice(device.id)
        XCTAssertTrue(session.canRun)
        session.run()
        session.selectDevice(next.id)
        XCTAssertEqual(session.selectedDeviceID, device.id, "启动预检时仍锁定下次选择")
        do {
            try await eventually { session.canOpenBrowser && session.canHotOperate }
            session.selectDevice(next.id)
            XCTAssertEqual(session.selectedDeviceID, next.id)
            XCTAssertEqual(session.activeLaunch?.device, device)
            XCTAssertEqual(session.activeLaunch?.configurationName, "sample-flutter-app(prod)")

            discovery.devices = [device]
            discovery.shutdown = [FlutterSimulator(id: next.id, name: next.name)]
            try await eventually { clock.hasSleeper(.seconds(5)) }
            clock.advance(by: .seconds(5))
            try await eventually { !session.canStop || clock.hasSleeper(.seconds(5)) }
            XCTAssertTrue(session.canStop, "仅 B 关机时，A 的监测不能停止当前调试")
            XCTAssertTrue(session.performDebugAction(.reload))
            try await fixture.waitFor("command-1")
            let request = try request(fixture, number: 1)
            XCTAssertEqual(request.appID, "first")
            XCTAssertEqual(request.fullRestart, false)
            try reply(fixture, to: request.id, number: 1, code: 0)
            try await eventually { session.canHotOperate }
            session.openBrowser(.devTools)
            session.openBrowser(.inspector)
            XCTAssertEqual(opened.map(\.port), [8181, 8181])
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "已打开当前会话的 DevTools，请选择 Inspector。")
            session.stop()
            await session.waitUntilIdle()
            XCTAssertNil(session.activeLaunch)
            XCTAssertEqual(session.selectedDeviceID, next.id)
            XCTAssertEqual(try fixture.marker(), "test\n")

            session.run()
            await session.waitUntilIdle()
            XCTAssertEqual(try fixture.marker(), "test\n", "重新发现 B 离线时不得运行 prod 前置")
            XCTAssertNil(try store.read(project: fixture.project))
            XCTAssertEqual(try String(contentsOf: fixture.state("launch-devices"), encoding: .utf8), "ios-fixture\n")
            XCTAssertFalse(session.canRun)

            discovery.devices = [device, next]
            discovery.shutdown = []
            session.refreshDevices()
            try await eventually { session.canRun }
            session.run()
            try await eventually { session.canOpenBrowser }
            XCTAssertEqual(session.activeLaunch?.device, next)
            session.openBrowser(.devTools)
            XCTAssertEqual(opened.last?.port, 8182)
            XCTAssertEqual(try String(contentsOf: fixture.state("launch-devices"), encoding: .utf8), "ios-fixture\nios-next\n")
            session.stop()
            await session.waitUntilIdle()
        } catch {
            try? reply(fixture, to: 0, number: 1, code: 1)
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    func testUntestedInspectorVersionOpensConnectedDevToolsWithFallbackFeedback() async throws {
        let fixture = try SessionFixture()
        defer { fixture.remove() }
        let store = try ProjectRecoveryStore(directory: fixture.storage)
        let executable = try makeFlutter(in: fixture, script: Self.machineReady + "\n" + #"""
            printf '%s\n' '[{"event":"app.devTools","params":{"appId":"current","uri":"http://127.0.0.1:8181/private=/devtools/?uri=ws://127.0.0.1:8181/private=/ws"}}]'
            IFS= read -r command
            """#)
        var opened: URL?
        let session = controller(fixture, store: store, executable: executable,
                                 flutterVersion: "3.47.4", devToolsVersion: "2.61.0",
                                 openURL: { opened = $0; return true }) { _ in true }
        try fixture.select("prod", in: session)
        try await eventually { session.canRun }
        session.run()
        do {
            try await eventually { session.canOpenBrowser }
            session.openBrowser(.inspector)
            XCTAssertTrue(opened?.path.hasSuffix("/devtools") == true)
            XCTAssertEqual(session.feedback.map { chinese.appString($0.title) }, "已打开当前会话的 DevTools，请选择 Inspector。")
            session.stop()
            await session.waitUntilIdle()
        } catch {
            session.stop()
            await session.waitUntilIdle()
            throw error
        }
    }

    private static let machineReady = #"""
        printf '%s\n' '[{"event":"app.start","params":{"appId":"current","deviceId":"ios-fixture","mode":"debug","supportsRestart":true}}]'
        printf '%s\n' '[{"event":"app.debugPort","params":{"appId":"current","wsUri":"ws://127.0.0.1:8181/private=/ws"}}]'
        """#

    private struct MachineRequest: Decodable {
        struct Params: Decodable {
            let appId: String
            let fullRestart: Bool?
        }
        let id: Int
        let method: String
        let params: Params
        var appID: String { params.appId }
        var fullRestart: Bool? { params.fullRestart }
    }

    private func request(_ fixture: SessionFixture, number: Int) throws -> MachineRequest {
        let data = try Data(contentsOf: fixture.state("command-\(number)"))
        return try XCTUnwrap(JSONDecoder().decode([MachineRequest].self, from: data).first)
    }

    private func reply(_ fixture: SessionFixture, to id: Int, number: Int, code: Int) throws {
        try "[{\"id\":\(id),\"result\":{\"code\":\(code),\"message\":\"fixture\"}}]\n"
            .write(to: fixture.state("reply-\(number)"), atomically: true, encoding: .utf8)
    }

    private func controller(_ fixture: SessionFixture, store: ProjectRecoveryStore, executable: URL,
                            timing: FlutterDebugTiming = .continuous, discovery: DeviceDiscovery? = nil,
                            flutterVersion: String = "test", devToolsVersion: String? = nil,
                            openURL: @escaping (URL) -> Bool = { _ in false },
                            focusInspector: @escaping @MainActor (URL) async -> Bool = { _ in false },
                            verify: @escaping @MainActor (URL) async -> Bool) -> SessionController {
        let device = self.device
        return SessionController(store: store, runner: .bundled, environment: fixture.environment,
                                 toolchain: FlutterToolchain(
                                    resolve: { _, _ in
                                        FlutterSDK(executable: executable, flutterVersion: flutterVersion,
                                                   dartVersion: "test", devToolsVersion: devToolsVersion)
                                    },
                                    discover: { _, _ in
                                        if discovery?.fails == true { throw SessionIssue("扫描失败") }
                                        return discovery?.devices ?? [device]
                                    },
                                    simulators: { _ in
                                        guard let discovery else { return [] }
                                        return discovery.shutdown
                                    }
                                 ), verifyVM: verify, debugTiming: timing, openURL: openURL, focusInspector: focusInspector)
    }

    private func makeFlutter(in fixture: SessionFixture, script: String) throws -> URL {
        let executable = fixture.base.appending(path: "flutter")
        try ("#!/bin/sh\n" + script + "\n").write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        return executable
    }

    private func makeStandaloneDevTools(in fixture: SessionFixture) throws -> URL {
        let directory = fixture.base.appending(path: "DevTools SDK")
        let manifest = directory.appending(path: "bin/resources/devtools")
        try FileManager.default.createDirectory(at: manifest, withIntermediateDirectories: true)
        try #"{"app_name":"devtools_app","version":"2.61.0"}"#
            .write(to: manifest.appending(path: "version.json"), atomically: true, encoding: .utf8)
        let dart = directory.appending(path: "bin/dart")
        try #"""
            #!/bin/sh
            printf '%s\n' "$@" >> .runlet-fixture/devtools-args
            printf '%s\n' "$$" > .runlet-fixture/devtools-pid
            printf '%s\n' '{"event":"server.started","params":{"host":"example.test","port":9100}}'
            while [ ! -f .runlet-fixture/devtools-ready ]; do /bin/sleep .02; done
            printf '%s\n' '{"event":"server.started","params":{"host":"127.0.0.1","port":9123}}'
            while [ ! -f .runlet-fixture/devtools-exit ]; do /bin/sleep .02; done
            exit 19
            """#.write(to: dart, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: dart.path)
        return directory
    }

    private func eventually(_ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !condition() {
            guard .now < deadline else { throw SessionIssue("等待调试状态超时") }
            try await Task.sleep(for: .milliseconds(20))
        }
    }

    private final class DeviceDiscovery {
        var devices: [FlutterDevice]
        var fails = false
        var shutdown: [FlutterSimulator] = []
        init(_ devices: [FlutterDevice]) { self.devices = devices }
    }

    @MainActor
    private final class ControlledDebugClock {
        private var offset: Duration = .zero
        private var sleepers: [UUID: (Duration, Duration, CheckedContinuation<Void, any Error>)] = [:]

        var timing: FlutterDebugTiming {
            FlutterDebugTiming(elapsedSinceStart: { _ in .zero }, sleep: sleep)
        }

        func hasSleeper(_ duration: Duration) -> Bool {
            sleepers.values.contains { $0.0 == duration }
        }

        func advance(by duration: Duration) {
            offset += duration
            let elapsed = sleepers.filter { $0.value.1 <= offset }
            for (id, sleeper) in elapsed {
                sleepers[id] = nil
                sleeper.2.resume()
            }
        }

        private func sleep(_ duration: Duration) async throws {
            let id = UUID()
            try await withTaskCancellationHandler {
                try Task.checkCancellation()
                try await withCheckedThrowingContinuation { continuation in
                    sleepers[id] = (duration, offset + duration, continuation)
                }
            } onCancel: {
                Task { @MainActor in
                    self.sleepers.removeValue(forKey: id)?.2.resume(throwing: CancellationError())
                }
            }
        }
    }
}
