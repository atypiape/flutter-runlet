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
              record.authorizingProcess.pid == getppid(), record.stageIdentity == staging.identity,
              record.recoveryIdentity == recovery.identity, record.stage.path == staging.url.path,
              fixture == nil || recovery.url.path == fixture?.recovery.path,
              try UpdatePackageService.copiedHelperHashes(at: record.copiedHelper, productID: record.product, fixture: fixture)
                == record.original.helperCodeHashes else { throw UpdateChannel.Issue.peer }
        let active = try record.currentArrangement(fixture: fixture) ? record.candidate : record.original
        guard record.authorizingProcess.verifies(active, executable: record.targetExecutable) else {
            throw UpdateChannel.Issue.peer
        }
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
            guard parent.matchesPeer(journal.authorizingProcess) else { return }
            if journal.reentryProcess == nil {
                try journal.verifyArrangement(false, fixture: fixture)
            } else {
                _ = try journal.currentArrangement(fixture: fixture)
                guard unlink(journal.socket.path) == 0 || errno == ENOENT else { return }
            }
            listener = try UpdateChannel.listen(journal.socket)
            guard let helper = UpdateProcessIdentity(getpid()) else { return }
            journal.helperProcess = helper
            try staging.write(journal, to: UpdateJournal.intent)
            if journal.phase == .prepared, journal.reentryProcess == nil, fault("delay-pending-publish") {
                try await Task.sleep(for: .seconds(10))
            }
            try recovery.write(journal, to: UpdateJournal.pending)
            if fault("helper-no-ready"), let fixture {
                try UpdateDirectory(fixture.root, privateAccess: true).write(journal, to: "helper-refused.json")
                if fault("observe-reservation") { try await Task.sleep(for: .seconds(4)) }
                return
            }
            try parent.send(UpdateMessage.ready)
            guard try await parent.receive(until: .now + .seconds(20)) == UpdateMessage.proceed,
                  await waitForExit(journal.authorizingProcess, until: .now + .seconds(12)) else { return }
        } catch {
            return
        }
        if journal.reentryProcess == nil {
            await replaceAndLaunch()
        } else {
            await recoverInterrupted()
        }
    }

    private func recoverInterrupted() async {
        do {
            try UpdateProcessIdentity.requireNoOtherInstances(journal.product, excluding: nil)
            let exchanged = try journal.currentArrangement(fixture: fixture)
            switch journal.phase {
            case .committed:
                guard exchanged else { throw UpdateDirectory.Issue.identity }
                if fault("interrupt-committed-reentry") { Darwin.exit(95) }
                await launchCandidate()
            case .restored:
                guard !exchanged else { throw UpdateDirectory.Issue.identity }
                await reopenOriginal()
            default:
                if exchanged {
                    await rollback()
                } else {
                    await reopenOriginal(failure: journal.rollbackFailure ?? (journal.phase == .restoring ? .newLaunch : .replacement))
                }
            }
        } catch { preserve() }
    }

    private func replaceAndLaunch() async {
        do {
            try await mutationBarrier("compatibility")
            try UpdateProcessIdentity.requireNoOtherInstances(journal.product, excluding: nil)
            try recovery.verify()
            let contents = try FileManager.default.contentsOfDirectory(atPath: recovery.url.path)
            guard !contents.contains(where: { $0.hasSuffix(".risk") || $0.hasPrefix("update-worker-") }),
                  !fault("exchange-before") else { throw UpdateDirectory.Issue.exchange }
            journal.phase = .waitingForNew
            try persist()
            interrupt("before-exchange")
            try await mutationBarrier("before-swap")
            try journal.exchange(restoring: false, fixture: fixture)
            interrupt("after-exchange")
            try await mutationBarrier("after-swap")
            try journal.verifyArrangement(true, fixture: fixture)
        } catch {
            if (try? journal.verifyArrangement(false, fixture: fixture)) != nil {
                await reopenOriginal(failure: .replacement)
            } else if (try? journal.verifyArrangement(true, fixture: fixture)) != nil {
                await rollback()
            } else {
                preserve()
            }
            return
        }
        await launchCandidate()
    }

    private func launchCandidate() async {
        switch await launch(journal.candidate, role: "b", timeout: .seconds(8)) {
        case .ready(let channel, let process):
            do { try journal.verifyArrangement(true, fixture: fixture) } catch {
                channel.shutdown()
                preserve()
                return
            }
            do {
                try channel.send(UpdateMessage.verify)
                guard try await channel.receive(until: .now + .seconds(3)) == UpdateMessage.verified,
                      process.verifies(journal.candidate, executable: journal.targetExecutable) else {
                    throw UpdateChannel.Issue.peer
                }
            } catch {
                channel.shutdown()
                journal.deliveryFailure = journal.isTerminal ? "candidate-failed-relaunch" : "candidate-exited-before-commit"
                await stopFailedCandidate(NSRunningApplication(processIdentifier: process.pid), process)
                return
            }
            journal.phase = .committed
            do { try persist() } catch { preserve(); return }
            interrupt("after-commit")
            _ = await deliverStartup(channel, process: process, role: "b")
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

    private func stopFailedCandidate(_ app: NSRunningApplication?, _ process: UpdateProcessIdentity) async {
        guard await stopTrial(app, process, signed: journal.candidate) else { preserve(); return }
        journal.candidateExitConfirmed = true
        await rollback()
    }

    private func rollback() async {
        do {
            try UpdateProcessIdentity.requireNoOtherInstances(journal.product, excluding: nil)
            journal.phase = .restoring
            journal.rollbackFailure = .newLaunch
            try persist()
            try journal.exchange(restoring: true, fixture: fixture)
        } catch {
            preserve()
            return
        }
        await reopenOriginal(failure: .newLaunch)
    }

    private func reopenOriginal(failure: UpdateReceipt.Failure? = nil) async {
        do {
            try journal.verifyArrangement(false, fixture: fixture)
            let previous = try recovery.read(UpdateJournal.receipt, as: UpdateReceipt.self)
            let failure = failure ?? journal.rollbackFailure
                ?? (previous?.transaction == journal.id ? previous?.failure : nil) ?? .newLaunch
            journal.rollbackFailure = failure
            let receipt = UpdateReceipt(transaction: journal.id, failure: failure, active: journal.original,
                                        version: journal.candidate.app.version, releaseTag: journal.releaseTag)
            if previous?.transaction != journal.id { try recovery.write(receipt, to: UpdateJournal.receipt) }
            journal.phase = .restored
            journal.originalExitConfirmed = nil
            try persist()
            let start = ContinuousClock.now
            let opened = await launch(journal.original, role: "a", timeout: .seconds(30))
            let elapsed = start.duration(to: .now).components
            journal.originalWaitMilliseconds = elapsed.seconds * 1_000 + elapsed.attoseconds / 1_000_000_000_000_000
            if case .unready(let app, let process) = opened {
                journal.originalExitConfirmed = await stopTrial(app, process, signed: journal.original)
            }
            try persist()
            if case .ready(let channel, let process) = opened {
                try journal.verifyArrangement(false, fixture: fixture)
                if await deliverStartup(channel, process: process, role: "a") { return }
            }
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
        // Bootstraps read pending first. Publish the decision there before its staged copy.
        try recovery.write(journal, to: UpdateJournal.pending)
        try staging.write(journal, to: UpdateJournal.intent)
    }

    private func deliverStartup(_ channel: UpdateChannel, process: UpdateProcessIdentity, role: String) async -> Bool {
        defer { channel.shutdown() }
        releaseLocks()
        if fault("interrupt-before-proceed-" + role) { Darwin.exit(95) }
        do {
            guard process.isRunning else { return false }
            try channel.send(UpdateMessage.proceed)
            if fault("interrupt-after-proceed-" + role) { Darwin.exit(95) }
            if try await channel.receive(until: .now + .seconds(8)) == UpdateMessage.acknowledged { return true }
        } catch {}
        // The app may have completed the disk handoff just before its socket closed.
        guard let recorded = try? staging.read(UpdateJournal.intent, as: UpdateJournal.self),
              recorded.id == journal.id, recorded.acknowledgedProcess == process else { return false }
        do { return try recovery.read(UpdateJournal.pending, as: UpdateJournal.self)?.id != journal.id }
        catch { return false }
    }

    private func releaseLocks() {
        locks.forEach { close($0) }
        locks.removeAll()
    }

    private func preserve() {
        if !journal.isTerminal { journal.phase = .preserved }
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
        journal.acknowledgedProcess = nil
        if role == "b" { journal.candidateProcess = process }
        else { journal.reopenedProcess = process }
        do { try persist() } catch { return .unknown }
        do {
            let channel = try await listener.accept(until: deadline, peer: process)
            guard try await channel.receive(until: deadline) == UpdateMessage.ready else {
                if role == "b" { journal.deliveryFailure = "candidate-protocol" }
                return .unready(application, process)
            }
            guard process.verifies(signed, executable: journal.targetExecutable) else {
                if role == "b" { journal.deliveryFailure = "candidate-identity" }
                return .unready(application, process)
            }
            try await Task.sleep(for: .milliseconds(250))
            return process.isRunning && ContinuousClock.now < deadline
                ? .ready(channel, process) : .unready(application, process)
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

    private func stopTrial(_ app: NSRunningApplication?, _ process: UpdateProcessIdentity,
                           signed: PreparedUpdate.SignedIdentity) async -> Bool {
        // Code identity can become unreadable during exit. Only signal a verified trial.
        if let app, process.verifies(signed, executable: journal.targetExecutable) { _ = app.terminate() }
        return await waitForExit(process, until: .now + .seconds(8))
    }

    private func waitForExit(_ process: UpdateProcessIdentity, until deadline: ContinuousClock.Instant) async -> Bool {
        while !process.hasExited && ContinuousClock.now < deadline { try? await Task.sleep(for: .milliseconds(50)) }
        return process.hasExited
    }

    private func fault(_ name: String) -> Bool { UpdateJournal.fault(fixture, name) }

    private func interrupt(_ point: String) {
        if journal.reentryProcess == nil, fault("interrupt-" + point) { Darwin.exit(95) }
    }

    private func mutationBarrier(_ point: String) async throws {
        #if PHASE07_UPDATE
        guard let fixture, fault("pause-" + point) else { return }
        let root = try UpdateDirectory(fixture.root, privateAccess: true)
        try root.write(journal.id, to: "mutation-ready.json")
        let deadline = ContinuousClock.now + .seconds(12)
        while ContinuousClock.now < deadline {
            if try root.read("mutation-done.json", as: UUID.self) == journal.id { return }
            try await Task.sleep(for: .milliseconds(25))
        }
        throw UpdateChannel.Issue.deadline
        #endif
    }

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
