import AppKit
import SwiftUI

struct MainWindowView: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openSettings: (() -> Void)?
    var openFlutterSettings: (() -> Void)? = nil

    @State private var isLogExpanded = true

    private var palette: RunletAppearance { RunletAppearance(scheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                SessionBrand()
                    .padding(.leading, 59)
                Spacer(minLength: 12)
                SessionStatusLabel(session: session, hasDemo: presentation.selection != nil)
                SessionSettingsButton(open: openSettings)
            }
            .padding(.horizontal, 19)
            .frame(height: 47)
            .background(palette.toolbar)
            palette.divider.frame(height: 1)
            VStack(alignment: .leading, spacing: 13) {
                ProjectControls(session: session, demoName: presentation.selection?.project)
                HStack(spacing: 12) {
                    RunConfigurationControls(session: session, demoConfiguration: presentation.selection?.configuration,
                                             runDemo: run, source: .mainWindow)
                    DebugControls(session: session)
                        .frame(idealWidth: 260, maxWidth: 260)
                }
                HStack(alignment: .top, spacing: 12) {
                    DeviceSelectionControls(session: session, demoDevice: presentation.selection?.device)
                    BrowserControls(session: session)
                        .frame(idealWidth: 260, maxWidth: 260)
                }
                sessionDetails.layoutPriority(1)
                logs
                if !isLogExpanded { Spacer(minLength: 0) }
            }
            .padding(.horizontal, 21)
            .padding(.top, 16)
            .padding(.bottom, 17)
        }
        .font(.system(size: 12))
        .foregroundStyle(palette.primary)
        .background(palette.window)
        .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(palette.border).allowsHitTesting(false) }
        .clipShape(.rect(cornerRadius: 14))
        .ignoresSafeArea(.container, edges: .top)
        .focusEffectDisabled()
    }

    private var sessionDetails: some View {
        Group {
            if let session, session.status == .recoveryFailed {
                recoveryFailureDetails(session)
            } else {
                regularSessionDetails
            }
        }
    }

    private var isRestoring: Bool { session?.status == .restoringEnvironment }

    private var regularSessionDetails: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let selection = presentation.selection {
                Text("Debug Session").font(RunletType.localized(locale, size: 13, medium: true))
                sessionCaption(verbatim: "\(selection.configuration) · \(selection.device)")
            } else if let session, isRestoring {
                Text("Flutter Has Exited").font(RunletType.localized(locale, size: 13, medium: true))
                if let task = session.activeRecoveryTaskLabel {
                    Text("Running post-debug task \(task).")
                        .font(RunletType.localized(locale, size: 11)).foregroundStyle(palette.secondary)
                } else {
                    Text(session.status.title).font(RunletType.localized(locale, size: 11)).foregroundStyle(palette.secondary)
                }
            } else if let session, let launch = session.activeLaunch {
                Text("Debug Session").font(RunletType.localized(locale, size: 13, medium: true))
                sessionCaption(verbatim: "\(launch.configurationName) · \(launch.device.name) (\(locale.appString(DeviceChoice(device: launch.device, availability: .online).kind.title)))")
                    .accessibilityValue(Text(session.vmConnected ? "VM Service Connected" : "VM Service Disconnected"))
                    .help(Text(session.vmConnected ? "VM Service Connected" : "VM Service Disconnected"))
            } else {
                Text("Debug Not Started").font(RunletType.localized(locale, size: 13, medium: true))
                Text("Choose a launch configuration and device to run.")
                    .font(RunletType.localized(locale, size: 11))
                    .foregroundStyle(palette.secondary)
            }
            if let session {
                if !isRestoring, let issue = session.displayMessage, session.recoveryMessage == nil,
                   locale.appString(issue) != locale.appString("Select a debug device") {
                    Text(session.configurationIsStale && !session.choices.isEmpty ? "Configuration Out of Date · \(issue)" : issue)
                        .foregroundStyle(palette.secondary)
                }
                if !isRestoring { RecoveryDetails(session: session) }
                if session.sdkIssue != nil, let openFlutterSettings {
                    Button("Open Flutter Settings", action: openFlutterSettings)
                }
                if let issue = session.taskIssue, issue != session.displayMessage {
                    Text(issue).foregroundStyle(palette.secondary)
                }
            }
            SessionFeedbackView(session: session)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 55, alignment: .leading)
        .background(palette.toolbar, in: .rect(cornerRadius: 7))
    }

    private func sessionCaption(verbatim caption: String) -> some View {
        Text(verbatim: caption)
            .font(RunletType.localized(locale, size: 11))
            .foregroundStyle(palette.secondary)
            .lineLimit(2)
            .help(caption)
    }

    private func recoveryFailureDetails(_ session: SessionController) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.recoveryFailure?.message ?? session.recoveryMessage ?? session.status.title)
                    .font(RunletType.localized(locale, size: 12, medium: true))
                    .frame(minHeight: 19, alignment: .leading)
                    .foregroundStyle(palette.error)
                if session.canRunAfterRecovery {
                    Text(RecoveryRetryButton.runHint)
                } else if let blocker = session.recoveryRunBlocker {
                    Text(blocker)
                }
                if session.recoveryAction == .openProject {
                    RecoveryDetails(session: session, showMessage: false)
                }
            }
            .font(RunletType.localized(locale, size: 11))
            .foregroundStyle(palette.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            RecoveryRetryButton(session: session)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 59)
        .background(palette.errorSurface, in: .rect(cornerRadius: 7))
    }

    private var logs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Text("Run Logs").font(RunletType.localized(locale, size: 12, medium: true))
                Spacer(minLength: 0)
                logButton("Copy Logs", icon: "Copy", action: { session?.copyLogs() })
                    .disabled(session?.logs.isEmpty != false)
                logButton("Clear Logs", icon: "Trash", action: { session?.clearLogs() })
                    .disabled(session?.logs.isEmpty != false)
                logButton(isLogExpanded ? Self.collapseLogsTitle : Self.expandLogsTitle, icon: "Collapse",
                          rotation: isLogExpanded ? 0 : -90, action: { isLogExpanded.toggle() })
            }
            .padding(.horizontal, 11)
            .frame(height: 38)
            .background(palette.toolbar)
            if isLogExpanded {
                if let session, !session.logs.isEmpty {
                    SessionLogView(contents: session.logs, trimmedUTF16: session.logTrimmedUTF16)
                        .id(session.logGeneration)
                        .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
                } else {
                    Text(verbatim: logContents)
                        .font(RunletType.localized(locale, size: 12))
                        .foregroundStyle(palette.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .frame(minHeight: 96)
                }
            }
        }
        .background(palette.console)
        .clipShape(.rect(cornerRadius: 8))
        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(palette.border).allowsHitTesting(false) }
    }

    private func logButton(_ title: LocalizedStringResource, icon: String, rotation: Double = 0,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RunletIcon(icon, size: 15)
                .rotationEffect(.degrees(rotation))
                .foregroundStyle(palette.secondary)
                .frame(width: 25, height: 25)
        }
        .buttonStyle(RunletButtonStyle(radius: 5, disabledOpacity: 1))
        .accessibilityLabel(Text(title))
        .help(Text(title))
    }

    static let collapseLogsTitle: LocalizedStringResource = "Collapse Logs"
    static let expandLogsTitle: LocalizedStringResource = "Expand Logs"

    private var logContents: String {
        if let session, !session.logs.isEmpty { return session.logs }
        if session?.didClearLogs == true { return locale.appString("Logs cleared. New output will appear here.") }
        return locale.appString("Flutter output will appear here after launch.")
    }
}

