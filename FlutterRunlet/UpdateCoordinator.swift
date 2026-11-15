import AppKit
import OSLog

@MainActor
final class UpdateCoordinator {
    struct Operations: Sendable {
        let check: @Sendable (String) async throws -> ReleaseCheckResult
        let availability: @Sendable (GitHubRelease) -> Result<UpdateDownload, UpdatePackageIssue>
        let prepare: @Sendable (UpdateDownload, RunningUpdateApp) async throws -> PreparedUpdate

        static let production = Self(
            check: { try await UpdatePackageService().check(runningVersion: $0) },
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
    private var gateWatcher: Task<Void, Never>?
    private var requestedConfirmation = false
    private var didAutoPrompt = false
    private var receiptObserver: Task<Void, Never>?

    init(source: UpdatePresentationSource, operations: Operations = .production,
         runningApp: @escaping () -> RunningUpdateApp? = { RunningUpdateApp() },
         openRelease: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) }) {
        self.source = source
        self.operations = operations
        self.runningApp = runningApp
        self.openRelease = openRelease
        if UpdatePackageService.installsEnabled {
            receiptObserver = Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(named: AppTermination.receivedUpdate) {
                    self?.applyReceipt()
                }
            }
        }
    }

    deinit {
        inFlight?.cancel()
        gateWatcher?.cancel()
        receiptObserver?.cancel()
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
            case .ready:
                if prepared != nil { requestConfirmation() }
            case .failed(.replacement), .failed(.newLaunch):
                check()
            case .checking, .updating, .waiting:
                break
            }
        case .showRelease:
            if presentation.showsReleaseAction, let releasePage { openRelease(releasePage) }
        case .install:
            install()
        case .later:
            if requestedConfirmation {
                requestedConfirmation = false
                refreshInstallGate()
            }
        case .dismissRecovery, .showInFinder:
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
                self.didAutoPrompt = false
                if UpdatePackageService.installsEnabled {
                    self.refreshInstallGate()
                    self.watchInstallGate()
                } else {
                    self.present(.ready)
                }
            } catch is CancellationError {
                self?.present(.available(offer.tag))
            } catch {
                self?.showFailure(error, for: offer)
            }
        }
    }

    private func requestConfirmation() {
        guard inFlight == nil, UpdatePackageService.installsEnabled else { return }
        requestedConfirmation = true
        refreshInstallGate()
    }

    private func watchInstallGate() {
        gateWatcher?.cancel()
        gateWatcher = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled else { return }
                if self.inFlight == nil { self.refreshInstallGate() }
            }
        }
    }

    private func refreshInstallGate() {
        guard let prepared, UpdatePackageService.installsEnabled else { return }
        if let blocker = AppTermination.current?.session?.updateBlocker {
            requestedConfirmation = false
            present(.waiting(blocker))
            return
        }
        if !didAutoPrompt && AppTermination.current?.session != nil {
            didAutoPrompt = true
            requestedConfirmation = true
        }
        let prompt: UpdatePresentation.Prompt? = requestedConfirmation ? .confirm(version: prepared.download.tag) : nil
        let next = UpdatePresentation(status: .ready, prompt: prompt)
        if source?.presentation != next { source?.present(next) }
    }

    private func install() {
        guard inFlight == nil, requestedConfirmation, let prepared,
              let termination = AppTermination.current, let session = termination.session else { return }
        requestedConfirmation = false
        if let blocker = session.updateBlocker {
            present(.waiting(blocker))
            return
        }
        present(.ready)
        inFlight = Task { [weak self, weak termination] in
            defer { self?.inFlight = nil }
            let reservation: UpdateReservation
            do {
                reservation = try await session.reserveUpdate(productID: prepared.runningApp.productID)
            } catch {
                self?.gateWatcher?.cancel()
                self?.present(.waiting(session.updateBlocker ?? .processUnconfirmed))
                self?.watchInstallGate()
                return
            }
            let language = termination?.language?.locale.identifier ?? Locale.current.identifier
            do {
                let handoff = try await Task.detached {
                    try await UpdateHandoff.prepare(prepared, reservation: reservation, language: language)
                }.value
                do {
                    try prepared.discard()
                } catch {
                    handoff.abandon()
                    throw error
                }
                if termination?.requestUpdateExit(handoff) != true {
                    handoff.abandon()
                    throw UpdateChannel.Issue.closed
                }
            } catch {
                session.releaseUpdateReservation()
                self?.gateWatcher?.cancel()
                self?.prepared = nil
                try? prepared.discard()
                self?.present(.unavailable(version: prepared.download.tag, reason: .staging, canRetry: true))
            }
        }
    }

    private func applyReceipt() {
        guard let receipt = AppTermination.current?.updateReceipt else { return }
        releasePage = UpdateRepository.releases.appending(path: "tag/\(receipt.releaseTag)")
        present(.failed(receipt.failure == .replacement ? .replacement : .newLaunch))
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
