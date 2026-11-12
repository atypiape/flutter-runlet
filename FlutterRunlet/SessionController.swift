import Foundation
import Observation

@MainActor
@Observable
final class SessionController {
    private(set) var project: URL?
    private(set) var choices: [LaunchChoice] = []
    private(set) var selectedID: Int?
    private(set) var isBusy = false
    private(set) var canStop = false
    private(set) var status = "无调试会话"
    private(set) var message: String?
    private(set) var taskIssue: String?
    private(set) var recovery: ProjectRecoveryRecord?
    private(set) var logs = ""
    var selection: LaunchChoice? { choices.first { $0.id == selectedID } }
    var canRun: Bool {
        !isBusy && recovery == nil && selection?.launch != nil &&
            store != nil && debugCommand != nil && runner.isAvailable
    }
    var displayMessage: String? {
        message ?? selection?.issue ?? (project != nil && debugCommand == nil ? "当前构建尚未接入 Flutter 调试进程" : nil)
    }

    @ObservationIgnored private let store: ProjectRecoveryStore?
    @ObservationIgnored private let runner: SessionProcessRunner
    @ObservationIgnored private let allowedRoot: URL?
    @ObservationIgnored private let allowedRootIdentity: String?
    @ObservationIgnored private let debugCommand: ((PreparedLaunch) -> SessionCommand?)?
    @ObservationIgnored private let environment: [String: String]
    @ObservationIgnored private var active: SessionProcess?
    @ObservationIgnored private var operation: Task<Void, Never>?
    @ObservationIgnored private var stopRequested = false

    init(
        store: ProjectRecoveryStore?, runner: SessionProcessRunner, allowedRoot: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        debugCommand: ((PreparedLaunch) -> SessionCommand?)? = nil
    ) {
        self.store = store
        self.runner = runner
        self.allowedRoot = allowedRoot
        allowedRootIdentity = allowedRoot.flatMap { try? ProjectLocation.identity($0) }
        self.debugCommand = debugCommand
        self.environment = environment
    }

    static func fixtureEnabled(arguments: [String]) -> Bool {
        #if DEBUG
        arguments.contains("--phase-02-fixture")
        #else
        false
        #endif
    }

    static func app(arguments: [String]) -> SessionController {
        let base = URL.applicationSupportDirectory
        #if DEBUG
        if fixtureEnabled(arguments: arguments) {
            let location = base.appending(path: "FlutterRunlet-Phase02Fixture")
            do {
                let namespace = try ProjectRecoveryStore.privateDirectory(location)
                let projects = try ProjectRecoveryStore.privateDirectory(namespace.appending(path: "projects"))
                let store = try ProjectRecoveryStore(directory: namespace.appending(path: "state"))
                return SessionController(store: store, runner: .bundled, allowedRoot: projects) { launch in
                    SessionCommand(
                        executable: "/bin/sh", arguments: ["-c", """
                        /bin/mkdir -p .runlet-fixture
                        trap 'exit 0' TERM INT
                        : > .runlet-fixture/debug-started
                        while [ ! -f .runlet-fixture/debug-exit ]; do /bin/sleep 0.1; done
                        exit 19
                        """], directory: launch.directory, environment: ["PATH": "/usr/bin:/bin"]
                    )
                }
            } catch {
                let blocked = SessionController(store: nil, runner: .bundled, allowedRoot: location.appending(path: "projects"))
                blocked.message = "无法验证隔离验收目录：\(error.localizedDescription)"
                return blocked
            }
        }
        #endif
        do {
            return try SessionController(store: ProjectRecoveryStore(directory: base.appending(path: "FlutterRunlet")), runner: .bundled)
        } catch {
            let blocked = SessionController(store: nil, runner: .bundled)
            blocked.message = error.localizedDescription
            return blocked
        }
    }

