import AppKit
import CoreFoundation
import Darwin
import Foundation

struct FlutterDebugTiming {
    let elapsedSinceStart: @MainActor (UInt64) -> Duration
    let sleep: @MainActor (Duration) async throws -> Void

    static var continuous: Self {
        Self(elapsedSinceStart: { started in
            let now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
            return .nanoseconds(Int64(clamping: now >= started ? now - started : 0))
        }, sleep: { try await Task.sleep(for: $0) })
    }
}

enum FlutterHotOperation {
    case reload, restart
}

enum FlutterBrowserPage {
    case devTools, inspector

    var title: String { self == .devTools ? "DevTools" : "Inspector" }
}

struct StandaloneDevToolsSDK {
    let directory: URL
    let version: String

    var dart: URL { directory.appending(path: "bin/dart") }
    static func hasSourceLinks(_ version: String) -> Bool {
        version.compare("2.61.0", options: .numeric) != .orderedAscending
    }

    init?(directory: URL) {
        guard directory.isFileURL, let root = try? ProjectLocation.directory(directory),
              FileManager.default.isExecutableFile(atPath: root.appending(path: "bin/dart").path),
              let data = Self.readManifest(in: root),
              data.count < 4096,
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data),
              manifest.app_name == "devtools_app",
              manifest.version.range(of: #"^\d+\.\d+\.\d+(?:[-+][A-Za-z0-9.+-]+)?$"#,
                                     options: .regularExpression) != nil else { return nil }
        self.directory = root
        version = manifest.version
    }

    private static func readManifest(in directory: URL) -> Data? {
        let file = directory.appending(path: "bin/resources/devtools/version.json")
        guard (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true,
              let handle = try? FileHandle(forReadingFrom: file) else { return nil }
        defer { try? handle.close() }
        return try? handle.read(upToCount: 4096)
    }

    static func serverAddress(from line: String) -> URL? {
        guard let response = try? JSONDecoder().decode(StartupEvent.self, from: Data(line.utf8)),
              response.event == "server.started", response.params.host == "127.0.0.1",
              (1...65535).contains(response.params.port) else { return nil }
        return URL(string: "http://127.0.0.1:\(response.params.port)")
    }

    private struct Manifest: Decodable {
        let app_name: String
        let version: String
    }

    private struct StartupEvent: Decodable {
        struct Params: Decodable {
            let host: String
            let port: Int
        }
        let event: String
        let params: Params
    }
}

enum InspectorEditor: String, CaseIterable {
    case vsCode = "vscode"
    case cursor
    case zed

    var title: String {
        switch self {
        case .vsCode: "VS Code"
        case .cursor: "Cursor"
        case .zed: "Zed"
        }
    }

    private var bundleID: String {
        switch self {
        case .vsCode: "com.microsoft.VSCode"
        case .cursor: "com.todesktop.230313mzl4w4u92"
        case .zed: "dev.zed.Zed"
        }
    }

    private var launcherPath: String {
        switch self {
        case .vsCode: "Contents/Resources/app/bin/code"
        case .cursor: "Contents/Resources/app/bin/cursor"
        case .zed: "Contents/MacOS/cli"
        }
    }

    func arguments(for location: InspectorSourceLocation) -> [String] {
        let argument = "\(location.file.path):\(location.line):\(location.column)"
        return self == .zed ? [argument] : ["--goto", argument]
    }

    @MainActor
    func open(_ location: InspectorSourceLocation, onFailure: @escaping @MainActor @Sendable () -> Void) {
        guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            onFailure()
            return
        }
        let process = Process()
        process.executableURL = app.appending(path: launcherPath)
        process.arguments = arguments(for: location)
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.terminationHandler = { process in
            if process.terminationStatus != 0 { Task { @MainActor in onFailure() } }
        }
        do { try process.run() }
        catch { onFailure() }
    }
}

struct InspectorSourceLocation {
    let file: URL
    let line: Int
    let column: Int

