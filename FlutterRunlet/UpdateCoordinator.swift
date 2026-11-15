import AppKit
import OSLog

@MainActor
final class UpdateCoordinator {
    struct Operations: Sendable {
        let check: @Sendable (String) async throws -> ReleaseCheckResult
        let availability: @Sendable (GitHubRelease) -> Result<UpdateDownload, UpdatePackageIssue>
        let prepare: @Sendable (UpdateDownload, RunningUpdateApp) async throws -> PreparedUpdate

        static let production = Self(
            check: { try await ReleaseClient().check(runningVersion: $0) },
            availability: { UpdatePackageService().availability(for: $0) },
            prepare: { try await UpdatePackageService().prepare($0, running: $1) }
        )
    }

    private weak var source: UpdatePresentationSource?
    private let operations: Operations
    private let runningApp: () -> RunningUpdateApp?
    private let openRelease: (URL) -> Void
    private var inFlight: Task<Void, Never>?
    private var releasePage: URL?
    private var offer: UpdateDownload?
    private(set) var prepared: PreparedUpdate?

    init(source: UpdatePresentationSource, operations: Operations = .production,
         runningApp: @escaping () -> RunningUpdateApp? = { RunningUpdateApp() },
         openRelease: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) }) {
        self.source = source
        self.operations = operations
        self.runningApp = runningApp
        self.openRelease = openRelease
    }

    deinit {
        inFlight?.cancel()
        try? prepared?.discard()
    }

    func perform(_ action: UpdatePresentationSource.Action) {
        guard let presentation = source?.presentation else { return }
        switch action {
        case .primary:
            switch presentation.status {
            case .idle, .current, .noRelease, .failed(.check):
                check()
            case .available, .failed(.download), .failed(.verification):
                prepare()
            case .unavailable(_, _, let canRetry):
                if canRetry { prepare() }
                else { check() }
            case .checking, .updating, .waiting, .ready, .failed(.replacement), .failed(.newLaunch):
                break
            }
        case .showRelease:
            if presentation.showsReleaseAction, let releasePage { openRelease(releasePage) }
        case .install, .later, .dismissRecovery, .showInFinder:
            break
        }
    }

    private func check() {
        guard inFlight == nil else { return }
        offer = nil
        releasePage = nil
        guard let running = runningApp() else { present(.failed(.check)); return }
        present(.checking)
        inFlight = Task { [weak self, operations] in
            defer { self?.inFlight = nil }
            do {
                let result = try await operations.check(running.version)
                try Task.checkCancellation()
                self?.apply(result)
            } catch is CancellationError {
                self?.present(.idle)
            } catch {
                self?.present(.failed(.check))
            }
        }
    }

    private func apply(_ result: ReleaseCheckResult) {
        switch result {
        case .current: present(.current)
        case .noRelease: present(.noRelease)
        case .newer(let release):
            releasePage = release.releasePage
            switch operations.availability(release) {
            case .success(let download):
                offer = download
                present(.available(release.tag))
            case .failure(let issue):
                present(.unavailable(version: release.tag, reason: issue, canRetry: false))
            }
        }
    }

    private func prepare() {
        guard inFlight == nil, let running = runningApp(), let offer else { return }
        present(.updating)
        inFlight = Task { [weak self, operations] in
            defer { self?.inFlight = nil }
            do {
                let candidate = try await operations.prepare(offer, running)
                guard let self, !Task.isCancelled else {
                    try candidate.discard()
                    return
                }
                self.prepared = candidate
                self.present(.ready)
            } catch is CancellationError {
                self?.present(.available(offer.tag))
            } catch {
                self?.showFailure(error, for: offer)
            }
        }
    }

    private func showFailure(_ error: Error, for offer: UpdateDownload) {
        let issue = error as? UpdatePackageIssue ?? .download
        switch issue {
        case .download:
            present(.failed(.download))
        case .digestMismatch, .invalidSidecar:
            present(.failed(.verification))
        case .releaseChanged, .mutableRelease, .publisherNotConfigured:
            self.offer = nil
            present(.unavailable(version: offer.tag, reason: issue, canRetry: false))
        default:
            present(.unavailable(version: offer.tag, reason: issue, canRetry: true))
        }
    }

    private func present(_ status: UpdatePresentation.Status) {
        let rotation: UpdatePresentation.Rotation = status == .checking || status == .updating
            ? .animated(.now) : .stationary
        source?.present(.init(status: status, rotation: rotation))
    }
}
