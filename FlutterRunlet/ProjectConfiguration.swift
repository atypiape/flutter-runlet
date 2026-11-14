import CoreFoundation
import CryptoKit
import Darwin
import Foundation

enum ProjectLocation {
    // SHA-256 of the checked-in public fixture script.
    private static let fixtureScriptDigest = "4172fdee6bb993e6a23acc6ab6a95702ecf0deca97c127568bd83e78682165ad"

    static func project(_ url: URL, inside root: URL? = nil) throws -> URL {
        guard url.isFileURL else { throw SessionIssue(localized: "Select a local Flutter project directory") }
        let project = try directory(url)
        if let root, !contains(project, in: try directory(root)) {
            throw SessionIssue(localized: "Select a Flutter project inside the acceptance directory")
        }
        let pubspec = try file("pubspec.yaml", in: project, restricted: root != nil)
        guard let contents = try? String(contentsOf: pubspec, encoding: .utf8),
              contents.range(of: #"(?m)^\s+sdk:[ \t]*flutter(?:[ \t]*#.*)?[ \t]*$"#,
                             options: .regularExpression) != nil else {
            throw SessionIssue(localized: "The selected directory has no valid Flutter pubspec.yaml")
        }
        if root != nil { try validateFixtureState(project) }
        return project
    }

    private static func validateFixtureState(_ project: URL) throws {
        let state = project.appending(path: ".runlet-fixture")
        var info = stat()
        if lstat(state.path, &info) != 0 && errno == ENOENT { return }
        guard info.st_mode & S_IFMT == S_IFDIR, info.st_uid == geteuid() else {
            throw SessionIssue(localized: "The acceptance project state directory is invalid")
        }
        for file in try FileManager.default.contentsOfDirectory(atPath: state.path) {
            guard lstat(state.appending(path: file).path, &info) == 0,
                  info.st_mode & S_IFMT == S_IFREG, info.st_uid == geteuid(), info.st_nlink == 1 else {
                throw SessionIssue(localized: "The acceptance project state file is invalid")
            }
        }
    }

    static func validateFixtureTask(executable: String, arguments: [String], cwd: URL, project: URL) throws {
        let relativeScript = "scripts/simulate-firebase-switch.sh"
        guard executable == "/bin/sh", arguments.count == 3,
              arguments[0] == project.appending(path: relativeScript).path,
              try file(relativeScript, in: project, restricted: true).path ==
                project.resolvingSymlinksInPath().appending(path: relativeScript).path,
              cwd.path == project.path, ["dev", "test", "prod"].contains(arguments[1]), arguments[2] == "--quiet",
              let script = try? Data(contentsOf: URL(fileURLWithPath: arguments[0])),
              SHA256.hash(data: script).map({ String(format: "%02x", $0) }).joined() == fixtureScriptDigest else {
            throw SessionIssue(localized: "Acceptance mode only supports environment-switching tasks from the public sample")
        }
        try validateFixtureState(project)
    }

