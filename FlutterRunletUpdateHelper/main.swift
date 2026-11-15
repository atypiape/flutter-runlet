import AppKit
import Darwin
import Foundation

@MainActor
private final class UpdateHelper {
    private enum Outcome {
        case ready(UpdateChannel, UpdateProcessIdentity), unready(NSRunningApplication, UpdateProcessIdentity), absent, unknown
    }

    private let fixture = IsolatedUpdateBuild.read(helper: true)
    private let staging: UpdateDirectory
    private let recovery: UpdateDirectory
    private var locks: [Int32]
    private var journal: UpdateJournal
    private var listener: UpdateChannel?

    init(_ arguments: [String]) throws {
        guard arguments.count >= 4, UpdatePackageService.helperMayInstall(fixture) else { throw UpdateChannel.Issue.channel }
        let inherited = arguments.dropFirst(2).compactMap(Int32.init)
        guard inherited.count == arguments.count - 2, Set(inherited).count == inherited.count,
              inherited.allSatisfy({ $0 > STDERR_FILENO && fcntl($0, F_GETFD) != -1 }) else { throw UpdateChannel.Issue.channel }
        staging = try UpdateDirectory(URL(filePath: arguments[0], directoryHint: .isDirectory), privateAccess: true)
        recovery = try UpdateDirectory(URL(filePath: arguments[1], directoryHint: .isDirectory), privateAccess: true)
        guard let record = try staging.read(UpdateJournal.intent, as: UpdateJournal.self),
              try recovery.read(UpdateJournal.pending, as: UpdateJournal.self)?.id == record.id,
              Bundle.main.bundleURL.path == record.copiedHelper.path,
              record.oldProcess.pid == getppid(), record.stageIdentity == staging.identity,
              record.recoveryIdentity == recovery.identity, record.stage.path == staging.url.path,
              fixture == nil || recovery.url.path == fixture?.recovery.path,
              record.oldProcess.verifies(record.original, executable: record.targetExecutable),
              try UpdatePackageService.copiedHelperHashes(at: record.copiedHelper, productID: record.product, fixture: fixture)
                == record.original.helperCodeHashes else { throw UpdateChannel.Issue.peer }
        for (descriptor, name) in zip(inherited, [UpdateActivityLease.name, "installation.lock"]) {
            var actual = stat()
            var expected = stat()
            guard fstat(descriptor, &actual) == 0,
                  fstatat(recovery.descriptor, name, &expected, AT_SYMLINK_NOFOLLOW) == 0,
                  actual.st_mode & S_IFMT == S_IFREG, UpdateObjectIdentity(actual) == UpdateObjectIdentity(expected) else {
                throw UpdateChannel.Issue.peer
            }
        }
        journal = record
        locks = inherited
    }

    func run() async {
        defer { releaseLocks(); unlink(journal.socket.path) }
        do {
            let parent = try UpdateChannel(taking: STDIN_FILENO)
            guard parent.matchesPeer(journal.oldProcess) else { return }
            try journal.verifyArrangement(false, fixture: fixture)
            listener = try UpdateChannel.listen(journal.socket)
            guard let helper = UpdateProcessIdentity(getpid()) else { return }
            journal.helperProcess = helper
            try persist()
            if fault("helper-no-ready"), let fixture {
                try UpdateDirectory(fixture.root, privateAccess: true).write(journal, to: "helper-refused.json")
                return
            }
            try parent.send(UpdateMessage.ready)
            guard try await parent.receive(until: .now + .seconds(20)) == UpdateMessage.proceed,
                  await waitForExit(journal.oldProcess, until: .now + .seconds(12)) else { return }
        } catch {
            return
        }
        await replaceAndLaunch()
    }