    init?(notification: [String: Any], project: URL, opensOnSelection: Bool) {
        guard notification["jsonrpc"] as? String == "2.0",
              notification["method"] as? String == "streamNotify", notification["id"] == nil,
              let params = notification["params"] as? [String: Any], params["streamId"] as? String == "ToolEvent",
              let event = params["event"] as? [String: Any], event["kind"] as? String == "Extension",
              event["extensionKind"] as? String == "navigate",
              let data = event["extensionData"] as? [String: Any],
              let source = data["source"] as? String,
              source == "devtools.inspector" || (opensOnSelection && source == "flutter.inspector"),
              let path = data["fileUri"] as? String, path.utf8.count <= 8192,
              let uri = URLComponents(string: path), uri.scheme == "file",
              uri.host == nil || uri.host == "" || uri.host == "localhost",
              uri.user == nil, uri.password == nil, uri.port == nil, uri.query == nil, uri.fragment == nil,
              uri.path.hasPrefix("/"), uri.path.rangeOfCharacter(from: .controlCharacters) == nil,
              let line = Self.coordinate(data["line"]), let column = Self.coordinate(data["column"]) else { return nil }
        let file = URL(fileURLWithPath: uri.path).resolvingSymlinksInPath()
        guard file.pathExtension == "dart", ProjectLocation.contains(file, in: project),
              (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { return nil }
        self.file = file
        self.line = line
        self.column = column
    }

    private static func coordinate(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID(),
              let integer = value as? Int, (1...Int(Int32.max)).contains(integer) else { return nil }
        return integer
    }
}

@MainActor
final class FlutterDebugSession {
    typealias Verification = @MainActor (URL) async -> Bool
    typealias HotCompletion = (Result<Void, SessionIssue>) -> Void

    private let deviceID: String
    private let verifyVM: Verification?
    private let timing: FlutterDebugTiming
    private let testedInspectorRoute: Bool
    private let connectionChanged: (Bool) -> Void
    private let browserAvailabilityChanged: (Bool) -> Void
    private let openSource: (([String: Any], Bool) -> Void)?
    private let opensSourceOnSelection: Bool
    private var appID: String?
    private var endpoint: URL?
    private var reportedDevTools: URL?
    private var probe: Task<Void, Never>?
    private var sourceListener: Task<Void, Never>?
    private var hotTimeout: Task<Void, Never>?
    private var hotWork: Task<Void, Never>?
    private var hotRequest: (id: Int, operation: FlutterHotOperation, complete: HotCompletion)?
    private var restartBaseline: (endpoint: URL, isolates: [String: String])?
    private var nextID = 2  // app.stop uses request 1.
    private(set) var supportsRestart = false
    private(set) var hasVerifiedVM = false
    private var connected = false
    private var stopped = false
    var openedBrowserURLs: Set<URL> = []
    var hasActiveVMService: Bool { connected && !stopped && endpoint != nil }

    init(deviceID: String, verifyVM: Verification?, timing: FlutterDebugTiming, sdk: FlutterSDK?,
         connectionChanged: @escaping (Bool) -> Void,
         browserAvailabilityChanged: @escaping (Bool) -> Void,
         openSource: (([String: Any], Bool) -> Void)? = nil) {
        self.deviceID = deviceID
        self.verifyVM = verifyVM
        self.timing = timing
        testedInspectorRoute = sdk?.flutterVersion == "3.47.4" && sdk?.devToolsVersion == "2.60.0"
        opensSourceOnSelection = sdk?.devToolsVersion?.compare("2.61.0", options: .numeric) == .orderedAscending
        self.connectionChanged = connectionChanged
        self.browserAvailabilityChanged = browserAvailabilityChanged
        self.openSource = openSource
    }

    func finish() {
        invalidateConnection()
        appID = nil
    }

    func stopRequest() -> Data? {
        invalidateConnection()
        guard let appID else { return nil }
        return Self.request(id: 1, method: "app.stop", appID: appID)
    }

