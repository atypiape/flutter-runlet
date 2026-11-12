import CryptoKit
import Darwin
import Foundation

enum ProjectLocation {
    static func project(_ url: URL, inside root: URL? = nil) throws -> URL {
        guard url.isFileURL else { throw SessionIssue("请选择本地 Flutter 项目目录") }
        let project = try directory(url)
        if let root, !contains(project, in: try directory(root)) {
            throw SessionIssue("请选择验收目录内的 Flutter 项目")
        }
        let pubspec = try file("pubspec.yaml", in: project, restricted: root != nil)
        guard let contents = try? String(contentsOf: pubspec, encoding: .utf8),
              contents.range(of: #"(?m)^\s+sdk:[ \t]*flutter(?:[ \t]*#.*)?[ \t]*$"#,
                             options: .regularExpression) != nil else {
            throw SessionIssue("所选目录缺少有效的 Flutter pubspec.yaml")
        }
        if root != nil { try validateFixtureState(project) }
        return project
    }

    private static func validateFixtureState(_ project: URL) throws {
        let state = project.appending(path: ".runlet-fixture")
        var info = stat()
        if lstat(state.path, &info) != 0 && errno == ENOENT { return }
        guard info.st_mode & S_IFMT == S_IFDIR, info.st_uid == geteuid() else {
            throw SessionIssue("验收项目的状态目录无效")
        }
        for file in try FileManager.default.contentsOfDirectory(atPath: state.path) {
            guard lstat(state.appending(path: file).path, &info) == 0,
                  info.st_mode & S_IFMT == S_IFREG, info.st_uid == geteuid(), info.st_nlink == 1 else {
                throw SessionIssue("验收项目的状态文件无效")
            }
        }
    }