struct DeviceSelectionControls: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    @State private var isShowing = false

    let session: SessionController?
    let demoDevice: String?

    private var palette: RunletAppearance { RunletAppearance(scheme) }

    var body: some View {
        let device = session?.selectedDeviceChoice
        let canInspect = session?.usesFlutterToolchain == true && session?.project != nil
        Button {
            isShowing.toggle()
        } label: {
            HStack(spacing: 6) {
                RunletIcon("Device", size: 14).foregroundStyle(palette.secondary)
                if let device {
                    Text(verbatim: "\(device.name) (\(locale.appString(device.kind.title)))")
                } else if let demoDevice {
                    Text(verbatim: demoDevice)
                } else {
                    Text("Select a debug device").foregroundStyle(palette.secondary)
                }
                Spacer(minLength: 4)
                RunletIcon("DeviceArrow", size: 13).foregroundStyle(palette.secondary)
            }
            .font(RunletType.localized(locale, size: 12))
            .lineLimit(1)
            .padding(.horizontal, 9)
            .frame(height: 32)
        }
        .buttonStyle(RunletButtonStyle(surface: .outlinedField))
        .accessibilityLabel("Device for Next Run")
        .accessibilityValue(summary(device))
        .help(summary(device))
        .disabled(!canInspect && demoDevice == nil)
        .contextMenu {
            if let device { Text(verbatim: summary(device)) }
        }
        .popover(isPresented: $isShowing, arrowEdge: .bottom) {
            if let session { choices(for: session).environment(\.locale, locale) }
        }
    }

    private func choices(for session: SessionController) -> some View {
        RunletPopup(title: "Select Device", close: { isShowing = false }) {
            Text("The selected device is used for the next run.")
                .padding(.horizontal, 5)
                .font(RunletType.localized(locale, size: 11))
                .foregroundStyle(palette.secondary)
            if session.isBusy {
                Text("Showing the last device scan.").foregroundStyle(palette.secondary)
            }
            if session.isRefreshingDevices || session.isStartingSimulator {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(session.isStartingSimulator ? "Starting Simulator" : "Refreshing Devices")
                }
            }
            if let issue = session.deviceIssue ?? session.sdkIssue ?? session.simulatorIssue {
                Text(issue).foregroundStyle(palette.secondary)
            }
            if session.deviceChoices.isEmpty, !session.isRefreshingDevices {
                Text("No debug devices found. Connect a device or start a simulator, then refresh devices.")
                    .foregroundStyle(palette.secondary)
            }
            if !session.deviceChoices.isEmpty {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(session.deviceChoices) { device in
                            Button {
                                guard session.canSelectNextDevice else { return }
                                session.selectDevice(device.id)
                                isShowing = false
                            } label: {
                                deviceRow(device)
                            }
                            .buttonStyle(RunletButtonStyle(surface: .field, radius: 5))
                            .accessibilityLabel(summary(device))
                            .accessibilityAddTraits(device.id == session.selectedDeviceID ? .isSelected : [])
                            .help(summary(device))
                            .disabled(!session.canSelectNextDevice)
                        }
                    }
                }
                .frame(idealHeight: min(CGFloat(session.deviceChoices.count) * 37 - 5, 224), maxHeight: 224)
                .fixedSize(horizontal: false, vertical: true)
            }
            HStack {
                Button("Refresh Devices", systemImage: "arrow.clockwise", action: session.refreshDevices)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Refresh Devices")
                    .disabled(!session.canRefreshDevices || session.isRefreshingDevices || session.isStartingSimulator)
                Spacer()
                if !session.simulators.isEmpty || !session.androidEmulators.isEmpty {
                    Menu("Start Simulator", systemImage: "iphone") {
                        ForEach(session.androidEmulators) { emulator in
                            Button { session.startAndroidEmulator(emulator.id) } label: {
                                Text(verbatim: "\(emulator.name) (Android)")
                            }
                        }
                        ForEach(session.simulators) { simulator in
                            Button {
                                session.startSimulator(simulator.id)
                            } label: {
                                Text(verbatim: simulator.name)
                            }
                        }
                    }
                    .disabled(!session.canStartSimulator)
                }
            }
            .padding(.horizontal, 5)
        }
    }

    private func deviceRow(_ device: DeviceChoice) -> some View {
        HStack(spacing: 8) {
            RunletIcon("Device", size: 14).foregroundStyle(palette.secondary)
            Text(verbatim: device.name).fontWeight(.medium)
            Text(device.kind.title)
                .font(RunletType.localized(locale, size: 11))
                .foregroundStyle(palette.secondary)
            Spacer(minLength: 6)
            availabilityDot(device.availability)
        }
        .lineLimit(1)
        .padding(.horizontal, 7)
        .frame(height: 32)
    }

    private func summary(_ device: DeviceChoice?) -> String {
        guard let device else { return locale.appString("Select a debug device") }
        return [device.name, locale.appString(device.kind.title), locale.appString(availabilityTitle(device.availability))]
            .joined(separator: " · ")
    }

    private func availabilityTitle(_ availability: DeviceChoice.Availability) -> LocalizedStringResource {
        switch availability {
        case .online: "Online"
        case .offline: "Offline"
        case .unknown: "Unknown"
        }
    }

    private func availabilityDot(_ availability: DeviceChoice.Availability) -> some View {
        let color: Color = switch availability {
        case .online: palette.success
        case .offline: palette.error
        case .unknown: palette.muted
        }
        return Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }
}