    func hotOperation(_ operation: FlutterHotOperation, send: @escaping (Data) -> Bool,
                      complete: @escaping HotCompletion) {
        guard connected, supportsRestart, !stopped, hotRequest == nil, let appID, let endpoint else {
            complete(.failure(SessionIssue(localized: "The current Flutter debug connection is unavailable")))
            return
        }
        let id = nextID
        nextID += 1
        guard let request = Self.request(id: id, method: "app.restart", appID: appID,
                                         fullRestart: operation == .restart) else {
            complete(.failure(SessionIssue(localized: "Could not send the command to the current Flutter process")))
            return
        }
        hotRequest = (id, operation, complete)
        if operation == .restart {
            hotWork = Task { [weak self] in
                let probe = VMServiceProbe(url: endpoint)
                defer { probe.close() }
                let isolates = await probe.viewIsolates()
                guard let self, !Task.isCancelled, self.hotRequest?.id == id else { return }
                self.hotWork = nil
                guard self.endpoint == endpoint else {
                    self.completeHot(.failure(SessionIssue(localized: "The current Flutter debug connection is unavailable")))
                    return
                }
                if let isolates, !isolates.isEmpty { self.restartBaseline = (endpoint, isolates) }
                self.sendHotRequest(request, id: id, send: send)
            }
        } else {
            sendHotRequest(request, id: id, send: send)
        }
    }

    private func sendHotRequest(_ request: Data, id: Int, send: (Data) -> Bool) {
        guard send(request) else {
            completeHot(.failure(SessionIssue(localized: "Could not send the command to the current Flutter process")))
            return
        }
        hotTimeout = Task { [weak self, timing] in
            do { try await timing.sleep(.seconds(30)) }
            catch { return }
            guard let self, !Task.isCancelled, self.hotRequest?.id == id else { return }
            self.completeHot(.failure(SessionIssue(localized: "Timed out waiting for Flutter to respond")))
        }
    }

    private func resetHotRequest() {
        hotRequest = nil
        restartBaseline = nil
        hotTimeout?.cancel()
        hotTimeout = nil
        hotWork?.cancel()
        hotWork = nil
    }

    private func completeHot(_ result: Result<Void, SessionIssue>) {
        let request = hotRequest
        resetHotRequest()
        request?.complete(result)
    }

    static func request(id: Int, method: String, appID: String, fullRestart: Bool? = nil) -> Data? {
        var params: [String: Any] = ["appId": appID]
        if let fullRestart { params["fullRestart"] = fullRestart }
        let message: [[String: Any]] = [["id": id, "method": method, "params": params]]
        guard var data = try? JSONSerialization.data(withJSONObject: message) else { return nil }
        data.append(0x0a)
        return data
    }

    private func invalidateConnection() {
        stopped = true
        probe?.cancel()
        probe = nil
        resetHotRequest()
        endpoint = nil
        reportedDevTools = nil
        openedBrowserURLs.removeAll()
        setConnected(false)
    }

    private func setConnected(_ value: Bool) {
        guard value != connected else { return }
        connected = value
        if value {
            hasVerifiedVM = true
            if let endpoint, let openSource, verifyVM == nil {
                sourceListener = Task { [timing, opensSourceOnSelection] in
                    while !Task.isCancelled {
                        do {
                            try await VMServiceProbe.listenForToolEvents(at: endpoint) { message in
                                if !Task.isCancelled { openSource(message, opensSourceOnSelection) }
                            }
                            return
                        } catch {
                            do { try await timing.sleep(.seconds(2)) }
                            catch { return }
                        }
                    }
                }
            }
        } else {
            sourceListener?.cancel()
            sourceListener = nil
        }
        connectionChanged(value)
        browserAvailabilityChanged(browserDestination(.devTools) != nil)
    }

    func receive(_ line: String, isError: Bool, output: (String, SessionLogTone?) -> Void) {
        if !isError, line.hasPrefix("["),
           let messages = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [[String: Any]],
           !messages.isEmpty,
           messages.allSatisfy({ $0["event"] is String || $0["id"] is Int }) {
            for message in messages { handle(message, output: output) }
            return
        }
        output(line, isError ? .diagnostic : SessionLogTone.flutterStatus(line))
    }