    @discardableResult
    func open(_ url: URL) -> Bool {
        guard !isBusy, recovery == nil else {
            message = "请先停止当前会话并完成适用的环境恢复，再打开项目"
            return false
        }
        do {
            let canonical = try validate(url)
            project = canonical
            let config = configuration(canonical)
            choices = config.choices
            selectedID = choices.filter { $0.launch != nil }.only?.id
            taskIssue = config.taskIssue
            message = config.launchIssue
            status = "就绪"
            if let record = try store?.read(project: canonical) {
                markRecovery(record, "项目存在待恢复的环境")
            }
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    func select(_ name: String) {
        select(choices.filter { $0.name == name }.only?.id)
    }

    func select(_ id: Int?) {
        guard !isBusy else { return }
        selectedID = id
        if !choices.isEmpty { message = nil }
    }

    func run() {
        guard !isBusy, recovery == nil, let project, let selection else { return }
        guard let store, let debugCommand, runner.isAvailable else {
            message = "当前构建没有可用的 Flutter 调试进程或恢复存储"
            return
        }
        do {
            let current = try validate(project)
            let lease = try store.lease(for: current)
            if let existing = try store.read(project: current) {
                markRecovery(existing, "项目存在待恢复的环境")
                return
            }
            let config = configuration(current)
            guard let choice = config.choices.filter({ $0.name == selection.name }).only,
                  let launch = choice.launch, launch.mode == "debug" else {
                throw SessionIssue(config.launchIssue ?? config.choices.first(where: { $0.name == selection.name })?.issue
                                   ?? "原启动配置已不可用")
            }
            guard let command = debugCommand(launch) else { throw SessionIssue("调试运行适配器不可用") }
            isBusy = true
            canStop = true
            stopRequested = false
            message = nil
            logs = ""
            operation = Task { [self] in
                await execute(launch, command: command, store: store, lease: lease)
                active = nil
                canStop = false
                isBusy = false
                operation = nil
            }
        } catch {
            message = error.localizedDescription
        }
    }

    func stop() {
        guard canStop else { return }
        canStop = false
        stopRequested = true
        status = "正在停止"
        active?.stop()
    }

    func waitUntilIdle() async { await operation?.value }

    private func execute(_ launch: PreparedLaunch, command: SessionCommand,
                         store: ProjectRecoveryStore, lease: ProjectLease) async {
        var record: ProjectRecoveryRecord?
        do {
            if let post = launch.post {
                record = try store.write(project: launch.project, task: post)
            }
        } catch {
            if let visible = try? store.read(project: launch.project) {
                markRecovery(visible, "未能确认恢复记录持久提交：\(error.localizedDescription)")
            } else {
                status = "启动已阻断"
                message = error.localizedDescription
            }
            return
        }
        if let pre = launch.pre, !stopRequested {
            status = "正在运行前置任务"
            let result = await execute(pre.command, lease: lease)
            if result != .exited(0) {
                let reason = "前置任务 \(pre.label) 失败（\(result.detail)）"
                if let record { markRecovery(record, reason) }
                else { status = "前置任务失败"; message = reason }
                return
            }
        }

        if !stopRequested {
            guard launch.mode == "debug" else {
                if let record { markRecovery(record, "执行阶段拒绝非 Debug 配置") }
                else { message = "执行阶段拒绝非 Debug 配置" }
                return
            }
            status = "运行中"
            let result = await execute(command, lease: lease)
            if result == .unconfirmed {
                if let record { markRecovery(record, result.detail) }
                else { status = "进程状态未确认"; message = result.detail }
                return
            }
            if result != .exited(0), !stopRequested { message = "调试进程：\(result.detail)" }
        }
        canStop = false
        if let record, let post = launch.post {
            await restore(post, record: record, project: launch.project, store: store, lease: lease)
        } else {
            status = "就绪"
        }
    }

    private func restore(_ post: PreparedTask, record: ProjectRecoveryRecord, project: URL,
                         store: ProjectRecoveryStore, lease: ProjectLease) async {
        status = "正在恢复环境"
        let result = await execute(post.command, lease: lease)
        guard result == .exited(0) else {
            markRecovery(record, "后置任务 \(post.label) 失败（\(result.detail)）")
            return
        }
        do {
            try store.remove(project: project)
            recovery = nil
            status = "就绪"
        } catch {
            markRecovery(record, error.localizedDescription)
        }
    }

    private func execute(_ command: SessionCommand, lease: ProjectLease) async -> SessionExit {
        do {
            let process = try runner.start(command, lease: lease)
            active = process
            let result = await process.wait()
            active = nil
            let output = result.stdout + result.stderr
            if !output.isEmpty { logs = String((logs + output).suffix(64 * 1024)) }
            return result.exit
        } catch let failure as SessionSpawn.SpawnError {
            return .launchFailed(failure.code)
        } catch {
            return .launchFailed(EIO)
        }
    }

    private func markRecovery(_ record: ProjectRecoveryRecord, _ reason: String) {
        recovery = record
        status = "环境恢复失败"
        message = reason
    }

    private func validate(_ url: URL) throws -> URL {
        if let allowedRoot {
            guard let allowedRootIdentity,
                  try ProjectLocation.identity(allowedRoot) == allowedRootIdentity,
                  try ProjectLocation.directory(allowedRoot).path == allowedRoot.path else {
                throw SessionIssue("验收目录的身份已变化")
            }
        }
        return try ProjectLocation.project(url, inside: allowedRoot)
    }

    private func configuration(_ project: URL) -> ProjectConfiguration {
        ProjectConfiguration(project: project, environment: environment, restricted: allowedRoot != nil)
    }
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
