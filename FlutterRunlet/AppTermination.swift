import AppKit

@MainActor
final class AppTermination: NSObject, NSApplicationDelegate {
    var session: SessionController?
    var language: AppLanguageSettings?
    var loginItem: LoginItemSettings?
    var launchActivationPolicy: NSApplication.ActivationPolicy = .regular
    private var reopenMainWindow: (() -> Void)?
    private var replying = false

    private var locale: Locale { language?.locale ?? .current }

    func applicationWillFinishLaunching(_ notification: Notification) {
        FlutterRunletApp.setActivationPolicy(launchActivationPolicy)
    }

    func installMainWindowHandler(presentOnLaunch: Bool, open: @escaping () -> Void) {
        let firstAppearance = reopenMainWindow == nil
        reopenMainWindow = open
        guard firstAppearance, presentOnLaunch else { return }
        // The menu bar scene can appear at login even when SwiftUI skips its default window.
        Task { @MainActor in
            reopenMainWindow?()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard let reopenMainWindow else { return true }
        reopenMainWindow()
        return false
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        loginItem?.refresh()
        session?.recheckInvalidFlutterSDK()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let session else { return .terminateNow }
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