    private func handle(_ message: [String: Any], output: (String, SessionLogTone?) -> Void) {
        guard let event = message["event"] as? String else {
            handleResponse(message)
            return
        }
        guard let params = message["params"] as? [String: Any] else { return }
        switch event {
        case "app.start":
            guard !stopped, appID == nil, params["deviceId"] as? String == deviceID,
                  params["mode"] as? String == "debug",
                  let id = params["appId"] as? String, !id.isEmpty, id.utf8.count <= 256 else { return }
            appID = id
            supportsRestart = params["supportsRestart"] as? Bool == true
        case "app.debugPort":
            guard !stopped, matches(params), let address = params["wsUri"] as? String,
                  let url = Self.localEndpoint(address, schemes: ["ws", "wss"]), url != endpoint else { return }
            probe?.cancel()
            endpoint = url
            openedBrowserURLs.removeAll()
            setConnected(false)
            probe = Task { [weak self, verifyVM, timing] in
                let service = VMServiceProbe(url: url)
                defer { service.close() }
                while !Task.isCancelled {
                    let ready: Bool
                    if let verifyVM { ready = await verifyVM(url) }
                    else { ready = await service.verify() }
                    guard self?.applyProbe(ready, endpoint: url) == true else { return }
                    do { try await timing.sleep(ready ? .seconds(2) : .milliseconds(500)) }
                    catch { return }
                }
            }
        case "app.devTools":
            guard !stopped, matches(params), let address = params["uri"] as? String else { return }
            reportedDevTools = Self.localEndpoint(address, schemes: ["http", "https"])
            browserAvailabilityChanged(browserDestination(.devTools) != nil)
        case "app.log":
            guard matches(params), let log = params["log"] as? String else { return }
            output(log + "\n", params["error"] as? Bool == true ? .diagnostic : nil)
        case "app.stop":
            if matches(params) { invalidateConnection() }
        case "daemon.logMessage", "daemon.log":
            if let log = params["message"] as? String ?? params["log"] as? String {
                switch params["level"] as? String {
                case "error", "warning": output(log + "\n", .diagnostic)
                default: output(log + "\n", SessionLogTone.flutterStatus(log))
                }
            }
        default:
            break
        }
    }

    func browserDestination(_ page: FlutterBrowserPage) -> (url: URL, inspectorFallback: Bool)? {
        guard connected, !stopped, let endpoint, let reportedDevTools,
              let service = URLComponents(url: endpoint, resolvingAgainstBaseURL: false),
              var browser = URLComponents(url: reportedDevTools, resolvingAgainstBaseURL: false),
              let items = browser.queryItems?.filter({ $0.name == "uri" }),
              items.count == 1, let address = items[0].value,
              Self.bindsService(address, service: service) else { return nil }

        let onService = browser.host?.lowercased() == service.host?.lowercased() && browser.port == service.port
        if onService {
            guard service.path.hasSuffix("/ws") else { return nil }
            let devToolsPath = String(service.path.dropLast(2)) + "devtools"
            guard browser.path == devToolsPath || browser.path == devToolsPath + "/" else { return nil }
        }
        if page == .inspector, testedInspectorRoute, onService, browser.percentEncodedPath.hasSuffix("/devtools/") {
            // This authenticated DDS route was verified on the matching simulator SDK.
            browser.percentEncodedPath += "inspector"
            if let url = browser.url { return (url, false) }
        }
        return (reportedDevTools, page == .inspector)
    }

    func standaloneBrowserDestination(_ page: FlutterBrowserPage, server: URL,
                                      version: String) -> (url: URL, inspectorFallback: Bool)? {
        guard hasActiveVMService, let endpoint,
              var browser = URLComponents(url: server, resolvingAgainstBaseURL: false) else { return nil }
        // Verified with the standalone DevTools 2.61.0 server.
        let directInspector = page == .inspector && version == "2.61.0"
        browser.path = directInspector ? "/inspector" : "/"
        browser.queryItems = [URLQueryItem(name: "uri", value: endpoint.absoluteString)]
        return browser.url.map { ($0, page == .inspector && !directInspector) }
    }