    private func replaceAndLaunch() async {
        do {
            try UpdateProcessIdentity.requireNoOtherInstances(journal.product, excluding: nil)
            try recovery.verify()
            let contents = try FileManager.default.contentsOfDirectory(atPath: recovery.url.path)
            guard !contents.contains(where: { $0.hasSuffix(".risk") || $0.hasPrefix("update-worker-") }),
                  !fault("exchange-before") else { throw UpdateDirectory.Issue.exchange }
            journal.phase = .waitingForNew
            try persist()
            try journal.exchange(restoring: false, fixture: fixture)
        } catch {
            if (try? journal.verifyArrangement(false, fixture: fixture)) != nil {
                await reopenOriginal(failure: .replacement)
            } else {
                preserve()
            }
            return
        }
        switch await launch(journal.candidate, role: "b", timeout: .seconds(8)) {
        case .ready(let channel, let process):
            do {
                try journal.verifyArrangement(true, fixture: fixture)
                try channel.send(UpdateMessage.verify)
                guard try await channel.receive(until: .now + .seconds(3)) == UpdateMessage.verified,
                      process.verifies(journal.candidate, executable: journal.targetExecutable) else {
                    throw UpdateChannel.Issue.peer
                }
                journal.phase = .committed
                try persist()
                guard process.isRunning else { throw UpdateChannel.Issue.peer }
                try recovery.remove(UpdateJournal.pending)
                try channel.send(UpdateMessage.proceed)
                releaseLocks()
            } catch {
                if process.hasExited {
                    await rollback()
                } else if process.verifies(journal.candidate, executable: journal.targetExecutable),
                          let app = NSRunningApplication(processIdentifier: process.pid) {
                    await stopFailedCandidate(app, process)
                } else { preserve() }
            }
        case .unready(let app, let process):
            await stopFailedCandidate(app, process)
        case .absent:
            journal.deliveryFailure = "candidate-absent"
            await rollback()
        case .unknown:
            journal.deliveryFailure = "candidate-unidentified"
            preserve()
        }
    }

    private func stopFailedCandidate(_ app: NSRunningApplication, _ process: UpdateProcessIdentity) async {
        guard process.verifies(journal.candidate, executable: journal.targetExecutable) || process.hasExited else {
            preserve()
            return
        }
        if !process.hasExited { _ = app.terminate() }
        guard await waitForExit(process, until: .now + .seconds(8)) else { preserve(); return }
        journal.candidateExitConfirmed = true
        await rollback()
    }

    private func rollback() async {
        do {
            try UpdateProcessIdentity.requireNoOtherInstances(journal.product, excluding: nil)
            journal.phase = .restoring
            try persist()
            try journal.exchange(restoring: true, fixture: fixture)
        } catch {
            preserve()
            return
        }
        await reopenOriginal(failure: .newLaunch)
    }

    private func reopenOriginal(failure: UpdateReceipt.Failure) async {
        do {
            try journal.verifyArrangement(false, fixture: fixture)
            journal.phase = .restoring
            try persist()
            let receipt = UpdateReceipt(transaction: journal.id, failure: failure, active: journal.original,
                                        version: journal.candidate.app.version, releaseTag: journal.releaseTag)
            try recovery.write(receipt, to: UpdateJournal.receipt)
            let opened = await launch(journal.original, role: "a", timeout: .seconds(30))
            journal.phase = .restored
            try persist()
            if case .ready(let channel, let process) = opened, process.isRunning {
                try releaseAndPermit(channel)
                return
            }
            try recovery.remove(UpdateJournal.pending)
            releaseLocks()
            showRecovery(restored: true)
        } catch {
            if (try? journal.verifyArrangement(false, fixture: fixture)) != nil {
                releaseLocks()
                showRecovery(restored: true)
            } else { preserve() }
        }
    }

    private func persist() throws {
        try staging.write(journal, to: UpdateJournal.intent)
        try recovery.write(journal, to: UpdateJournal.pending)
    }

    private func releaseAndPermit(_ channel: UpdateChannel) throws {
        try recovery.remove(UpdateJournal.pending)
        releaseLocks()
        try channel.send(UpdateMessage.proceed)
    }

    private func releaseLocks() {
        locks.forEach { close($0) }
        locks.removeAll()
    }

    private func preserve() {
        journal.phase = .preserved
        try? persist()
        releaseLocks()
        showRecovery(restored: false)
    }