struct RecoveryDetails: View {
    let session: SessionController
    var showMessage = true
    var showRetry = true

    var body: some View {
        if showMessage, let message = session.recoveryMessage {
            Text(message)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        if let record = session.recovery, let action = session.recoveryAction, showRetry || action != .retry {
            Text(verbatim: "\(record.projectPath) · \(record.taskLabel)")
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .help("\(record.projectPath) · \(record.taskLabel)")
            Button(action: session.performRecoveryAction) {
                Text(action.title)
            }
            .disabled(!session.canPerformRecoveryAction)
        }
    }
}

struct RecoveryRetryButton: View {
    @Environment(\.colorScheme) private var scheme
    let session: SessionController
    static let runHint: LocalizedStringResource = "Click Run to try recovery and start debugging"

    var body: some View {
        if session.status == .recoveryFailed, session.recoveryAction == .retry {
            Button(action: session.retryRecovery) {
                RunletIcon("Recovery", size: 15)
                    .foregroundStyle(RunletAppearance(scheme).accent)
                    .frame(width: 24, height: 24)
            }
                .buttonStyle(RunletButtonStyle())
                .accessibilityLabel("Retry Recovery")
                .help("Retry Recovery")
                .disabled(!session.canPerformRecoveryAction)
        }
    }
}

struct SessionBrand: View {
    var body: some View {
        HStack(spacing: 7) {
            RunletIcon("Glyph", size: 21)
            Text("FlutterRunlet").font(.system(size: 14, weight: .semibold))
        }
        .fixedSize()
    }
}

private struct SessionLogView: NSViewRepresentable {
    let contents: String
    let trimmedUTF16: Int