    private static func bindsService(_ address: String, service: URLComponents) -> Bool {
        guard let url = localEndpoint(address, schemes: ["ws", "wss", "http", "https"]),
              let candidate = URLComponents(url: url, resolvingAgainstBaseURL: false),
              candidate.host?.lowercased() == service.host?.lowercased(), candidate.port == service.port,
              candidate.percentEncodedQuery == service.percentEncodedQuery else { return false }

        switch candidate.scheme {
        case "ws", "wss":
            return candidate.scheme == service.scheme && candidate.path == service.path
        case "http", "https":
            let scheme = candidate.scheme == "http" ? "ws" : "wss"
            let wsPath = candidate.path.hasSuffix("/") ? candidate.path + "ws" : candidate.path + "/ws"
            return scheme == service.scheme && wsPath == service.path
        default:
            return false
        }
    }

    private func applyProbe(_ ready: Bool, endpoint url: URL) -> Bool {
        guard !Task.isCancelled, endpoint == url, !stopped else { return false }
        setConnected(ready)
        return true
    }

    private func handleResponse(_ message: [String: Any]) {
        guard !stopped, hotWork == nil, let hotRequest, Self.integer(message["id"]) == hotRequest.id else { return }
        if message["error"] != nil {
            completeHot(.failure(SessionIssue(localized: "Flutter rejected the request")))
        } else if let result = message["result"] as? [String: Any], let code = Self.integer(result["code"]) {
            if code != 0 {
                completeHot(.failure(SessionIssue(localized: "Flutter returned error code \(String(code))")))
            } else if hotRequest.operation == .restart {
                confirmRestart(id: hotRequest.id)
            } else {
                completeHot(.success(()))
            }
        } else {
            completeHot(.failure(SessionIssue(localized: "Flutter did not confirm that the operation completed")))
        }
    }

    private func confirmRestart(id: Int) {
        let unconfirmed = SessionIssue(localized: "Could not verify that the Flutter app restarted")
        guard let baseline = restartBaseline else {
            completeHot(.failure(unconfirmed))
            return
        }
        hotTimeout?.cancel()
        hotTimeout = nil
        hotWork = Task { [weak self, timing] in
            let probe = VMServiceProbe(url: baseline.endpoint)
            defer { probe.close() }
            // The machine response can precede publication of the new UI isolate.
            for attempt in 0..<3 {
                if attempt > 0 {
                    do { try await timing.sleep(.milliseconds(250)) }
                    catch { return }
                }
                guard !Task.isCancelled, self?.hotRequest?.id == id else { return }
                guard self?.endpoint == baseline.endpoint else { break }
                let current = await probe.viewIsolates()
                guard !Task.isCancelled, self?.hotRequest?.id == id else { return }
                guard self?.endpoint == baseline.endpoint else { break }
                if let current, baseline.isolates.allSatisfy({ view, isolate in
                    current[view].map { $0 != isolate } == true
                }) {
                    self?.completeHot(.success(()))
                    return
                }
            }
            self?.completeHot(.failure(unconfirmed))
        }
    }

    private static func integer(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        return value as? Int
    }

    private func matches(_ params: [String: Any]) -> Bool {
        guard let appID else { return false }
        return params["appId"] as? String == appID
    }

    static func localEndpoint(_ address: String, schemes: Set<String>) -> URL? {
        guard let components = URLComponents(string: address), let scheme = components.scheme,
              schemes.contains(scheme), let host = components.host?.lowercased(),
              ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host),
              let port = components.port, (1...65535).contains(port),
              components.user == nil, components.password == nil, components.fragment == nil,
              !components.percentEncodedPath.localizedCaseInsensitiveContains("%2f"),
              !components.path.contains("\\") else { return nil }
        return components.url
    }
}

@MainActor
private final class VMServiceProbe {
    private enum ToolEventSubscriptionError: Error {
        case rejected
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 3
        config.httpShouldSetCookies = false
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        return URLSession(configuration: config, delegate: VMRedirectGuard(), delegateQueue: nil)
    }()