    private func launch(_ signed: PreparedUpdate.SignedIdentity, role: String, timeout: Duration) async -> Outcome {
        guard !fault("launch-" + role), let listener else { return .absent }
        let deadline = ContinuousClock.now + timeout
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = ["--runlet-update-trial", journal.id.uuidString]
        configuration.activates = false
        configuration.createsNewApplicationInstance = true
        configuration.addsToRecentItems = false
        if let fixture {
            configuration.environment = ["CFFIXED_USER_HOME": fixture.root.appending(path: "home", directoryHint: .isDirectory).path]
            configuration.arguments += ["-appLanguage", journal.language]
        }
        let result = OpenResult()
        NSWorkspace.shared.openApplication(at: journal.target, configuration: configuration) { app, _ in
            let processID = app?.processIdentifier
            Task { @MainActor in
                result.processID = processID
                result.completed = true
            }
        }
        while !result.completed && ContinuousClock.now < deadline { try? await Task.sleep(for: .milliseconds(25)) }
        guard result.completed else { return .unknown }
        guard let processID = result.processID else {
            return (try? UpdateProcessIdentity.requireNoOtherInstances(journal.product, excluding: nil)) != nil ? .absent : .unknown
        }
        guard let application = NSRunningApplication(processIdentifier: processID) else {
            return kill(processID, 0) == -1 && errno == ESRCH ? .absent : .unknown
        }
        guard let process = UpdateProcessIdentity(application.processIdentifier) else {
            return application.isTerminated ? .absent : .unknown
        }
        guard process.executable == journal.targetExecutable else { return .unknown }
        journal.attemptedProcess = process
        if role == "b" { journal.candidateProcess = process }
        else { journal.reopenedProcess = process }
        do {
            try persist()
            let channel = try await listener.accept(until: deadline, peer: process)
            guard try await channel.receive(until: deadline) == UpdateMessage.ready,
                  process.verifies(signed, executable: journal.targetExecutable) else { return .unready(application, process) }
            try await Task.sleep(for: .milliseconds(250))
            return process.isRunning ? .ready(channel, process) : .unready(application, process)
        } catch UpdateChannel.Issue.deadline {
            if role == "b" { journal.deliveryFailure = process.isRunning ? "candidate-timeout" : "candidate-early-exit" }
            return .unready(application, process)
        } catch {
            if role == "b" { journal.deliveryFailure = process.isRunning ? "candidate-protocol" : "candidate-early-exit" }
            return .unready(application, process)
        }
    }

    @MainActor private final class OpenResult {
        var processID: pid_t?
        var completed = false
    }

    private func waitForExit(_ process: UpdateProcessIdentity, until deadline: ContinuousClock.Instant) async -> Bool {
        while !process.hasExited && ContinuousClock.now < deadline { try? await Task.sleep(for: .milliseconds(50)) }
        return process.hasExited
    }

    private func fault(_ name: String) -> Bool { UpdateJournal.fault(fixture, name) }

    private func showRecovery(restored: Bool) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        let translation = Bundle.main.url(forResource: journal.language, withExtension: "lproj").flatMap(Bundle.init(url:))
        func localized(_ key: String) -> String { translation?.localizedString(forKey: key, value: key, table: nil) ?? key }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = restored
            ? localized("The previous version was restored but could not open automatically.")
            : localized("Automatic update recovery could not be confirmed. The update files were preserved.")
        let location = restored ? journal.target : journal.stage
        alert.informativeText = location.path
        alert.window.title = localized("Update Recovery")
        alert.addButton(withTitle: localized("Dismiss"))
        alert.addButton(withTitle: localized("Show in Finder"))
        alert.addButton(withTitle: localized("View Release"))
        while true {
            switch alert.runModal() {
            case .alertSecondButtonReturn: NSWorkspace.shared.activateFileViewerSelecting([location])
            case .alertThirdButtonReturn: NSWorkspace.shared.open(journal.releaseURL)
            default: return
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
Task { @MainActor in
    do {
        let helper = try UpdateHelper(Array(CommandLine.arguments.dropFirst()))
        await helper.run()
        Darwin.exit(0)
    } catch {
        Darwin.exit(74)
    }
}
app.run()