    func makeNSView(context: Context) -> SessionLogScrollView {
        SessionLogScrollView()
    }

    func updateNSView(_ scrollView: SessionLogScrollView, context: Context) {
        scrollView.setLogAccessibilityLabel(context.environment.locale.appString("Run Logs"))
        scrollView.scheduleUpdate(contents, trimmedUTF16: trimmedUTF16)
    }
}

final class SessionLogScrollView: NSScrollView {
    private struct ReadingAnchor {
        let character: Int
        let offset: CGPoint
    }

    private static let logColor = NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
            return NSColor(srgbRed: 240 / 255, green: 245 / 255, blue: 251 / 255, alpha: 1)
        }
        return NSColor(srgbRed: 25 / 255, green: 38 / 255, blue: 56 / 255, alpha: 1)
    }

    private let logText = NSTextView(frame: .zero)
    private let logFont = RunletType.logFont()
    private let logParagraph: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 18
        style.maximumLineHeight = 18
        return style.copy() as? NSParagraphStyle ?? .default
    }()
    private var trimmedUTF16 = 0
    private var lastUpdate: ContinuousClock.Instant?
    private var pendingUpdate: (contents: String, trimmedUTF16: Int)?
    private var updateTask: Task<Void, Never>?

    init() {
        super.init(frame: .zero)
        drawsBackground = false
        hasHorizontalScroller = true
        hasVerticalScroller = true
        autohidesScrollers = true
        logText.drawsBackground = false
        logText.isEditable = false
        logText.isSelectable = true
        logText.isRichText = false
        logText.font = logFont
        logText.textColor = Self.logColor
        logText.defaultParagraphStyle = logParagraph
        logText.textContainerInset = NSSize(width: 7, height: 8)
        logText.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        logText.textContainer?.containerSize = logText.maxSize
        logText.textContainer?.widthTracksTextView = false
        documentView = logText
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setLogAccessibilityLabel(_ label: String) {
        logText.setAccessibilityLabel(label)
    }

    override func layout() {
        let visible = documentVisibleRect
        let follow = followsBottom(visible)
        super.layout()
        sizeDocument(origin: visible.origin, follow: follow)
    }

    func scheduleUpdate(_ contents: String, trimmedUTF16: Int) {
        pendingUpdate = (contents, trimmedUTF16)
        guard updateTask == nil else { return }
        let now = ContinuousClock.now
        guard let deadline = lastUpdate?.advanced(by: .milliseconds(100)), now < deadline else {
            applyPendingUpdate()
            return
        }
        updateTask = Task { [weak self] in
            try? await ContinuousClock().sleep(until: deadline)
            self?.applyPendingUpdate()
        }
    }

    private func applyPendingUpdate() {
        updateTask = nil
        guard let update = pendingUpdate else { return }
        pendingUpdate = nil
        lastUpdate = .now
        show(update.contents, trimmedUTF16: update.trimmedUTF16)
    }

    func show(_ contents: String, trimmedUTF16: Int) {
        let old = logText.string as NSString
        let textChanged = !old.isEqual(to: contents)
        guard textChanged || self.trimmedUTF16 != trimmedUTF16 else { return }
        let visible = documentVisibleRect
        let follow = followsBottom(visible)
        let removed = max(0, trimmedUTF16 - self.trimmedUTF16)
        self.trimmedUTF16 = trimmedUTF16
        let retained = removed <= old.length ? old.substring(from: removed) : nil
        let retainsText = retained.map { contents.utf16.starts(with: $0.utf16) } ?? false
        let oldAnchor = !follow && removed > 0 ? readingAnchor(in: visible) : nil
        let selection: [NSValue] = retainsText ? logText.selectedRanges.compactMap { value in
            let range = value.rangeValue
            guard NSMaxRange(range) >= removed else { return nil }
            let start = max(range.location, removed)
            return NSValue(range: NSRange(location: start - removed, length: NSMaxRange(range) - start))
        } : []
        if textChanged, let storage = logText.textStorage {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: logFont, .foregroundColor: Self.logColor, .paragraphStyle: logParagraph,
            ]
            if retainsText, let retained {
                let suffix = (contents as NSString).substring(from: retained.utf16.count)
                storage.beginEditing()
                if removed > 0 { storage.deleteCharacters(in: NSRange(location: 0, length: removed)) }
                storage.append(NSAttributedString(string: suffix, attributes: attributes))
                storage.endEditing()
            } else {
                storage.setAttributedString(NSAttributedString(string: contents, attributes: attributes))
            }
        }
        if selection.isEmpty {
            logText.setSelectedRange(NSRange(location: 0, length: 0))
        } else {
            logText.selectedRanges = selection
        }
        let anchor: ReadingAnchor?
        if retainsText, let oldAnchor, oldAnchor.character >= removed {
            anchor = ReadingAnchor(character: oldAnchor.character - removed, offset: oldAnchor.offset)
        } else {
            anchor = nil
        }
        let origin = removed > 0 && !follow ? .zero : visible.origin
        sizeDocument(origin: origin, follow: follow, anchor: anchor)
    }

    private func followsBottom(_ visible: NSRect) -> Bool {
        visible.height == 0 || visible.maxY >= logText.bounds.maxY - 2
    }

    private func readingAnchor(in visible: NSRect) -> ReadingAnchor? {
        guard let layout = logText.layoutManager, let container = logText.textContainer else { return nil }
        let origin = logText.textContainerOrigin
        let glyphs = layout.glyphRange(forBoundingRect: visible.offsetBy(dx: -origin.x, dy: -origin.y), in: container)
        guard glyphs.length > 0 else { return nil }
        let first = glyphOrigin(glyphs.location, in: layout)
        return ReadingAnchor(character: layout.characterIndexForGlyph(at: glyphs.location),
                             offset: CGPoint(x: visible.minX - first.x, y: visible.minY - first.y))
    }

    private func glyphOrigin(_ glyph: Int, in layout: NSLayoutManager) -> CGPoint {
        let line = layout.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
        let origin = logText.textContainerOrigin
        return CGPoint(x: origin.x + line.minX + layout.location(forGlyphAt: glyph).x, y: origin.y + line.minY)
    }

    private func sizeDocument(origin: CGPoint, follow: Bool, anchor: ReadingAnchor? = nil) {
        guard let layout = logText.layoutManager, let container = logText.textContainer else { return }
        layout.ensureLayout(for: container)
        let used = layout.usedRect(for: container).integral
        let viewport = contentView.bounds.size
        let size = NSSize(width: max(viewport.width, used.maxX + logText.textContainerInset.width * 2),
                          height: max(viewport.height, used.maxY + logText.textContainerInset.height * 2))
        if logText.frame.size != size { logText.setFrameSize(size) }
        let maxY = max(0, size.height - viewport.height)
        var target = origin
        if let anchor, anchor.character < (logText.textStorage?.length ?? 0) {
            let glyph = glyphOrigin(layout.glyphIndexForCharacter(at: anchor.character), in: layout)
            target = CGPoint(x: glyph.x + anchor.offset.x, y: glyph.y + anchor.offset.y)
        }
        contentView.scroll(to: CGPoint(x: min(max(0, target.x), max(0, size.width - viewport.width)),
                                       y: follow ? maxY : min(max(0, target.y), maxY)))
        reflectScrolledClipView(contentView)
    }
}