    static func directory(_ url: URL) throws -> URL {
        let fd = open(url.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard fd >= 0 else { throw SessionIssue(localized: "The project or working directory is unavailable") }
        defer { close(fd) }
        var bytes = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard fcntl(fd, F_GETPATH, &bytes) == 0,
              let path = bytes.withUnsafeBufferPointer({ String(validatingCString: $0.baseAddress!) }) else {
            throw SessionIssue(localized: "Could not determine the canonical directory path")
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    static func identity(_ url: URL) throws -> String {
        var info = stat()
        guard stat(url.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR else {
            throw SessionIssue(localized: "Could not verify the project directory identity")
        }
        return "\(info.st_dev)-\(info.st_ino)"
    }

    static func file(_ name: String, in project: URL, restricted: Bool) throws -> URL {
        let file = project.appending(path: name).resolvingSymlinksInPath()
        if restricted && !contains(file, in: project) { throw SessionIssue(localized: "The project file is outside the acceptance directory") }
        return file
    }

    static func contains(_ url: URL, in directory: URL) -> Bool {
        let components = url.resolvingSymlinksInPath().pathComponents
        let root = directory.resolvingSymlinksInPath().pathComponents
        return components.count > root.count && components.starts(with: root)
    }
}

struct PreparedTask: Codable, Equatable, Sendable {
    struct Definition: Codable, Equatable, Sendable {
        let type: String
        let command: String
        let arguments: [String]
        let directory: String
        let environment: [String: String]
    }

    let label: String
    let command: SessionCommand
    let definition: Definition
    let references: [String: String]
}

struct PreparedLaunch: Codable, Equatable, Sendable {
    let project: URL
    let name: String
    let mode: String
    let program: String
    let directory: String
    let toolArguments: [String]
    let applicationArguments: [String]
    let environment: [String: String]
    let deviceID: String?
    let pre: PreparedTask?
    let post: PreparedTask?

    func executionMatches(_ other: Self) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let left = try? encoder.encode(self), let right = try? encoder.encode(other) else { return false }
        return left == right
    }
}

struct LaunchChoice: Identifiable, Equatable {
    let id: Int
    let name: String?
    let launch: PreparedLaunch?
    let issue: LocalizedStringResource?

    var title: LocalizedStringResource {
        if let name { return .verbatim(name) }
        return "Unnamed Configuration \(String(id + 1))"
    }
}

struct ProjectConfiguration {
    let project: URL
    let environment: [String: String]
    let restricted: Bool
    let choices: [LaunchChoice]
    let launchIssue: LocalizedStringResource?
    let taskIssue: LocalizedStringResource?
    private let tasks: [[String: Any]]

    init(project: URL, environment: [String: String], restricted: Bool) {
        self.project = project
        self.environment = environment
        self.restricted = restricted
        let taskResult = Result { try Self.read("tasks", key: "tasks", in: project, restricted: restricted) }
        tasks = (try? taskResult.get()) ?? []
        taskIssue = taskResult.issue
        let launchResult = Result { try Self.read("launch", key: "configurations", in: project, restricted: restricted) }
        launchIssue = launchResult.issue
        let source = (try? launchResult.get()) ?? []
        let names = source.compactMap { $0["name"] as? String }
        let nameCounts = Dictionary(grouping: names, by: { $0 }).mapValues(\.count)
        choices = source.enumerated().map { index, entry in
            let name = entry["name"] as? String
            if let name, nameCounts[name, default: 0] > 1 {
                return LaunchChoice(id: index, name: name, launch: nil, issue: "Duplicate launch configuration name. Rename it in launch.json")
            }
            let result = Result {
                try Self.prepare(entry, project: project, tasks: (try? taskResult.get()) ?? [],
                                 taskIssue: taskResult.issue, environment: environment, restricted: restricted)
            }
            return LaunchChoice(id: index, name: name, launch: try? result.get(), issue: result.issue)
        }
    }

    func prepareTask(
        _ label: String, verify: (PreparedTask.Definition) throws -> Void = { _ in }
    ) throws -> PreparedTask {
        try Self.prepareTask(label, tasks: tasks, taskIssue: taskIssue, project: project,
                             environment: environment, restricted: restricted, verify: verify)
    }

    private static func prepare(
        _ entry: [String: Any], project: URL, tasks: [[String: Any]], taskIssue: LocalizedStringResource?,
        environment: [String: String], restricted: Bool
    ) throws -> PreparedLaunch {
        guard let name = entry["name"] as? String, !name.isEmpty else { throw SessionIssue(localized: "The configuration has no name") }
        guard entry["type"] as? String == "dart", entry["request"] as? String == "launch" else {
            throw SessionIssue(localized: "Only Dart Flutter launch configurations are supported")
        }
        let mode = try string(entry, key: "flutterMode", default: "debug")
        guard mode == "debug" else { throw SessionIssue(localized: "Only Debug mode is supported (current mode: \(mode))") }
        var variables = ConfigVariables(project: project, environment: environment)
        let program = try resolve(variables.expand(string(entry, key: "program", default: "lib/main.dart")), in: project)
        var fileInfo = stat()
        guard program.pathExtension == "dart", stat(program.path, &fileInfo) == 0,
              fileInfo.st_mode & S_IFMT == S_IFREG else {
            throw SessionIssue(localized: "The Dart entry point is unavailable")
        }
        let cwd = try ProjectLocation.directory(resolve(variables.expand(string(entry, key: "cwd", default: project.path)), in: project))
        if restricted && (!ProjectLocation.contains(program, in: project) || !insideProject(cwd, project)) {
            throw SessionIssue(localized: "The Dart entry point or working directory is outside the acceptance project")
        }
        let options = try dictionary(entry, "osx")
        guard options.keys.allSatisfy({ $0 == "env" }) else {
            throw SessionIssue(localized: "macOS launch overrides other than osx.env are unsupported")
        }
        var env = try dictionary(entry, "env")
        env.merge(try dictionary(options, "env"), uniquingKeysWith: { _, macOS in macOS })
        let launchEnvironment = try variables.apply(env)
        var tool = try strings(entry, "toolArgs").map { try variables.expand($0) }
        var keys = try validateToolArguments(tool)
        let arguments = try strings(entry, "args").map { try variables.expand($0) }
        var application: [String] = []
        let define = "--dart-define="
        for argument in arguments {
            if argument.hasPrefix(define) {
                let key = try defineKey(String(argument.dropFirst(define.count)))
                guard keys.insert(key).inserted else { throw SessionIssue(localized: "Conflicting Dart defines. Keep one declaration in toolArgs") }
                tool.append(argument)
            } else if argument == "--dart-define" || argument == "--dart-define-from-file" ||
                        argument.hasPrefix("--dart-define-from-file=") {
                throw SessionIssue(localized: "The legacy Dart define format is unsupported. Move it to toolArgs")
            } else {
                application.append(argument)
            }
        }
        func task(_ key: String) throws -> PreparedTask? {
            guard entry[key] != nil else { return nil }
            return try prepareTask(string(entry, key: key), tasks: tasks, taskIssue: taskIssue,
                                   project: project, environment: environment, restricted: restricted)
        }
        let device = try entry["deviceId"].map { _ in try variables.expand(string(entry, key: "deviceId")) }
        return try PreparedLaunch(project: project, name: name, mode: mode, program: program.path, directory: cwd.path,
                                  toolArguments: tool, applicationArguments: application, environment: launchEnvironment,
                                  deviceID: device, pre: task("preLaunchTask"), post: task("postDebugTask"))
    }

    private static func prepareTask(
        _ label: String, tasks: [[String: Any]], taskIssue: LocalizedStringResource?, project: URL,
        environment: [String: String], restricted: Bool,
        verify: (PreparedTask.Definition) throws -> Void = { _ in }
    ) throws -> PreparedTask {
        if let taskIssue { throw SessionIssue(localized: taskIssue) }
        let matches = tasks.filter { $0["label"] as? String == label }
        guard let entry = matches.first else { throw SessionIssue(localized: "Could not find task \(label)") }
        guard matches.count == 1 else { throw SessionIssue(localized: "Duplicate task label: \(label)") }
        let type = try string(entry, key: "type")
        guard ["shell", "process"].contains(type),
              entry["dependsOn"] == nil, entry["runOptions"] == nil, entry["osx"] == nil,
              isAbsentOrFalse(entry["isBackground"]),
              entry["problemMatcher"] == nil || (entry["problemMatcher"] as? [Any])?.isEmpty == true else {
            throw SessionIssue(localized: "Task \(label) uses an unsupported type, dependency, or background setting")
        }
        let options = try dictionary(entry, "options")
        guard options.keys.allSatisfy({ ["cwd", "env"].contains($0) }) else {
            throw SessionIssue(localized: "Task \(label) uses unsupported execution options")
        }
        let rawEnvironment = try dictionary(options, "env")
        let rawCommand = try string(entry, key: "command")
        let rawArguments = try strings(entry, "args")
        let rawDirectory = try string(options, key: "cwd", default: "$" + "{workspaceFolder}")
        let definition = PreparedTask.Definition(
            type: type, command: rawCommand, arguments: rawArguments, directory: rawDirectory,
            environment: try rawEnvironment.mapValues {
                guard let value = $0 as? String else { throw SessionIssue(localized: "Task environment values must be strings") }
                return value
            }
        )
        try verify(definition)
        var variables = ConfigVariables(project: project, environment: environment)
        let cwd = try ProjectLocation.directory(resolve(variables.expand(rawDirectory), in: project))
        if restricted && !insideProject(cwd, project) { throw SessionIssue(localized: "The task working directory is outside the acceptance project") }
        let taskEnvironment = try variables.apply(rawEnvironment)
        let command = try variables.expand(rawCommand)
        var argv = try rawArguments.map { try variables.expand($0) }
        let executable: String
        if restricted {
            guard rawEnvironment.isEmpty else { throw SessionIssue(localized: "Acceptance tasks do not support extra environment variables") }
            try ProjectLocation.validateFixtureTask(executable: command, arguments: argv, cwd: cwd, project: project)
            executable = "/bin/sh"
        } else if let path = executablePath(command, directory: cwd, environment: taskEnvironment) {
            executable = path
        } else if type == "shell", rawArguments.isEmpty, rawCommand == command,
                  command.rangeOfCharacter(from: .whitespaces) != nil {
            executable = "/bin/sh"
            argv = ["-c", command]
        } else {
            throw SessionIssue(localized: "The command for task \(label) is not executable or uses unsupported quoting")
        }
        return PreparedTask(label: label,
                            command: SessionCommand(executable: executable, arguments: argv, directory: cwd.path,
                                                    environment: restricted ? ["PATH": "/usr/bin:/bin"] : taskEnvironment),
                            definition: definition, references: variables.references)
    }

    private static func validateToolArguments(_ arguments: [String]) throws -> Set<String> {
        let flags: Set<String> = [
            "--verbose", "-v", "--pub", "--no-pub", "--build", "--no-build", "--start-paused",
            "--hot", "--no-hot", "--track-widget-creation", "--no-track-widget-creation",
            "--enable-software-rendering", "--enable-impeller", "--no-enable-impeller",
            "--machine", "--no-resident", "--dds", "--no-dds"
        ]
        let options: Set<String> = [
            "--dart-define", "--dart-define-from-file", "--flavor", "--route",
            "--web-port", "--web-hostname", "--web-browser-flag", "--host-vmservice-port",
            "--device-vmservice-port", "--dds-port", "--device-timeout"
        ]
        var index = 0
        var keys: Set<String> = []
        while index < arguments.count {
            let token = arguments[index]
            index += 1
            if flags.contains(token) { continue }
            let parts = token.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard let option = parts.first.map(String.init), options.contains(option) else {
                throw SessionIssue(localized: "toolArgs contains an argument that may override Debug mode, the entry point, or the device")
            }
            let value: String
            if parts.count == 2 {
                value = String(parts[1])
            } else {
                guard index < arguments.count, !arguments[index].hasPrefix("-") else {
                    throw SessionIssue(localized: "\(option) in toolArgs requires a value")
                }
                value = arguments[index]
                index += 1
            }
            guard !value.isEmpty else { throw SessionIssue(localized: "\(option) in toolArgs requires a value") }
            if option == "--dart-define" {
                let key = try defineKey(value)
                guard keys.insert(key).inserted else { throw SessionIssue(localized: "Duplicate Dart define in toolArgs") }
            }
        }
        return keys
    }

    private static func defineKey(_ assignment: String) throws -> String {
        guard let separator = assignment.firstIndex(of: "="), separator != assignment.startIndex else {
            throw SessionIssue(localized: "Dart defines must use KEY=VALUE. Check toolArgs")
        }
        let key = String(assignment[..<separator])
        guard !key.hasPrefix("-"), !key.contains(where: \.isWhitespace) else {
            throw SessionIssue(localized: "The Dart define name is invalid. Check toolArgs")
        }
        return key
    }

    private static func read(_ file: String, key: String, in project: URL, restricted: Bool) throws -> [[String: Any]] {
        let name = "\(file).json"
        let url = try ProjectLocation.file(".vscode/\(name)", in: project, restricted: restricted)
        let data: Data
        do {
            let values = try url.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else { throw SessionIssue(localized: "The configuration must be a regular file") }
            data = try Data(contentsOf: url)
        } catch {
            throw SessionIssue(localized: "\(name) is missing or unreadable")
        }
        let object = try JSONCReader.decode(data, file: name)
        guard let entries = (object as? [String: Any])?[key] as? [[String: Any]] else {
            throw SessionIssue(localized: "\(key) in \(name) must be an array of objects")
        }
        return entries
    }

    private static func isAbsentOrFalse(_ value: Any?) -> Bool {
        guard let value else { return true }
        guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return false }
        return !number.boolValue
    }

    private static func executablePath(_ command: String, directory: URL, environment: [String: String]) -> String? {
        func isExecutable(_ path: String) -> Bool {
            var info = stat()
            return stat(path, &info) == 0 && info.st_mode & S_IFMT == S_IFREG && access(path, X_OK) == 0
        }
        if command.contains("/") {
            let path = resolve(command, in: directory).path
            return isExecutable(path) ? path : nil
        }
        return (environment["PATH"] ?? "/usr/bin:/bin").components(separatedBy: ":")
            .lazy.map { resolve($0, in: directory).appending(path: command).path }
            .first(where: isExecutable)
    }

    private static func resolve(_ path: String, in directory: URL) -> URL {
        URL(fileURLWithPath: path, relativeTo: directory).standardizedFileURL.resolvingSymlinksInPath()
    }

    private static func insideProject(_ url: URL, _ project: URL) -> Bool {
        url.path == project.path || ProjectLocation.contains(url, in: project)
    }

    private static func string(_ object: [String: Any], key: String, default fallback: String? = nil) throws -> String {
        if object[key] == nil, let fallback { return fallback }
        guard let value = object[key] as? String, !value.isEmpty, !value.utf8.contains(0) else {
            throw SessionIssue(localized: "\(key) must be a nonempty string")
        }
        return value
    }

    private static func strings(_ object: [String: Any], _ key: String) throws -> [String] {
        guard let value = object[key] else { return [] }
        guard let strings = value as? [String], strings.allSatisfy({ !$0.utf8.contains(0) }) else {
            throw SessionIssue(localized: "\(key) must be an array of strings")
        }
        return strings
    }

    private static func dictionary(_ object: [String: Any], _ key: String) throws -> [String: Any] {
        guard let value = object[key] else { return [:] }
        guard let dictionary = value as? [String: Any] else { throw SessionIssue(localized: "\(key) must be an object") }
        return dictionary
    }
}

private struct ConfigVariables {
    let project: URL
    let environment: [String: String]
    var references: [String: String] = [:]

    mutating func expand(_ input: String) throws -> String {
        var rest = input[...]
        var output = ""
        while let opening = rest.range(of: "$" + "{") {
            output += rest[..<opening.lowerBound]
            rest = rest[opening.upperBound...]
            guard let end = rest.firstIndex(of: "}") else { throw SessionIssue(localized: "Unterminated configuration variable") }
            let variable = String(rest[..<end])
            if variable == "workspaceFolder" {
                output += project.path
            } else if variable.hasPrefix("env:") {
                let name = String(variable.dropFirst(4))
                guard let value = environment[name] else { throw SessionIssue(localized: "Environment variable \(name) is not set") }
                references[name] = value
                output += value
            } else {
                throw SessionIssue(localized: "Unsupported configuration variable \(variable)")
            }
            rest = rest[rest.index(after: end)...]
        }
        output += rest
        guard !output.utf8.contains(0) else { throw SessionIssue(localized: "An argument contains an invalid character") }
        return output
    }

    mutating func apply(_ overrides: [String: Any]) throws -> [String: String] {
        var values = environment
        for (name, raw) in overrides {
            guard !name.isEmpty, !name.contains("="), !name.utf8.contains(0), let text = raw as? String else {
                throw SessionIssue(localized: "The environment variable definition is invalid")
            }
            values[name] = try expand(text)
        }
        return values
    }
}

private extension Result where Failure == Error {
    var issue: LocalizedStringResource? {
        if case .failure(let error) = self { return .appIssue(error) }
        return nil
    }
}
