import Foundation
import Observation

struct UpdatePresentation: Equatable {
    enum Blocker: String, CaseIterable {
        case debugging, recoveryPending = "recovery-pending", recoveryFailed = "recovery-failed"
        case processUnconfirmed = "process-unconfirmed", recoveryUnreadable = "recovery-unreadable"

        var explanation: LocalizedStringResource {
            switch self {
            case .debugging: "Wait for the debug session to finish."
            case .recoveryPending: "Finish the pending environment recovery."
            case .recoveryFailed: "Retry the failed environment recovery."
            case .processUnconfirmed: "Wait until the managed process has exited."
            case .recoveryUnreadable: "The environment recovery record cannot be read."
            }
        }
    }

    enum Failure: Equatable {
        case check, download, verification, replacement, newLaunch

        var message: LocalizedStringResource {
            switch self {
            case .check: "Could not check for updates. Release information was unavailable."
            case .download: "Download failed. The update package could not be read."
            case .verification: "Verification failed. The package checksum did not match."
            case .replacement: "Replacement failed. The previous version was restored."
            case .newLaunch: "The new version could not open. The previous version was restored."
            }
        }
    }

    enum Rotation: Equatable {
        case stationary
        case animated(Date)
        case frozen(Double)

        func degrees(at date: Date) -> Double {
            switch self {
            case .stationary: 0
            case .frozen(let angle): angle
            case .animated(let start):
                (-360 * date.timeIntervalSince(start) / 0.8).truncatingRemainder(dividingBy: 360)
            }
        }
    }

    enum Status: Equatable {
        case idle, checking, current, noRelease
        case available(String), updating
        case unavailable(version: String, reason: UpdatePackageIssue, canRetry: Bool)
        case waiting(Blocker), ready
        case failed(Failure)
    }

    enum Prompt: Equatable {
        case confirm(version: String)
        case recovery(path: String)
    }

    var status: Status = .idle
    var rotation: Rotation = .stationary
    var displayedVersion: String?
    var prompt: Prompt?

    var primaryTitle: LocalizedStringResource {
        switch status {
        case .idle, .current, .noRelease: "Check for Updates"
        case .checking: "Checking…"
        case .available(let version): "Update to \(version)"
        case .unavailable(_, _, let canRetry): canRetry ? "Retry" : "Check for Updates"
        case .updating: "Updating…"
        case .waiting, .ready: "Continue Installation"
        case .failed: "Retry"
        }
    }

    var feedback: LocalizedStringResource {
        switch status {
        case .idle: "Check if there is a new version of FlutterRunlet"
        case .checking: "Checking…"
        case .current: "You’re up to date"
        case .noRelease: "No stable release is available"
        case .available(let version): "New version available: \(version)"
        case .unavailable(let version, let reason, _):
            "New version \(version) cannot be installed safely. \(reason.installExplanation)"
        case .updating: "Updating…"
        case .waiting(let blocker): "Update downloaded. \(blocker.explanation)"
        case .ready: "Update downloaded. You can continue installation."
        case .failed(let failure): failure.message
        }
    }

    var canPerformPrimary: Bool {
        guard prompt == nil else { return false }
        switch status {
        case .checking, .updating, .waiting: return false
        default: return true
        }
    }

    var showsReleaseAction: Bool {
        if case .unavailable = status { return true }
        if case .failed(let failure) = status { return failure != .check }
        return false
    }
}

@MainActor
@Observable
final class UpdatePresentationSource {
    enum Action { case primary, install, later, dismissRecovery, showRelease, showInFinder }

    private(set) var presentation: UpdatePresentation
    @ObservationIgnored private let action: (Action) -> Void

    init(presentation: UpdatePresentation = .init(), action: @escaping (Action) -> Void = { _ in }) {
        self.presentation = presentation
        self.action = action
    }

    func present(_ presentation: UpdatePresentation) {
        self.presentation = presentation
    }

    func perform(_ action: Action) {
        guard action != .primary || presentation.canPerformPrimary else { return }
        self.action(action)
    }
}

private extension UpdatePackageIssue {
    var installExplanation: LocalizedStringResource {
        switch self {
        case .mutableRelease: "The release has not been locked."
        case .publisherNotConfigured: "The publisher’s signing identity is not configured."
        case .missingAsset: "A universal macOS package is missing."
        case .ambiguousAsset: "The release has conflicting macOS packages."
        case .assetTooLarge: "The package exceeds the size limit."
        case .missingDigest: "The package has no valid SHA-256 checksum."
        case .sizeMismatch: "The package size does not match the release."
        case .releaseChanged: "The release or its package changed."
        case .invalidImage, .detachFailed: "The disk image could not be safely inspected."
        case .invalidBundle, .invalidSignature: "The app’s identity or signature could not be verified."
        case .unsupportedArchitecture: "The package does not support both Mac architectures."
        case .versionMismatch: "The signed version does not match the release tag."
        case .notNewer: "The signed version is not newer than this app."
        case .systemAssessment: "macOS did not approve the package for distribution."
        case .staging: "The package could not be stored."
        case .invalidRelease, .invalidAsset, .download, .digestMismatch, .invalidSidecar:
            "The package could not be verified."
        }
    }
}