    private let url: URL
    private var socket: URLSessionWebSocketTask?
    private var nextID = 0

    init(url: URL) {
        self.url = url
    }

    func close() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
    }

    private func connection() -> URLSessionWebSocketTask {
        if let socket { return socket }
        let socket = Self.session.webSocketTask(with: url)
        socket.maximumMessageSize = 64 * 1024
        self.socket = socket
        socket.resume()
        return socket
    }

    func verify() async -> Bool {
        await request("getVersion") { result -> Bool? in
            guard result["type"] as? String == "Version", let major = result["major"] as? Int,
                  major > 0, result["minor"] is Int else { return nil }
            return true
        } ?? false
    }

    func viewIsolates() async -> [String: String]? {
        await request("_flutter.listViews") { result in
            guard result["type"] as? String == "FlutterViewList",
                  let views = result["views"] as? [[String: Any]] else { return nil }
            var isolates: [String: String] = [:]
            for view in views {
                guard let viewID = view["id"] as? String, !viewID.isEmpty,
                      let isolate = view["isolate"] as? [String: Any],
                      let isolateID = isolate["id"] as? String, !isolateID.isEmpty else { continue }
                isolates[viewID] = isolateID
            }
            return isolates
        }
    }

    private func request<Value: Sendable>(_ method: String,
                                          decode: @escaping @Sendable ([String: Any]) -> Value?) async -> Value? {
        guard !Task.isCancelled else { return nil }
        let socket = connection()
        nextID += 1
        let id = "runlet-vm-\(nextID)"
        let value = await withTaskCancellationHandler {
            await withTaskGroup(of: Value?.self) { group in
                group.addTask {
                    do {
                        try await socket.send(.string(#"{"jsonrpc":"2.0","id":"\#(id)","method":"\#(method)","params":{}}"#))
                        let message = try await socket.receive()
                        guard case .string(let response) = message,
                              let envelope = try? JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any],
                              envelope["jsonrpc"] as? String == "2.0",
                              envelope["id"] as? String == id, envelope["error"] == nil,
                              let result = envelope["result"] as? [String: Any] else { return nil }
                        return decode(result)
                    } catch { return nil }
                }
                group.addTask {
                    try? await Task.sleep(for: .seconds(3))
                    return nil
                }
                let result = await group.next() ?? nil
                if result == nil { socket.cancel(with: .normalClosure, reason: nil) }
                group.cancelAll()
                return result
            }
        } onCancel: {
            socket.cancel(with: .normalClosure, reason: nil)
        }
        if value == nil { self.socket = nil }
        return value
    }

    static func listenForToolEvents(at url: URL, receive: ([String: Any]) -> Void) async throws {
        let connection = VMServiceProbe(url: url)
        let socket = connection.connection()
        defer { connection.close() }
        try await withTaskCancellationHandler {
            let id = "runlet-inspector"
            try await socket.send(.string(#"{"jsonrpc":"2.0","id":"\#(id)","method":"streamListen","params":{"streamId":"ToolEvent"}}"#))
            var subscribed = false
            while !Task.isCancelled {
                guard case .string(let text) = try await socket.receive(),
                      let message = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else { continue }
                if message["id"] as? String == id {
                    guard let result = message["result"] as? [String: Any], result["type"] as? String == "Success" else {
                        throw ToolEventSubscriptionError.rejected
                    }
                    subscribed = true
                } else if subscribed {
                    receive(message)
                }
            }
        } onCancel: {
            socket.cancel(with: .normalClosure, reason: nil)
        }
    }
}

private final class VMRedirectGuard: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

enum SessionLogTone {
    case launch, diagnostic

    static func flutterStatus(_ text: String) -> Self? {
        let line = text.last?.isNewline == true ? text.dropLast() : text[...]
        return line.hasPrefix("Launching ") && line.hasSuffix(" in debug mode...") ? .launch : nil
    }
}

struct SessionLogSpan: Equatable {
    // UTF-16 offsets from the beginning of this log generation, before trimming.
    let range: Range<Int>
    let tone: SessionLogTone
}

@MainActor
final class SessionLineStream {
    private var stdout = SessionLineBuffer()
    private var stderr = SessionLineBuffer()
    private let output: (String, Bool, UInt64) -> Void

    init(output: @escaping (String, Bool, UInt64) -> Void) {
        self.output = output
    }

    func receive(_ data: Data, isError: Bool, generation: UInt64) {
        let lines = isError ? stderr.append(data, generation: generation) : stdout.append(data, generation: generation)
        for line in lines { output(line.text, isError, line.generation) }
    }

    func finish() {
        if let line = stdout.finish() { output(line.text, false, line.generation) }
        if let line = stderr.finish() { output(line.text, true, line.generation) }
    }
}

private struct SessionLineBuffer {
    typealias Line = (text: String, generation: UInt64)

    private var bytes = Data()
    private var generation: UInt64?
    private var droppingLine = false
    private let limit = 64 * 1024

    mutating func append(_ chunk: Data, generation: UInt64) -> [Line] {
        var lines: [Line] = []
        var start = chunk.startIndex
        while start < chunk.endIndex {
            let newline = chunk[start...].firstIndex(of: 0x0a)
            let end = newline.map { chunk.index(after: $0) } ?? chunk.endIndex
            let piece = chunk[start..<end]
            if self.generation == nil { self.generation = generation }
            if !droppingLine {
                if bytes.count + piece.count <= limit {
                    bytes.append(piece)
                } else {
                    bytes.removeAll()
                    droppingLine = true
                }
            }
            if newline != nil {
                if let line = finish() { lines.append(line) }
            }
            start = end
        }
        return lines
    }

    mutating func finish() -> Line? {
        defer {
            bytes.removeAll(keepingCapacity: true)
            droppingLine = false
            generation = nil
        }
        guard let generation else { return nil }
        if droppingLine { return ("[调试输出单行超过上限]\n", generation) }
        return (String(decoding: bytes, as: UTF8.self), generation)
    }
}

enum FlutterLogRedaction {
    private static let plain = #"(?:https?|wss?)://(?:localhost|127\.0\.0\.1|\[::1\]):\d+/"#
    private static let encoded = #"(?:https?|wss?)%3a%2f%2f(?:localhost|127\.0\.0\.1|%5b%3a%3a1%5d)%3a\d+%2f"#
    private static let token = #"[a-z0-9_-]+(?:=|%3d|%253d){0,2}"#
    private static let patterns: [NSRegularExpression] = [
        // An authenticated VM or DevTools route, including unpadded base64url tokens.
        #"(?i)(\#(plain))\#(token)(?=/(?:ws|devtools)(?=[/\s?&#"'<>]|$))"#,
        #"(?i)(\#(encoded))\#(token)(?=%2f(?:ws|devtools)(?=%2f|%3f|[&\s"'<>]|$))"#,
        // HTTP VM endpoints can end at the token before the WebSocket suffix is added.
        #"(?i)(\b(?:Dart )?VM Service[^\r\n]*?\#(plain))\#(token)(?=/[\s"'<>]|/$|[\s"'<>]|$)"#,
        #"(?i)([?&]uri=\#(plain))\#(token)(?=/[&\s"'<>]|/$|[&\s"'<>]|$)"#,
        #"(?i)([?&]uri=\#(encoded))\#(token)(?=%2f(?:[&\s"'<>]|$)|[&\s"'<>]|$)"#,
        #"(?i)(\#(plain))[a-z0-9_-]+(?:=|%3d){1,2}(?=[/\s?&#"'<>]|$)"#,
        #"(?i)(\#(encoded))[a-z0-9_-]+(?:%3d|%253d){1,2}(?=%2f|%3f|[&\s"'<>]|$)"#,
    ].map { try! NSRegularExpression(pattern: $0) }

    static func clean(_ text: String) -> String {
        patterns.reduce(text) { value, pattern in
            pattern.stringByReplacingMatches(in: value, range: NSRange(value.startIndex..., in: value),
                                              withTemplate: "$1[已遮罩]")
        }
    }
}
