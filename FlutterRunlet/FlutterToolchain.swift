import Darwin
import Foundation

struct FlutterSDK: Equatable, Sendable {
    enum Source: String, Sendable {
        case projectFVM = "项目 FVM"
        case manual = "手动指定"
        case system = "系统 PATH"
    }

    let executable: URL
    let flutterVersion: String
    let dartVersion: String
    let devToolsVersion: String?
    let source: Source
    let directory: URL

    init(executable: URL, flutterVersion: String, dartVersion: String,
         devToolsVersion: String? = nil, source: Source = .system, directory: URL? = nil) {
        self.executable = executable
        self.flutterVersion = flutterVersion
        self.dartVersion = dartVersion
        self.devToolsVersion = devToolsVersion
        self.source = source
        self.directory = directory ?? executable.deletingLastPathComponent().deletingLastPathComponent()
    }
}

struct FlutterDoctorResult: Sendable {
    enum Tool: String, CaseIterable, Sendable {
        case flutter = "Flutter"
        case xcode = "Xcode"
        case android = "Android toolchain"

        var title: LocalizedStringResource {
            switch self {
            case .flutter: "Flutter"
            case .xcode: "Xcode"
            case .android: "Android Toolchain"
            }
        }
    }

    enum Status: Sendable {
        case passed, warning, failed, unknown

        var title: LocalizedStringResource {
            switch self {
            case .passed: "Passed"
            case .warning: "Warning"
            case .failed: "Failed"
            case .unknown: "Unknown"
            }
        }
    }

    enum Failure: Equatable, Sendable {
        case launch, output, timeout, truncated, cancelled, exit(Int32), signal(Int32)

        var reason: LocalizedStringResource {
            switch self {
            case .launch: "Flutter could not be started"
            case .output: "The diagnostic output could not be read"
            case .timeout: "The environment check timed out"
            case .truncated: "The environment check exceeded the output limit"
            case .cancelled: "The environment check was cancelled"
            case .exit(let code): "Flutter exited with code \(code)"
            case .signal(let signal): "Flutter terminated with signal \(signal)"
            }
        }
    }

    let stdout: String
    let stderr: String
    let summary: [Tool: Status]
    let failure: Failure?

    init(stdout: String = "", stderr: String = "", failure: Failure? = nil) {
        self.stdout = stdout
        self.stderr = stderr
        self.failure = failure
        let headings = [stdout, stderr].flatMap(Self.headings)
        summary = Dictionary(uniqueKeysWithValues: Tool.allCases.map { tool in
            let status = headings.first { $0.0 == tool }?.1 ?? .unknown
            return (tool, status)
        })
    }

    private static func headings(_ output: String) -> [(Tool, Status)] {
        let plain = output.replacingOccurrences(of: #"\x1B\[[0-?]*[ -/]*[@-~]"#, with: "", options: .regularExpression)
        let pattern = /^\s*(?:\[\s*\+?\d+(?:\.\d+)?\s*(?:ms|s)\]\s*)*\[([^\]]+)\]\s*(Flutter|Xcode|Android toolchain)(?:\s*(?:\(|-|–)|\s*$)/
        return plain.split(whereSeparator: \.isNewline).compactMap { line in
            guard let match = line.prefixMatch(of: pattern), let tool = Tool(rawValue: String(match.output.2)) else {
                return nil
            }
            let status: Status = switch match.output.1 {
            case "✓": .passed
            case "!": .warning
            case "✗", "✘": .failed
            default: .unknown
            }
            return (tool, status)
        }
    }
}

struct FlutterSDKOptions: Sendable {
    var preferProjectFVM = true
    var manualPath: String?
}

struct FlutterDevice: Decodable, Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let platform: String
    let isSimulator: Bool
    let isSupported: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, isSupported
        case platform = "targetPlatform"
        case isSimulator = "emulator"
    }

    init(id: String, name: String, platform: String, isSimulator: Bool, isSupported: Bool? = nil) {
        self.id = id
        self.name = name
        self.platform = platform
        self.isSimulator = isSimulator
        self.isSupported = isSupported
    }

    var isMacOSDesktop: Bool {
        id == "macos" && (platform == "darwin" || platform.hasPrefix("darwin-"))
    }

    var isUsableDebugDevice: Bool {
        (platform == "ios" || platform == "android" || platform.hasPrefix("android-") || isMacOSDesktop) &&
            isSupported != false && !name.isEmpty && !id.isEmpty && !id.hasPrefix("-")
    }
}

