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
    private var appID: String?
    private var endpoint: URL?
    private var reportedDevTools: URL?
    private var probe: Task<Void, Never>?
    private var hotTimeout: Task<Void, Never>?
    private var hotRequest: (id: Int, complete: HotCompletion)?
    private var nextID = 2  // app.stop uses request 1.
    private(set) var supportsRestart = false
    private(set) var hasVerifiedVM = false
    private var connected = false
    private var stopped = false

    init(deviceID: String, verifyVM: Verification?, timing: FlutterDebugTiming, sdk: FlutterSDK?,
         connectionChanged: @escaping (Bool) -> Void,
         browserAvailabilityChanged: @escaping (Bool) -> Void) {
        self.deviceID = deviceID
        self.verifyVM = verifyVM
        self.timing = timing
        testedInspectorRoute = sdk?.flutterVersion == "3.47.4" && sdk?.devToolsVersion == "2.60.0"
        self.connectionChanged = connectionChanged
        self.browserAvailabilityChanged = browserAvailabilityChanged
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

    func hotOperation(_ operation: FlutterHotOperation, send: (Data) -> Bool, complete: @escaping HotCompletion) {
        guard connected, supportsRestart, !stopped, hotRequest == nil, let appID else {
            complete(.failure(SessionIssue(localized: "The current Flutter debug connection is unavailable")))
            return
        }
        let id = nextID
        nextID += 1
        guard let request = Self.request(id: id, method: "app.restart", appID: appID,
                                         fullRestart: operation == .restart), send(request) else {
            complete(.failure(SessionIssue(localized: "Could not send the command to the current Flutter process")))
            return
        }
        hotRequest = (id, complete)
        hotTimeout = Task { [weak self, timing] in
            do { try await timing.sleep(.seconds(30)) }
            catch { return }
            guard let self, !Task.isCancelled, self.hotRequest?.id == id else { return }
            self.completeHot(.failure(SessionIssue(localized: "Timed out waiting for Flutter to respond")))
        }
    }

    private func completeHot(_ result: Result<Void, SessionIssue>) {
        let request = hotRequest
        hotRequest = nil
        hotTimeout?.cancel()
        hotTimeout = nil
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
        hotRequest = nil
        hotTimeout?.cancel()
        hotTimeout = nil
        endpoint = nil
        reportedDevTools = nil
        setConnected(false)
    }

    private func setConnected(_ value: Bool) {
        guard value != connected else { return }
        connected = value
        if value { hasVerifiedVM = true }
        connectionChanged(value)
        browserAvailabilityChanged(browserDestination(.devTools) != nil)
    }

    func receive(_ line: String, isError: Bool, output: (String) -> Void) {
        if !isError, line.hasPrefix("["),
           let messages = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [[String: Any]],
           !messages.isEmpty,
           messages.allSatisfy({ $0["event"] is String || $0["id"] is Int }) {
            for message in messages { handle(message, output: output) }
            return
        }
        output(line)
    }

    private func handle(_ message: [String: Any], output: (String) -> Void) {
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
            output(log + "\n")
        case "app.stop":
            if matches(params) { invalidateConnection() }
        case "daemon.logMessage", "daemon.log":
            if let log = params["message"] as? String ?? params["log"] as? String {
                output(log + "\n")
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
        guard !stopped, let hotRequest, Self.integer(message["id"]) == hotRequest.id else { return }
        if message["error"] != nil {
            completeHot(.failure(SessionIssue(localized: "Flutter rejected the request")))
        } else if let result = message["result"] as? [String: Any], let code = Self.integer(result["code"]) {
            completeHot(code == 0 ? .success(()) : .failure(SessionIssue(localized: "Flutter returned error code \(String(code))")))
        } else {
            completeHot(.failure(SessionIssue(localized: "Flutter did not confirm that the operation completed")))
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
        let socket = connection()
        nextID += 1
        let id = "runlet-vm-version-\(nextID)"
        let ready = await withTaskCancellationHandler {
            await withTaskGroup(of: Bool.self) { group in
                group.addTask {
                    do {
                        try await socket.send(.string(#"{"jsonrpc":"2.0","id":"\#(id)","method":"getVersion","params":{}}"#))
                        let message = try await socket.receive()
                        guard case .string(let response) = message,
                              let envelope = try? JSONSerialization.jsonObject(with: Data(response.utf8)) as? [String: Any],
                              envelope["jsonrpc"] as? String == "2.0",
                              envelope["id"] as? String == id, envelope["error"] == nil,
                              let result = envelope["result"] as? [String: Any], result["type"] as? String == "Version",
                              let major = result["major"] as? Int, major > 0, result["minor"] is Int else { return false }
                        return true
                    } catch { return false }
                }
                group.addTask {
                    try? await Task.sleep(for: .seconds(3))
                    return false
                }
                let result = await group.next() ?? false
                if !result { socket.cancel(with: .normalClosure, reason: nil) }
                group.cancelAll()
                return result
            }
        } onCancel: {
            socket.cancel(with: .normalClosure, reason: nil)
        }
        if !ready { self.socket = nil }
        return ready
    }
}

private final class VMRedirectGuard: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
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
