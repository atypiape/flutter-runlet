import Darwin
import Foundation

private func run(_ command: SessionCommand, lease: Int32, directory: Int32, machineInput: Int32?,
                 report: FileHandle) -> SessionExit {
    guard command.executable.hasPrefix("/"), fchdir(directory) == 0 else {
        return .launchFailed(ENOENT)
    }
    close(directory)
    guard fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK) == 0 else { return .launchFailed(errno) }
    var byte: UInt8 = 0
    let initial = read(STDIN_FILENO, &byte, 1)
    guard initial == -1, errno == EAGAIN || errno == EWOULDBLOCK else {
        return .launchFailed(ECANCELED)
    }

    let spawn = SessionSpawn.spawn(
        command.executable, arguments: command.arguments, environment: command.environment,
        flags: Int16(POSIX_SPAWN_CLOEXEC_DEFAULT | POSIX_SPAWN_SETPGROUP)
    ) { actions in
        let stdin = machineInput.map { posix_spawn_file_actions_adddup2(&actions, $0, STDIN_FILENO) }
            ?? posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0)
        guard stdin == 0 else { return stdin }
        for fd in [STDOUT_FILENO, STDERR_FILENO, lease] {
            let code = posix_spawn_file_actions_addinherit_np(&actions, fd)
            if code != 0 { return code }
        }
        return 0
    }
    if let machineInput { close(machineInput) }
    let pid: pid_t
    switch spawn {
    case .failure(let error): return .launchFailed(error.code)
    case .success(let child):
        pid = child
        // The trusted report pipe carries the actual spawn time before the exit report.
        let started = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        try? report.write(contentsOf: Data("\(started)\n".utf8))
    }

    var leader: SessionExit?
    var stopDeadline: ContinuousClock.Instant?
    var sentKill = false
    while true {
        if leader == nil {
            var status: Int32 = 0
            let reaped = waitpid(pid, &status, WNOHANG)
            if reaped == pid {
                leader = SessionExit(waitStatus: status)
            } else if reaped == -1 && errno != EINTR {
                leader = .unconfirmed
            }
        }
        if let leader, kill(-pid, 0) == -1 && errno == ESRCH {
            return leader
        }

        if stopDeadline == nil {
            let count = read(STDIN_FILENO, &byte, 1)
            if count >= 0 || (errno != EAGAIN && errno != EWOULDBLOCK && errno != EINTR) {
                if leader == nil, getpgid(pid) == pid { _ = kill(-pid, SIGTERM) }
                stopDeadline = .now + .seconds(3)
            }
        } else if let stopDeadline, !sentKill, ContinuousClock.now >= stopDeadline {
            // Once reaped, the old group number can eventually be reused. Observe it
            // until quiet, but only signal while its original leader can be identified.
            if leader == nil, getpgid(pid) == pid { _ = kill(-pid, SIGKILL) }
            sentKill = true
        }
        usleep(20_000)
    }
}

private func main() -> Int32 {
    let args = CommandLine.arguments.dropFirst().compactMap(Int32.init)
    guard [4, 5].contains(args.count), CommandLine.arguments.count == args.count + 1,
          Set(args).count == args.count,
          args.allSatisfy({ $0 > STDERR_FILENO }) else { return 64 }
    let lease = args[0]
    let input = FileHandle(fileDescriptor: args[1], closeOnDealloc: true)
    let report = FileHandle(fileDescriptor: args[2], closeOnDealloc: true)
    guard flock(lease, LOCK_EX | LOCK_NB) == 0,
          fcntl(report.fileDescriptor, F_SETNOSIGPIPE, 1) == 0,
          let payload = try? input.readToEnd(),
          let command = try? JSONDecoder().decode(SessionCommand.self, from: payload) else { return 65 }
    try? input.close()
    let result = run(command, lease: lease, directory: args[3], machineInput: args.count == 5 ? args[4] : nil,
                     report: report)
    guard let data = try? JSONEncoder().encode(result) else { return 66 }
    // The app can be gone by the time the worker finishes draining its group.
    try? report.write(contentsOf: data)
    return 0
}

exit(main())