struct FlutterSimulator: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
}

struct AndroidEmulator: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let deviceID: String?
}

enum FlutterDeviceAvailability: Equatable, Sendable {
    case available
    case missing
    case disconnected
    case unknown
}

struct FlutterToolchain {
    typealias SDKResolution = @MainActor (URL?, [String: String], FlutterSDKOptions) async throws -> FlutterSDK
    typealias DeviceDiscovery = @MainActor (FlutterSDK, [String: String]) async throws -> [FlutterDevice]
    typealias SimulatorDiscovery = @MainActor ([String: String]) async throws -> [FlutterSimulator]
    typealias SimulatorBoot = @MainActor (String, [String: String]) async throws -> Void

    let resolve: SDKResolution
    let discover: DeviceDiscovery
    let validateManual: @MainActor (URL, URL?, [String: String]) async throws -> FlutterSDK
    let simulators: SimulatorDiscovery
    let bootSimulator: SimulatorBoot
    var showSimulator: SimulatorBoot = { _, _ in }
    var androidEmulators: @MainActor (FlutterSDK, [String: String]) async throws -> [AndroidEmulator] = { _, _ in [] }
    var bootAndroidEmulator: @MainActor (String, FlutterSDK, [String: String]) async throws -> Void = { _, _, _ in
        throw SessionIssue(localized: "Android emulator launch is unavailable")
    }

    init(resolve: @escaping SDKResolution, discover: @escaping DeviceDiscovery,
         simulators: @escaping SimulatorDiscovery = { _ in [] },
         bootSimulator: @escaping SimulatorBoot = { _, _ in throw SessionIssue(localized: "iOS simulator launch is unavailable") }) {
        self.resolve = resolve
        self.discover = discover
        self.simulators = simulators
        self.bootSimulator = bootSimulator
        validateManual = { directory, project, environment in
            try await Self.verifySDK(in: directory, source: .manual, environment: Self.probeEnvironment(environment, project))
        }
    }

    init(resolve: @escaping @MainActor (URL, [String: String]) async throws -> FlutterSDK,
         discover: @escaping DeviceDiscovery, simulators: @escaping SimulatorDiscovery = { _ in [] },
         bootSimulator: @escaping SimulatorBoot = { _, _ in throw SessionIssue(localized: "iOS simulator launch is unavailable") }) {
        self.init(resolve: { project, environment, _ in
            guard let project else { throw SessionIssue(localized: "Open a Flutter project first") }
            return try await resolve(project, environment)
        }, discover: discover, simulators: simulators, bootSimulator: bootSimulator)
    }

    static var production: Self {
        var toolchain = Self(resolve: { project, environment, options in
            try await resolveSDK(project: project, environment: environment, options: options)
        }, discover: { sdk, environment in
            let data = try await query(sdk.executable, ["devices", "--machine", "--device-timeout=5"],
                                       environment: environment)
            guard let devices = try? JSONDecoder().decode([FlutterDevice].self, from: data) else {
                throw SessionIssue(localized: "Could not read the Flutter device list")
            }
            var ids = Set<String>()
            return devices.filter { $0.isUsableDebugDevice && ids.insert($0.id).inserted }
        }, simulators: { environment in
            let data = try await query(xcrun, ["simctl", "list", "devices", "available", "--json"],
                                       environment: environment)
            guard let list = try? JSONDecoder().decode(SimulatorList.self, from: data) else {
                throw SessionIssue(localized: "Could not read the system simulator list")
            }
            return list.devices
                .filter { $0.key.hasPrefix("com.apple.CoreSimulator.SimRuntime.iOS-") }
                .flatMap(\.value)
                .filter { $0.state == "Shutdown" && $0.isAvailable && UUID(uuidString: $0.udid) != nil }
                .map { FlutterSimulator(id: $0.udid, name: $0.name) }
                .sorted { ($0.name, $0.id) < ($1.name, $1.id) }
        }, bootSimulator: { id, environment in
            guard UUID(uuidString: id) != nil else { throw SessionIssue(localized: "The simulator identifier is invalid") }
            do {
                _ = try await query(xcrun, ["simctl", "boot", id], environment: environment)
            } catch {
                throw SessionIssue(localized: "The system could not start the selected simulator")
            }
        })
        toolchain.showSimulator = showIOSSimulator
        toolchain.androidEmulators = discoverAndroidEmulators
        toolchain.bootAndroidEmulator = { id, sdk, environment in
            guard validAVDIdentifier(id),
                  try await discoverAndroidEmulators(sdk, environment).contains(where: { $0.id == id }) else {
                throw SessionIssue(localized: "The simulator identifier is invalid")
            }
            _ = try await query(sdk.executable, ["emulators", "--launch", id], environment: environment)
        }
        return toolchain
    }