struct ProjectControls: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    @State private var isShowingHistory = false

    static let historyTitle: LocalizedStringResource = "Recent Projects"
    static let folderTitle: LocalizedStringResource = "Open Project"
    static func removeTitle(_ name: String) -> LocalizedStringResource { "Remove \(name) from Recent Projects" }

    let session: SessionController?
    let demoName: String?
    var prepareForPicker: (() -> (() -> Void)?)? = nil

    private var palette: RunletAppearance { RunletAppearance(scheme) }

    var body: some View {
        HStack(spacing: 4) {
            let name = session?.project?.lastPathComponent ?? demoName
            Group {
                if let name {
                    Text(verbatim: name)
                        .contextMenu { Text(verbatim: name) }
                } else {
                    Text("No project selected").foregroundStyle(palette.secondary)
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .lineLimit(1)
            .help(name ?? "")
            Spacer(minLength: 4)

            projectButton(Self.historyTitle, icon: "History", action: { isShowingHistory.toggle() })
                .popover(isPresented: $isShowingHistory, arrowEdge: .bottom) {
                    if let session { history(session).environment(\.locale, locale) }
                }

            projectButton(Self.folderTitle, icon: "Folder", action: openProject)
        }
        .frame(height: 26)
    }

    private func projectButton(_ title: LocalizedStringResource, icon: String,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RunletIcon(icon, size: 16)
                .foregroundStyle(palette.secondary)
                .frame(width: 28, height: 26)
        }
        .buttonStyle(RunletButtonStyle(surface: .outlinedField))
        .accessibilityLabel(Text(title))
        .help(Text(title))
        .disabled(session?.canChangeProject != true && demoName == nil)
    }

    private func history(_ session: SessionController) -> some View {
        RunletPopup(title: Self.historyTitle, close: { isShowingHistory = false }) {
            if session.recentProjects.isEmpty {
                Text("No recent projects").foregroundStyle(palette.secondary).padding(5)
            } else {
                ScrollView {
                    VStack(spacing: 5) {
                        ForEach(session.recentProjects, id: \.self) { project in
                            let name = project.lastPathComponent
                            HStack(spacing: 8) {
                                Button {
                                    if session.open(project) { isShowingHistory = false }
                                } label: {
                                    HStack(spacing: 8) {
                                        RunletIcon("HistoryFolder", size: 14).foregroundStyle(palette.secondary)
                                        Text(verbatim: name)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                }
                                .buttonStyle(RunletButtonStyle())
                                .help(project.path)
                                .disabled(!session.canChangeProject)
                                Button {
                                    session.removeRecentProject(project)
                                } label: {
                                    RunletIcon("Trash", size: 15)
                                        .foregroundStyle(palette.secondary)
                                        .frame(width: 22, height: 26)
                                }
                                .buttonStyle(RunletButtonStyle())
                                .accessibilityLabel(Text(Self.removeTitle(name)))
                                .help(Text(Self.removeTitle(name)))
                            }
                            .padding(.horizontal, 7)
                            .background(palette.field, in: .rect(cornerRadius: 5))
                        }
                    }
                }
                .frame(idealHeight: min(CGFloat(session.recentProjects.count) * 37 - 5, 220), maxHeight: 220)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func openProject() {
        guard let session, session.requestProjectChange() else { return }
        let restorePickerWindow = prepareForPicker?()
        let panel = NSOpenPanel()
        panel.title = locale.appString("Open Flutter Project")
        panel.message = locale.appString("Select the folder for a Flutter project.")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { session.open(url) }
        restorePickerWindow?()
    }
}

struct SessionStatusLabel: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    let session: SessionController?
    let hasDemo: Bool

    var body: some View {
        let status = session?.status ?? (hasDemo ? .ready : .idle)
        let palette = RunletAppearance(scheme)
        let colors: (foreground: Color, surface: Color) = switch status {
        case .running: (palette.success, palette.successSurface)
        case .restoringEnvironment, .recoveryPending: (palette.warning, palette.warningSurface)
        case .recoveryFailed, .recoveryUnavailable, .processUnconfirmed: (palette.error, palette.errorSurface)
        default: (palette.secondary, palette.raised)
        }
        HStack(spacing: 6) {
            Circle().fill(colors.foreground).frame(width: 6, height: 6).accessibilityHidden(true)
            Text(shortTitle(status)).font(RunletType.localized(locale, size: 11, medium: true))
                .lineLimit(1)
                .fixedSize()
        }
        .foregroundStyle(colors.foreground)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(colors.surface, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(status.title))
        .accessibilityValue(Text(session?.recoveryMessage.map { locale.appString($0) } ?? ""))
        .help(Text(session?.recoveryMessage ?? status.title))
    }

    private func shortTitle(_ status: SessionStatus) -> LocalizedStringResource {
        switch status {
        case .idle: "Idle"
        case .checkingToolchain: "Checking"
        case .runningPreTask: "Preparing"
        case .startingFlutter: "Starting"
        case .waitingForVM: "Waiting for VM"
        case .connectionInterrupted: "Disconnected"
        case .restoringEnvironment: "Restoring"
        case .recoveryPending: "Recovery Pending"
        case .recoveryFailed: "Recovery Failed"
        case .recoveryUnavailable: "Recovery Unavailable"
        case .preTaskFailed: "Pre-launch Failed"
        case .processUnconfirmed: "Process Unconfirmed"
        default: status.title
        }
    }
}

struct SessionSettingsButton: View {
    @Environment(\.colorScheme) private var scheme
    let open: (() -> Void)?

    var body: some View {
        Button { open?() } label: {
            RunletIcon("Settings", size: 17)
                .foregroundStyle(RunletAppearance(scheme).secondary)
        }
        .buttonStyle(RunletButtonStyle())
        .accessibilityLabel("Settings")
        .help("Settings")
        .disabled(open == nil)
    }
}

struct RunConfigurationControls: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    @State private var isShowing = false

    let session: SessionController?
    let demoConfiguration: String?
    let runDemo: () -> Void
    var source: DebugActionSource = .menuBar

    private var canRun: Bool {
        session?.canPerformDebugAction(.run, source: source) ?? (demoConfiguration != nil)
    }

    private var canChoose: Bool {
        guard let session else { return false }
        return session.canChangeConfiguration(source: source) && !session.configurationIsStale && !session.choices.isEmpty
    }

    private var palette: RunletAppearance { RunletAppearance(scheme) }

    var body: some View {
        let selected = session?.selection.map { locale.appString($0.title) } ?? demoConfiguration
        let prompt = selected ?? locale.appString("Select a configuration")
        HStack(spacing: 0) {
            Button {
                if let session {
                    session.performDebugAction(.run, source: source)
                } else {
                    runDemo()
                }
            } label: {
                RunletIcon("Run", size: 17).frame(width: 34, height: 32)
            }
            .buttonStyle(RunletButtonStyle(disabledOpacity: 0.43))
            .accessibilityLabel(Text(DebugControls.runAccessibilityLabel))
            .help(Text(DebugControls.runTitle))
            .disabled(!canRun)
            palette.border.frame(width: 1, height: 20)
            Button {
                isShowing.toggle()
            } label: {
                HStack {
                    Text(verbatim: prompt).font(.system(size: 12)).lineLimit(1)
                    Spacer(minLength: 4)
                    RunletIcon("ConfigArrow", size: 15).foregroundStyle(palette.secondary)
                }
                .padding(.horizontal, 9)
                .frame(height: 32)
            }
            .buttonStyle(RunletButtonStyle(disabledOpacity: 0.48))
            .accessibilityLabel("Configuration")
            .accessibilityValue(Text(verbatim: prompt))
            .help(prompt)
            .disabled(!canChoose && demoConfiguration == nil)
            .popover(isPresented: $isShowing, arrowEdge: .bottom) {
                if let session { choices(session).environment(\.locale, locale) }
            }
            if let session, session.configurationIsStale, session.project != nil {
                Button("Reload Configuration", systemImage: "arrow.clockwise", action: session.reload)
                    .labelStyle(.iconOnly)
                    .buttonStyle(RunletButtonStyle())
                    .padding(.trailing, 8)
                    .disabled(!session.canChangeConfiguration(source: source))
                    .help("Reload Configuration")
            }
        }
        .padding(1)
        .foregroundStyle(palette.primary)
        .background(palette.raised, in: .rect(cornerRadius: 6))
        .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(palette.border).allowsHitTesting(false) }
        .contextMenu {
            if let session, session.project != nil {
                if let selected { Text(verbatim: selected) }
                Button("Reload Configuration", systemImage: "arrow.clockwise", action: session.reload)
                    .disabled(!session.canChangeConfiguration(source: source))
            }
        }
    }

    private func choices(_ session: SessionController) -> some View {
        RunletPopup(title: "Select Launch Configuration", close: { isShowing = false }, compactHeader: true) {
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(session.choices) { choice in
                        Button {
                            guard canChoose else { return }
                            session.select(choice.id)
                            isShowing = false
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(choice.title).font(.system(size: 12))
                                if let issue = choice.issue { Text(issue).foregroundStyle(palette.secondary) }
                            }
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 8).padding(.vertical, 6)
                            .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
                        }
                        .buttonStyle(RunletButtonStyle(surface: .field, radius: 5))
                        .accessibilityAddTraits(choice.id == session.selectedID ? .isSelected : [])
                    }
                }
            }
            .frame(idealHeight: min(CGFloat(session.choices.count) * 35 - 5, 224), maxHeight: 224)
            .fixedSize(horizontal: false, vertical: true)
            HStack {
                if session.selection != nil {
                    Button("Clear Configuration Selection") {
                        session.select(nil as Int?)
                        isShowing = false
                    }
                }
                Spacer()
                Button("Reload Configuration", systemImage: "arrow.clockwise") {
                    session.reload()
                    isShowing = false
                }
                .labelStyle(.iconOnly)
                .help("Reload Configuration")
            }
            .buttonStyle(RunletButtonStyle())
            .foregroundStyle(palette.secondary)
        }
    }
}

