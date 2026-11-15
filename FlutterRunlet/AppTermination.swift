import AppKit

@MainActor
final class AppTermination: NSObject, NSApplicationDelegate {
    static private(set) weak var current: AppTermination?
    static let receivedUpdate = Notification.Name("FlutterRunlet.receivedUpdate")
    var session: SessionController?
    var language: AppLanguageSettings?
    var loginItem: LoginItemSettings?
    var launchActivationPolicy: NSApplication.ActivationPolicy = .regular
    private var reopenMainWindow: (() -> Void)?
    private var replying = false
    private var handoff: UpdateHandoff?
    private var authorizedUpdateExit = false
    private(set) var updateReceipt: UpdateReceipt?

    private var locale: Locale { language?.locale ?? .current }

    func applicationWillFinishLaunching(_ notification: Notification) {
        if session?.updateTrial != nil || session?.updateStartupBlocked == true {
            FlutterRunletApp.setActivationPolicy(.prohibited)
            return
        }
        FlutterRunletApp.setActivationPolicy(launchActivationPolicy)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.current = self
        guard let session else { return }
        if session.updateStartupBlocked {
            NSApp.terminate(nil)
            return
        }
        guard let trial = session.updateTrial else {
            readUpdateReceipt()
            return
        }
        Task {
            do {
                try await trial.awaitCommit()
                session.completeUpdateStartup()
                FlutterRunletApp.setActivationPolicy(launchActivationPolicy)
                if session.shouldPresentMainWindowOnLaunch { reopenMainWindow?() }
                readUpdateReceipt()
            } catch {
                NSApp.terminate(nil)
            }
        }
    }

    private func readUpdateReceipt() {
        guard UpdatePackageService.installsEnabled,
              let directory = try? UpdateDirectory(SessionController.recoveryNamespace, privateAccess: true),
              let receipt = try? directory.read(UpdateJournal.receipt, as: UpdateReceipt.self),
              let actual = try? UpdatePackageService.installationIdentity(at: Bundle.main.bundleURL,
                    productID: receipt.active.app.productID, fixture: IsolatedUpdateBuild.read()),
              actual == receipt.active else { return }
        do {
            let lease = try UpdateActivityLease(directory: directory.url, installing: true)
            guard try directory.read(UpdateJournal.receipt, as: UpdateReceipt.self)?.transaction == receipt.transaction else { return }
            try directory.remove(UpdateJournal.receipt)
            withExtendedLifetime(lease) {}
            updateReceipt = receipt
            NotificationCenter.default.post(name: Self.receivedUpdate, object: self)
        } catch { return }
    }

    func requestUpdateExit(_ handoff: UpdateHandoff) -> Bool {
        guard self.handoff == nil, !replying, session?.updateReserved == true, session?.canTerminate == true else { return false }
        authorizedUpdateExit = false
        self.handoff = handoff
        NSApp.terminate(nil)
        // If AppKit canceled before consulting the delegate, return control to the running app.
        if !authorizedUpdateExit { self.handoff = nil }
        return authorizedUpdateExit
    }

    func installMainWindowHandler(presentOnLaunch: Bool, open: @escaping () -> Void) {
        let firstAppearance = reopenMainWindow == nil
        reopenMainWindow = open
        guard firstAppearance, presentOnLaunch, session?.updateTrial == nil,
              session?.updateStartupBlocked != true else { return }
        // The menu bar scene can appear at login even when SwiftUI skips its default window.
        Task { @MainActor in
            reopenMainWindow?()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if session?.updateTrial != nil || session?.updateStartupBlocked == true { return false }
        guard let reopenMainWindow else { return true }
        reopenMainWindow()
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        guard session?.updateTrial == nil, session?.updateStartupBlocked != true else { return }
        loginItem?.refresh()
        session?.recheckInvalidFlutterSDK()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let session else { return .terminateNow }
        if session.updateTrial != nil || session.updateStartupBlocked { return .terminateNow }
        if session.updateReserved {
            guard let handoff, session.canTerminate, !session.hasPendingEnvironmentChecks,
                  handoff.authorizeExit() else { return .terminateCancel }
            authorizedUpdateExit = true
            return .terminateNow
        }
        guard !replying else { return .terminateLater }
        if session.canTerminate && !session.hasPendingEnvironmentChecks { return .terminateNow }
        guard session.isBusy || session.canTerminate else {
            showBlocked(session)
            return .terminateCancel
        }
        replying = true
        if session.isBusy && !confirmStoppingSession() {
            replying = false
            return .terminateCancel
        }
        session.beginFinishingTermination()
        Task {
            let completed = await session.finishForTermination()
            sender.reply(toApplicationShouldTerminate: completed)
            replying = false
            if !completed { showBlocked(session) }
        }
        return .terminateLater
    }

    private func confirmStoppingSession() -> Bool {
        let alert = NSAlert()
        alert.messageText = locale.appString("Stop the session and quit FlutterRunlet?")
        alert.informativeText = locale.appString("FlutterRunlet will wait for managed processes to exit and run the project’s recovery task.")
        alert.addButton(withTitle: locale.appString("Stop and Quit"))
        alert.addButton(withTitle: locale.appString("Cancel"))
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func showBlocked(_ session: SessionController) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = locale.appString("FlutterRunlet Cannot Quit Right Now")
        alert.informativeText = locale.appString(session.displayMessage ?? "Finish environment recovery in the main window first.")
        alert.addButton(withTitle: locale.appString("Dismiss"))
        alert.runModal()
    }
}