    @MainActor
    private static func showIOSSimulator(_ id: String, _ environment: [String: String]) async throws {
        guard let uuid = UUID(uuidString: id) else {
            throw SessionIssue(localized: "The simulator identifier is invalid")
        }
        let data = try await query(URL(fileURLWithPath: "/usr/bin/xcode-select"), ["--print-path"],
                                   environment: environment)
        let path = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        guard path.hasPrefix("/") else {
            throw SessionIssue(localized: "Could not open the iOS simulator window")
        }
        let developer = URL(fileURLWithPath: path, isDirectory: true)
        let deviceHub = developer.deletingLastPathComponent().appending(path: "Applications/DeviceHub.app")
        let arguments: [String]
        if FileManager.default.fileExists(atPath: deviceHub.path) {
            arguments = ["-a", deviceHub.path, "devices://device/open?id=\(uuid.uuidString)"]
        } else {
            let simulator = developer.appending(path: "Applications/Simulator.app")
            arguments = ["-a", simulator.path, "--args", "-CurrentDeviceUDID", uuid.uuidString]
        }
        _ = try await query(URL(fileURLWithPath: "/usr/bin/open"), arguments, environment: environment)
    }

    @MainActor
    private static func discoverAndroidEmulators(_ sdk: FlutterSDK, _ environment: [String: String]) async throws -> [AndroidEmulator] {
        let data = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(with: Result {
                    try readQuery(sdk.executable, ["daemon"], environment: environment,
                                  daemonMethods: ["emulator.getEmulators", "device.getDevices"])
                })
            }
        }
        return try decodeAndroidEmulators(data)
    }

    static func validAVDIdentifier(_ id: String) -> Bool {
        !id.isEmpty && !id.hasPrefix("-") && id.range(of: #"^[A-Za-z0-9_.-]+$"#, options: .regularExpression) != nil
    }

    static func decodeAndroidEmulators(_ data: Data) throws -> [AndroidEmulator] {
        struct Snapshot: Decodable {
            struct Emulator: Decodable { let id: String; let name: String; let platformType: String }
            struct Device: Decodable {
                let id: String; let emulatorId: String?; let platform: String
                let emulator: Bool; let isConnected: Bool
            }
            let emulators: [Emulator]
            let devices: [Device]
            enum CodingKeys: String, CodingKey {
                case emulators = "emulator.getEmulators"
                case devices = "device.getDevices"
            }
        }
        let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
        var ids = Set<String>()
        return snapshot.emulators.compactMap { emulator in
            guard emulator.platformType == "android", validAVDIdentifier(emulator.id),
                  !emulator.name.isEmpty, ids.insert(emulator.id).inserted else { return nil }
            let device = snapshot.devices.first {
                $0.emulator && $0.isConnected && $0.platform.hasPrefix("android") && $0.emulatorId == emulator.id
            }
            return AndroidEmulator(id: emulator.id, name: emulator.name, deviceID: device?.id)
        }.sorted { ($0.name, $0.id) < ($1.name, $1.id) }
    }

    @MainActor
    func availability(of device: FlutterDevice, using sdk: FlutterSDK, environment: [String: String],
                      project: URL? = nil) async -> FlutterDeviceAvailability {
        let environment = Self.probeEnvironment(environment, project)
        let devices = try? await discover(sdk, environment)
        if devices?.contains(where: { $0.id == device.id }) == true { return .available }
        // The simulator list contains only available iOS simulators explicitly in Shutdown.
        if device.platform == "ios", device.isSimulator,
           let shutdown = try? await simulators(environment),
           shutdown.contains(where: { $0.id == device.id }) {
            return .disconnected
        }
        return devices == nil ? .unknown : .missing
    }

    private static let xcrun = URL(fileURLWithPath: "/usr/bin/xcrun")

    private struct SimulatorList: Decodable {
        struct Entry: Decodable {
            let udid: String
            let name: String
            let state: String
            let isAvailable: Bool
        }

        let devices: [String: [Entry]]
    }

    private static func resolveSDK(project: URL?, environment: [String: String],
                                   options: FlutterSDKOptions) async throws -> FlutterSDK {
        let environment = probeEnvironment(environment, project)
        if options.preferProjectFVM, let project {
            do {
                if let directory = try projectFVMSDK(project, environment: environment) {
                    return try await verifySDK(in: directory, source: .projectFVM, environment: environment)
                }
            } catch {
                throw SessionIssue(localized: "The FVM SDK required by the project is unavailable: \(LocalizedStringResource.appIssue(error)). Fix the SDK specified by the project.")
            }
        }
        if let manual = options.manualPath {
            do {
                guard manual.hasPrefix("/") else { throw SessionIssue(localized: "The path is not an absolute directory") }
                return try await verifySDK(in: URL(fileURLWithPath: manual, isDirectory: true),
                                           source: .manual, environment: environment)
            } catch {
                throw SessionIssue(localized: "The current Flutter SDK is unavailable: manual path \(manual) — \(LocalizedStringResource.appIssue(error)). Check the SDK path.")
            }
        }

        var sdkEnvironment = environment
        var executable = flutterOnPATH(environment, project: project)
        if executable == nil, let path = await loginShellPATH(environment, project: project) {
            sdkEnvironment["PATH"] = path
            sdkEnvironment = probeEnvironment(sdkEnvironment, project)
            executable = flutterOnPATH(sdkEnvironment, project: project)
        }
        guard let executable else {
            throw SessionIssue(localized: "The current Flutter SDK is unavailable: Flutter was not found on PATH. Check the SDK path.")
        }
        do {
            return try await resolvePATHSDK(executable, project: project, environment: sdkEnvironment)
        } catch {
            throw SessionIssue(localized: "The current Flutter SDK is unavailable: \(LocalizedStringResource.appIssue(error)). Check the SDK path.")
        }
    }

    private static func flutterOnPATH(_ environment: [String: String], project: URL?) -> URL? {
        (environment["PATH"] ?? "").split(separator: ":").lazy
            .map { URL(fileURLWithPath: String($0), isDirectory: true).appending(path: "flutter").resolvingSymlinksInPath() }
            .first { !isInside($0, project) && FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    private static func loginShellPATH(_ environment: [String: String], project: URL?) async -> String? {
        let accountShell = getpwuid(getuid())?.pointee.pw_shell.map { String(cString: $0) }
        let path = environment["SHELL"] ?? accountShell ?? "/bin/zsh"
        guard path.hasPrefix("/") else { return nil }
        let shell = URL(fileURLWithPath: path).resolvingSymlinksInPath()
        guard !isInside(shell, project), FileManager.default.isExecutableFile(atPath: shell.path) else { return nil }

        // Frame PATH separately from messages printed by shell startup files.
        let printPATH = #"/usr/bin/printf '\000'; /usr/bin/printenv PATH; /usr/bin/printf '\000'"#
        guard let output = try? await query(shell, ["-l", "-i", "-c", printPATH],
                                            environment: environment, timeout: .seconds(5)) else { return nil }
        let fields = output.split(separator: 0, maxSplits: 2, omittingEmptySubsequences: false)
        guard fields.count == 3, fields[1].last == 10 else { return nil }
        return String(bytes: fields[1].dropLast(), encoding: .utf8)
    }

    private static func resolvePATHSDK(_ executable: URL, project: URL?,
                                       environment: [String: String]) async throws -> FlutterSDK {
        let version = try await probeSDKVersion(executable, environment: environment)
        guard let root = version.flutterRoot else { return version.sdk(executable, source: .system) }
        guard root.hasPrefix("/"), !root.utf8.contains(0) else {
            throw SessionIssue(localized: "Flutter reported an invalid SDK directory")
        }
        let directory = URL(fileURLWithPath: root, isDirectory: true).resolvingSymlinksInPath()
        let sdkExecutable = try verifiedSDKExecutable(in: directory)
        guard !isInside(directory, project), !isInside(sdkExecutable, project) else {
            throw SessionIssue(localized: "Flutter reported an SDK directory inside the project")
        }
        let sdkVersion = sdkExecutable.path == executable.path
            ? version : try await probeSDKVersion(sdkExecutable, environment: environment)
        return sdkVersion.sdk(sdkExecutable, source: .system, directory: directory)
    }

    private static func projectFVMSDK(_ project: URL, environment: [String: String]) throws -> URL? {
        let files = FileManager.default
        let modern = project.appending(path: ".fvmrc")
        let legacy = project.appending(path: ".fvm/fvm_config.json")
        let link = project.appending(path: ".fvm/flutter_sdk")
        let destination = try? files.destinationOfSymbolicLink(atPath: link.path)
        guard entryExists(modern) || entryExists(legacy) || entryExists(link) else { return nil }

        var version: String?
        if entryExists(modern) {
            version = try readPin(modern, key: "flutter", project: project)
        } else if entryExists(legacy) {
            version = try readPin(legacy, key: "flutterSdkVersion", project: project)
        }
        guard let destination else { throw SessionIssue(localized: "The .fvm/flutter_sdk cache link is missing") }
        let target = URL(fileURLWithPath: destination, isDirectory: true, relativeTo: link.deletingLastPathComponent())
            .absoluteURL.standardizedFileURL.resolvingSymlinksInPath()
        let userHome = environment["HOME"].flatMap { $0.hasPrefix("/") ? URL(fileURLWithPath: $0) : nil }
            ?? FileManager.default.homeDirectoryForCurrentUser
        var roots = [userHome.appending(path: "fvm/versions"), userHome.appending(path: ".fvm/versions")]
        if let path = environment["FVM_CACHE_PATH"], path.hasPrefix("/") {
            let configured = URL(fileURLWithPath: path, isDirectory: true)
            roots += [configured, configured.appending(path: "versions")]
        }
        guard !isInside(target, project), roots.contains(where: {
            $0.resolvingSymlinksInPath().path == target.deletingLastPathComponent().path
        }) else {
            throw SessionIssue(localized: ".fvm/flutter_sdk does not point to an SDK in the user’s FVM cache")
        }
        if let version, target.lastPathComponent != version {
            throw SessionIssue(localized: ".fvm/flutter_sdk does not match the version pinned by the project")
        }
        return target
    }

    private static func entryExists(_ url: URL) -> Bool {
        var metadata = stat()
        return lstat(url.path, &metadata) == 0
    }

    private static func readPin(_ url: URL, key: String, project: URL) throws -> String {
        let canonical = url.resolvingSymlinksInPath()
        var metadata = stat()
        guard isInside(canonical, project), lstat(url.path, &metadata) == 0,
              metadata.st_mode & S_IFMT == S_IFREG, metadata.st_size <= 64 * 1024,
              let data = try? Data(contentsOf: canonical),
              let fields = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pin = fields[key] as? String,
              !pin.isEmpty else {
            throw SessionIssue(localized: "Could not read the pinned project version from \(url.lastPathComponent)")
        }
        return pin
    }

    static func probeEnvironment(_ environment: [String: String], _ project: URL?) -> [String: String] {
        var trusted = environment
        trusted["PATH"] = (environment["PATH"] ?? "").split(separator: ":")
            .filter { path in
                path.hasPrefix("/") && !isInside(URL(fileURLWithPath: String(path)).resolvingSymlinksInPath(), project)
            }
            .joined(separator: ":")
        return trusted
    }

    private static func isInside(_ url: URL, _ directory: URL?) -> Bool {
        guard let directory else { return false }
        let path = directory.resolvingSymlinksInPath().path
        return url.path == path || url.path.hasPrefix(path == "/" ? path : path + "/")
    }

    private static func verifySDK(in directory: URL, source: FlutterSDK.Source,
                                  environment: [String: String]) async throws -> FlutterSDK {
        let directory = directory.resolvingSymlinksInPath()
        let executable = try verifiedSDKExecutable(in: directory)
        let version = try await probeSDKVersion(executable, environment: environment)
        return version.sdk(executable, source: source, directory: directory)
    }

    private static func verifiedSDKExecutable(in directory: URL) throws -> URL {
        let executable = directory.appending(path: "bin/flutter").resolvingSymlinksInPath()
        guard isInside(executable, directory), FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw SessionIssue(localized: "bin/flutter is not executable or points outside the SDK directory")
        }
        return executable
    }

    private static func probeSDKVersion(_ executable: URL, environment: [String: String]) async throws -> Version {
        let data = try await query(executable, ["--version", "--machine"], environment: environment)
        let decoder = JSONDecoder()
        var version = try? decoder.decode(Version.self, from: data)
        // Flutter may print startup or first-run notices around the machine-readable version object.
        if version == nil,
           let json = String(decoding: data, as: UTF8.self).firstMatch(of: /(?m)^\{(?:[^\n]*\}|(?s:.*?)^\})$/) {
            version = try? decoder.decode(Version.self, from: Data(json.output.utf8))
        }
        guard let version, !version.flutterVersion.isEmpty, !version.dartSdkVersion.isEmpty else {
            throw SessionIssue(localized: "Could not verify the Flutter/Dart version")
        }
        return version
    }

    static func command(sdk: FlutterSDK, device: FlutterDevice, launch: PreparedLaunch) throws -> SessionCommand {
        guard sdk.executable.isFileURL, sdk.executable.path.hasPrefix("/"),
              FileManager.default.isExecutableFile(atPath: sdk.executable.path) else {
            throw SessionIssue(localized: "The verified Flutter SDK path is not executable. Refresh and try again")
        }
        guard launch.mode == "debug" else { throw SessionIssue(localized: "Only Debug mode is supported") }
        if let requested = launch.deviceID, requested != device.id {
            throw SessionIssue(localized: "This configuration requires \(requested). Select that device from the device menu.")
        }
        guard !device.id.isEmpty, !device.id.hasPrefix("-") else { throw SessionIssue(localized: "Could not verify the device identifier") }
        guard launch.applicationArguments.isEmpty else {
            throw SessionIssue(localized: "The current device cannot pass Dart application arguments from args. Move Flutter tool arguments to toolArgs.")
        }
        guard !launch.toolArguments.contains("--machine"), !launch.toolArguments.contains("--no-resident") else {
            throw SessionIssue(localized: "--machine or --no-resident in toolArgs conflicts with the managed Debug session")
        }
        return SessionCommand(
            executable: sdk.executable.path,
            arguments: ["run", "--machine", "--debug", "-d", device.id, "--target", launch.program] + launch.toolArguments,
            directory: launch.directory, environment: launch.environment
        )
    }

    private struct Version: Decodable {
        let flutterVersion: String
        let dartSdkVersion: String
        let devToolsVersion: String?
        let flutterRoot: String?

        func sdk(_ executable: URL, source: FlutterSDK.Source, directory: URL? = nil) -> FlutterSDK {
            FlutterSDK(executable: executable, flutterVersion: flutterVersion,
                       dartVersion: dartSdkVersion, devToolsVersion: devToolsVersion,
                       source: source, directory: directory)
        }
    }

    static func doctor(using sdk: FlutterSDK, environment: [String: String], project: URL?,
                       timeout: Duration = .seconds(25), outputLimit: Int = 1024 * 1024,
                       activity: UpdateActivityLease? = nil) async -> FlutterDoctorResult {
        let environment = probeEnvironment(environment, project)
        let operation = Task.detached(priority: .utility) {
            readDoctor(sdk.executable, environment: environment, timeout: timeout, outputLimit: outputLimit, activity: activity)
        }
        return await withTaskCancellationHandler {
            await operation.value
        } onCancel: {
            operation.cancel()
        }
    }

    private static func readDoctor(_ executable: URL, environment: [String: String],
                                   timeout: Duration, outputLimit: Int, activity: UpdateActivityLease?) -> FlutterDoctorResult {
        guard !Task.isCancelled else { return FlutterDoctorResult(failure: .cancelled) }
        guard executable.isFileURL, executable.path.hasPrefix("/") else { return FlutterDoctorResult(failure: .launch) }
        let directory = FileManager.default.temporaryDirectory.appending(path: "FlutterRunlet-doctor-\(UUID())")
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
                                                    attributes: [.posixPermissions: 0o700])
        } catch {
            return FlutterDoctorResult(failure: .launch)
        }
        defer { try? FileManager.default.removeItem(at: directory) }

        let stdout = DoctorStream()
        let stderr = DoctorStream()
        guard stdout.enableNonblockingReads(), stderr.enableNonblockingReads() else {
            return FlutterDoctorResult(failure: .output)
        }
        let start = SessionSpawn.spawn(
            executable.path, arguments: ["--no-version-check", "doctor", "-v"], environment: environment,
            flags: Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETPGROUP)
        ) { actions in
            let stdin = posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0)
            guard stdin == 0 else { return stdin }
            for (stream, fd) in [(stdout, STDOUT_FILENO), (stderr, STDERR_FILENO)] {
                let status = posix_spawn_file_actions_adddup2(&actions, stream.writer.fileDescriptor, fd)
                if status != 0 { return status }
            }
            if let activity {
                let inherited = posix_spawn_file_actions_addinherit_np(&actions, activity.descriptor)
                if inherited != 0 { return inherited }
            }
            if #available(macOS 26, *) {
                return posix_spawn_file_actions_addchdir(&actions, directory.path)
            }
            return posix_spawn_file_actions_addchdir_np(&actions, directory.path)
        }
        guard case .success(let pid) = start else { return FlutterDoctorResult(failure: .launch) }
        try? stdout.writer.close()
        try? stderr.writer.close()
        var reaped = false
        defer {
            if !reaped {
                // Retain the unreaped group leader until its group has been signalled.
                if kill(-pid, SIGTERM) == 0 {
                    Thread.sleep(forTimeInterval: 0.15)
                }
                _ = kill(-pid, SIGKILL)
                var status: Int32 = 0
                while waitpid(pid, &status, 0) == -1 && errno == EINTR {}
            }
        }

        func result(_ failure: FlutterDoctorResult.Failure?) -> FlutterDoctorResult {
            FlutterDoctorResult(stdout: String(decoding: stdout.data, as: UTF8.self),
                                stderr: String(decoding: stderr.data, as: UTF8.self), failure: failure)
        }
        let deadline = ContinuousClock.now + timeout
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            if Task.isCancelled { return result(.cancelled) }
            if .now >= deadline { return result(.timeout) }
            var received = false
            for stream in [stdout, stderr] where !stream.reachedEnd {
                let count = Darwin.read(stream.reader.fileDescriptor, &buffer, buffer.count)
                if count > 0 {
                    let remaining = outputLimit - stdout.data.count - stderr.data.count
                    stream.data.append(contentsOf: buffer.prefix(min(count, max(0, remaining))))
                    if count > remaining { return result(.truncated) }
                    received = true
                } else if count == 0 {
                    stream.reachedEnd = true
                } else if errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR {
                    return result(.output)
                }
            }

            if stdout.reachedEnd, stderr.reachedEnd {
                var status: Int32 = 0
                let exited = waitpid(pid, &status, WNOHANG)
                if exited == pid {
                    reaped = true
                    let signal = status & 0x7f
                    let code = (status >> 8) & 0xff
                    if signal != 0 { return result(.signal(signal)) }
                    return result(code == 0 ? nil : .exit(code))
                }
                if exited < 0 && errno != EINTR {
                    reaped = errno == ECHILD
                    return result(.output)
                }
            }
            if !received { Thread.sleep(forTimeInterval: 0.02) }
        }
    }

    private final class DoctorStream {
        private let pipe = Pipe()
        var reader: FileHandle { pipe.fileHandleForReading }
        var writer: FileHandle { pipe.fileHandleForWriting }
        var reachedEnd = false
        var data = Data()

        func enableNonblockingReads() -> Bool {
            fcntl(reader.fileDescriptor, F_SETFL, O_NONBLOCK) == 0
        }
    }

    private static func query(_ executable: URL, _ arguments: [String],
                              environment: [String: String], timeout: Duration = .seconds(25)) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(with: Result {
                    try readQuery(executable, arguments, environment: environment, timeout: timeout)
                })
            }
        }
    }

    private static func readQuery(_ executable: URL, _ arguments: [String],
                                  environment: [String: String], daemonMethods: [String]? = nil,
                                  timeout: Duration = .seconds(25)) throws -> Data {
        let process = Process()
        let input = daemonMethods == nil ? nil : Pipe()
        let pipe = Pipe()
        let reader = pipe.fileHandleForReading
        let fd = reader.fileDescriptor
        guard fcntl(fd, F_SETFL, O_NONBLOCK) == 0 else { throw SessionIssue(localized: "Could not configure the Flutter probe pipe") }
        process.executableURL = executable
        process.arguments = arguments
        process.environment = environment
        process.currentDirectoryURL = URL(fileURLWithPath: "/", isDirectory: true)
        if let input { process.standardInput = input }
        else { process.standardInput = FileHandle.nullDevice }
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        if let daemonMethods, let input {
            // Queue bounded requests before launch; keep stdin open until all responses arrive.
            for method in daemonMethods {
                let request = try JSONSerialization.data(withJSONObject: [["id": method, "method": method]])
                try input.fileHandleForWriting.write(contentsOf: request + Data([10]))
            }
        }
        do { try process.run() }
        catch { throw SessionIssue(localized: "Could not run the Flutter SDK probe") }
        defer {
            if process.isRunning { process.terminate() }
            try? reader.close()
            try? input?.fileHandleForWriting.close()
            try? input?.fileHandleForReading.close()
        }
        let deadline = ContinuousClock.now + timeout
        var data = Data()
        var pending = Data()
        var replies: [String: Any] = [:]
        var buffer = [UInt8](repeating: 0, count: 4096)
        while .now < deadline {
            let count = Darwin.read(fd, &buffer, buffer.count)
            if count > 0 {
                guard data.count + count <= 1024 * 1024 else { throw SessionIssue(localized: "Flutter probe output exceeded the limit") }
                data.append(contentsOf: buffer.prefix(count))
                if let daemonMethods {
                    pending.append(contentsOf: buffer.prefix(count))
                    while let end = pending.firstIndex(of: 10) {
                        let line = pending.prefix(upTo: end)
                        pending.removeSubrange(...end)
                        guard let messages = try? JSONSerialization.jsonObject(with: line) as? [[String: Any]] else { continue }
                        for message in messages {
                            guard let id = message["id"] as? String, daemonMethods.contains(id) else { continue }
                            guard message["error"] == nil, let result = message["result"] else {
                                throw SessionIssue(localized: "The Flutter probe did not complete successfully")
                            }
                            replies[id] = result
                        }
                    }
                    if replies.count == daemonMethods.count {
                        return try JSONSerialization.data(withJSONObject: replies)
                    }
                }
            } else if count == -1, errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR {
                throw SessionIssue(localized: "Could not read Flutter probe output")
            } else if count == 0, !process.isRunning {
                guard process.terminationStatus == 0 else { throw SessionIssue(localized: "The Flutter probe did not complete successfully") }
                guard daemonMethods == nil else { throw SessionIssue(localized: "The Flutter probe did not complete successfully") }
                return data
            } else {
                Thread.sleep(forTimeInterval: 0.02)
            }
        }
        throw SessionIssue(localized: "The Flutter probe timed out. Check the SDK or device, then refresh")
    }
}