struct DebugControls: View {
    @Environment(\.locale) private var locale
    static let runTitle: LocalizedStringResource = "Run"
    static let runAccessibilityLabel: LocalizedStringResource = "Run Current Debug Configuration"

    let session: SessionController?

    var body: some View {
        HStack(spacing: 6) {
            debugButton("Reload", accessibilityTitle: "Hot Reload", icon: "Reload", action: .reload)
            debugButton("Restart", accessibilityTitle: "Hot Restart", icon: "Restart", action: .restart)
            debugButton("Stop", accessibilityTitle: "Stop", icon: "Stop", action: .stop)
        }
    }

    private func debugButton(_ title: LocalizedStringResource, accessibilityTitle: LocalizedStringResource,
                             icon: String, action: DebugAction) -> some View {
        Button {
            session?.performDebugAction(action)
        } label: {
            HStack(spacing: 6) {
                RunletIcon(icon, size: 16)
                Text(title).font(RunletType.localized(locale, size: 12, medium: true)).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
        }
        .buttonStyle(RunletButtonStyle(surface: .field, radius: 7))
        .accessibilityLabel(Text(accessibilityTitle))
        .disabled(session?.canPerformDebugAction(action) != true)
    }
}

struct SessionFeedbackView: View {
    let session: SessionController?