    static func directory(_ url: URL) throws -> URL {
        let fd = open(url.path, O_RDONLY | O_DIRECTORY | O_CLOEXEC)
        guard fd >= 0 else { throw SessionIssue("项目或工作目录不可用") }
        defer { close(fd) }
        var bytes = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        guard fcntl(fd, F_GETPATH, &bytes) == 0,
              let path = bytes.withUnsafeBufferPointer({ String(validatingCString: $0.baseAddress!) }) else {
            throw SessionIssue("无法确定目录的规范路径")
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    static func identity(_ url: URL) throws -> String {
        var info = stat()
        guard stat(url.path, &info) == 0, info.st_mode & S_IFMT == S_IFDIR else {
            throw SessionIssue("无法确认项目目录身份")
        }
        return "\(info.st_dev)-\(info.st_ino)"
    }

    static func file(_ name: String, in project: URL, restricted: Bool) throws -> URL {
        let file = project.appending(path: name).resolvingSymlinksInPath()
        if restricted && !contains(file, in: project) { throw SessionIssue("项目文件超出验收目录") }
        return file
    }

    static func contains(_ url: URL, in directory: URL) -> Bool {
        let components = url.resolvingSymlinksInPath().pathComponents
        let root = directory.resolvingSymlinksInPath().pathComponents
        return components.count > root.count && components.starts(with: root)
    }
}

struct PreparedTask: Equatable, Sendable {
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

struct PreparedLaunch: Equatable, Sendable {
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
}

struct LaunchChoice: Identifiable, Equatable {
    let id: Int
    let name: String
    let launch: PreparedLaunch?
    let issue: String?
}

struct ProjectConfiguration {
    // SHA-256 of the checked-in public fixture script.
    private static let fixtureScriptDigest = "2d07516e06a3fdab9a13fe9015d1f1d35ef952dc88732ae9f142019e6d44f154"

    let project: URL
    let environment: [String: String]
    let restricted: Bool
    let choices: [LaunchChoice]
    let launchIssue: String?
    let taskIssue: String?
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
        choices = source.enumerated().map { index, entry in
            let name = entry["name"] as? String ?? "配置 \(index + 1)"
            let result = Result {
                try Self.prepare(entry, project: project, tasks: (try? taskResult.get()) ?? [],
                                 taskIssue: taskResult.issue, environment: environment, restricted: restricted)
            }
            return LaunchChoice(id: index, name: name, launch: try? result.get(), issue: result.issue)
        }
    }

    func prepareTask(_ label: String) throws -> PreparedTask {
        try Self.prepareTask(label, tasks: tasks, taskIssue: taskIssue,
                             project: project, environment: environment, restricted: restricted)
    }

    private static func prepare(
        _ entry: [String: Any], project: URL, tasks: [[String: Any]], taskIssue: String?,
        environment: [String: String], restricted: Bool
    ) throws -> PreparedLaunch {
        guard let name = entry["name"] as? String, !name.isEmpty else { throw SessionIssue("配置缺少名称") }
        guard entry["type"] as? String == "dart", entry["request"] as? String == "launch" else {
            throw SessionIssue("仅支持 Dart Flutter 启动配置")
        }
        let mode = try string(entry, key: "flutterMode", default: "debug")
        guard mode == "debug" else { throw SessionIssue("仅支持 Debug 模式（当前为 \(mode)）") }
        var variables = ConfigVariables(project: project, environment: environment)
        let program = try resolve(variables.expand(string(entry, key: "program", default: "lib/main.dart")), in: project)
        guard program.pathExtension == "dart", FileManager.default.fileExists(atPath: program.path) else {
            throw SessionIssue("Dart 入口文件不可用")
        }
        let cwd = try ProjectLocation.directory(resolve(variables.expand(string(entry, key: "cwd", default: project.path)), in: project))
        if restricted && (!ProjectLocation.contains(program, in: project) || !insideProject(cwd, project)) {
            throw SessionIssue("Dart 入口或工作目录超出验收项目")
        }
        let options = try dictionary(entry, "osx")
        var env = try dictionary(entry, "env")
        env.merge(try dictionary(options, "env"), uniquingKeysWith: { _, macOS in macOS })
        let launchEnvironment = try variables.apply(env)
        var tool = try strings(entry, "toolArgs").map { try variables.expand($0) }
        let arguments = try strings(entry, "args").map { try variables.expand($0) }
        var application: [String] = []
        for argument in arguments {
            if argument.hasPrefix("--dart-define=") {
                guard argument.dropFirst("--dart-define=".count).firstIndex(of: "=").map({
                    $0 != argument.index(argument.startIndex, offsetBy: "--dart-define=".count)
                }) == true else { throw SessionIssue("旧 Dart define 格式无效，请移到 toolArgs") }
                tool.append(argument)
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
        _ label: String, tasks: [[String: Any]], taskIssue: String?, project: URL,
        environment: [String: String], restricted: Bool
    ) throws -> PreparedTask {
        if let taskIssue { throw SessionIssue(taskIssue) }
        let matches = tasks.filter { $0["label"] as? String == label }
        guard let entry = matches.first else { throw SessionIssue("找不到任务 \(label)") }
        guard matches.count == 1 else { throw SessionIssue("任务标签重复：\(label)") }
        let type = try string(entry, key: "type")
        guard ["shell", "process"].contains(type),
              entry["dependsOn"] == nil, entry["isBackground"] == nil || (entry["isBackground"] as? Bool) == false,
              entry["problemMatcher"] == nil || (entry["problemMatcher"] as? [Any])?.isEmpty == true else {
            throw SessionIssue("暂不支持任务 \(label) 的类型、依赖或后台设置")
        }
        let options = try dictionary(entry, "options")
        guard options.keys.allSatisfy({ ["cwd", "env"].contains($0) }) else {
            throw SessionIssue("暂不支持任务 \(label) 的执行选项")
        }
        let rawEnvironment = try dictionary(options, "env")
        let rawCommand = try string(entry, key: "command")
        let rawArguments = try strings(entry, "args")
        let rawDirectory = try string(options, key: "cwd", default: "$" + "{workspaceFolder}")
        var variables = ConfigVariables(project: project, environment: environment)
        let cwd = try ProjectLocation.directory(resolve(variables.expand(rawDirectory), in: project))
        if restricted && !insideProject(cwd, project) { throw SessionIssue("任务工作目录超出验收项目") }
        let taskEnvironment = try variables.apply(rawEnvironment)
        let command = try variables.expand(rawCommand)
        var argv = try rawArguments.map { try variables.expand($0) }
        let executable: String
        if restricted {
            guard command == "/bin/sh", argv.count == 3,
                  argv[0] == project.appending(path: "scripts/simulate-firebase-switch.sh").path,
                  try ProjectLocation.file("scripts/simulate-firebase-switch.sh", in: project, restricted: true).path ==
                    project.resolvingSymlinksInPath().appending(path: "scripts/simulate-firebase-switch.sh").path,
                  cwd == project, ["dev", "test", "prod"].contains(argv[1]), argv[2] == "--quiet",
                  rawEnvironment.isEmpty,
                  let script = try? Data(contentsOf: URL(fileURLWithPath: argv[0])),
                  SHA256.hash(data: script).map({ String(format: "%02x", $0) }).joined() == fixtureScriptDigest else {
                throw SessionIssue("验收模式仅支持公开样例的环境切换任务")
            }
            executable = "/bin/sh"
        } else if let path = executablePath(command, directory: cwd, environment: taskEnvironment) {
            executable = path
        } else if type == "shell", entry["args"] == nil, rawCommand == command,
                  command.rangeOfCharacter(from: .whitespaces) != nil {
            executable = "/bin/sh"
            argv = ["-c", command]
        } else {
            throw SessionIssue("任务 \(label) 的命令不可执行或引用方式暂不支持")
        }
        let definition = PreparedTask.Definition(
            type: type, command: rawCommand, arguments: rawArguments, directory: rawDirectory,
            environment: try rawEnvironment.mapValues {
                guard let value = $0 as? String else { throw SessionIssue("任务环境值必须是字符串") }
                return value
            }
        )
        return PreparedTask(label: label,
                            command: SessionCommand(executable: executable, arguments: argv, directory: cwd.path,
                                                    environment: restricted ? ["PATH": "/usr/bin:/bin"] : taskEnvironment),
                            definition: definition, references: variables.references)
    }

    private static func read(_ file: String, key: String, in project: URL, restricted: Bool) throws -> [[String: Any]] {
        let name = "\(file).json"
        let url = try ProjectLocation.file(".vscode/\(name)", in: project, restricted: restricted)
        let data: Data
        do { data = try Data(contentsOf: url) } catch {
            throw SessionIssue("\(name) 缺失或无法读取")
        }
        let object: Any
        do { object = try JSONSerialization.jsonObject(with: jsonWithoutComments(data)) } catch {
            let info = (error as NSError).userInfo
            let position = info["NSJSONSerializationErrorIndex"] as? Int ?? 0
            let prefix = String(decoding: data.prefix(max(0, position)), as: UTF8.self)
            let lines = prefix.replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n").components(separatedBy: "\n")
            throw SessionIssue("\(name) 第 \(lines.count) 行第 \((lines.last?.count ?? 0) + 1) 列：JSONC 语法错误")
        }
        guard let entries = (object as? [String: Any])?[key] as? [[String: Any]] else {
            throw SessionIssue("\(name) 的 \(key) 必须是对象数组")
        }
        return entries
    }

    private static func jsonWithoutComments(_ data: Data) -> Data {
        var bytes = Array(data)
        var index = 0
        var inString = false
        var previous: UInt8?
        var comma: Int?
        while index < bytes.count {
            let byte = bytes[index]
            if inString {
                if byte == 92 { index += 2; continue }
                if byte == 34 { inString = false }
            } else if byte == 47, index + 1 < bytes.count, [42, 47].contains(bytes[index + 1]) {
                let start = index
                let line = bytes[index + 1] == 47
                index += 2
                while index < bytes.count {
                    if line && [10, 13].contains(bytes[index]) { break }
                    if !line && bytes[index] == 42 && index + 1 < bytes.count && bytes[index + 1] == 47 {
                        index += 2
                        break
                    }
                    index += 1
                }
                if !line && (index - start < 4 || bytes[(index - 2)..<index] != [42, 47]) { return data }
                for offset in start..<index where ![10, 13].contains(bytes[offset]) { bytes[offset] = 32 }
                continue
            } else if ![9, 10, 13, 32].contains(byte) {
                if [93, 125].contains(byte), let comma { bytes[comma] = 32 }
                comma = byte == 44 && previous.map({ ![44, 58, 91, 123].contains($0) }) == true ? index : nil
                inString = byte == 34
                previous = byte
            }
            index += 1
        }
        return Data(bytes)
    }

    private static func executablePath(_ command: String, directory: URL, environment: [String: String]) -> String? {
        if command.contains("/") {
            let path = resolve(command, in: directory).path
            return FileManager.default.isExecutableFile(atPath: path) ? path : nil
        }
        return (environment["PATH"] ?? "/usr/bin:/bin").components(separatedBy: ":")
            .lazy.map { resolve($0, in: directory).appending(path: command).path }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
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
            throw SessionIssue("\(key) 必须是非空字符串")
        }
        return value
    }

    private static func strings(_ object: [String: Any], _ key: String) throws -> [String] {
        guard let value = object[key] else { return [] }
        guard let strings = value as? [String], strings.allSatisfy({ !$0.utf8.contains(0) }) else {
            throw SessionIssue("\(key) 必须是字符串数组")
        }
        return strings
    }

    private static func dictionary(_ object: [String: Any], _ key: String) throws -> [String: Any] {
        guard let value = object[key] else { return [:] }
        guard let dictionary = value as? [String: Any] else { throw SessionIssue("\(key) 必须是对象") }
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
            guard let end = rest.firstIndex(of: "}") else { throw SessionIssue("配置变量未闭合") }
            let variable = String(rest[..<end])
            if variable == "workspaceFolder" {
                output += project.path
            } else if variable.hasPrefix("env:") {
                let name = String(variable.dropFirst(4))
                guard let value = environment[name] else { throw SessionIssue("环境变量 \(name) 未设置") }
                references[name] = value
                output += value
            } else {
                throw SessionIssue("暂不支持配置变量 \(variable)")
            }
            rest = rest[rest.index(after: end)...]
        }
        output += rest
        guard !output.utf8.contains(0) else { throw SessionIssue("参数含无效字符") }
        return output
    }

    mutating func apply(_ overrides: [String: Any]) throws -> [String: String] {
        var values = environment
        for (name, raw) in overrides {
            guard !name.isEmpty, !name.contains("="), !name.utf8.contains(0), let text = raw as? String else {
                throw SessionIssue("环境变量定义无效")
            }
            values[name] = try expand(text)
        }
        return values
    }
}

private extension Result where Failure == Error {
    var issue: String? {
        if case .failure(let error) = self { return error.localizedDescription }
        return nil
    }
}