    var body: some View {
        if let session, let feedback = session.feedback {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedback.title).fontWeight(.semibold)
                    if let detail = feedback.detail {
                        Text(detail)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Button("Dismiss", action: session.dismissFeedback)
                    .buttonStyle(.bordered)
            }
        }
    }
}

struct BrowserControls: View {
    let session: SessionController?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                browserButton("DevTools", label: "Open DevTools", action: .devTools, icon: "DevTools")
                browserButton("Inspector", label: "Open Inspector", action: .inspector, icon: "Inspector")
            }
            .disabled(session?.canOpenBrowser != true)
            if let session, session.vmConnected, !session.canOpenBrowser {
                Text("No DevTools address is available for the current session")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func browserButton(_ title: LocalizedStringResource, label: LocalizedStringResource,
                               action: FlutterBrowserPage, icon: String) -> some View {
        Button {
            session?.openBrowser(action)
        } label: {
            HStack(spacing: 6) {
                RunletIcon(icon, size: 14)
                Text(title).font(.system(size: 12, weight: .semibold)).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
        }
        .buttonStyle(RunletButtonStyle(surface: .outline, radius: 7))
        .accessibilityLabel(Text(label))
    }
}

#if DEBUG
#Preview("G1 主窗长字段", traits: .fixedLayout(width: 640, height: 520)) {
    MainWindowView(
        presentation: .longFieldsPreview,
        run: {},
        openSettings: {}
    )
}
#endif
