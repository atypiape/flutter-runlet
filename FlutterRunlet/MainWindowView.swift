import AppKit
import SwiftUI

struct MainWindowView: View {
    @Environment(\.locale) private var locale

    let presentation: LaunchPresentation
    var session: SessionController? = nil
    let run: () -> Void
    let openSettings: (() -> Void)?
    var openFlutterSettings: (() -> Void)? = nil

    @State private var isLogExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SessionBrand()
                Spacer(minLength: 12)
                SessionStatusLabel(session: session, hasDemo: presentation.selection != nil)
                SessionSettingsButton(open: openSettings)
            }
            ProjectControls(session: session, demoName: presentation.selection?.project)

            HStack(spacing: 12) {
                RunConfigurationControls(session: session, demoConfiguration: presentation.selection?.configuration,
                                         runDemo: run, source: .mainWindow)
                DebugControls(session: session)
            }
            HStack(alignment: .top, spacing: 12) {
                DeviceSelectionControls(session: session, demoDevice: presentation.selection?.device)
                BrowserControls(session: session)
            }
            sessionDetails
                .layoutPriority(1)
            logs
            if !isLogExpanded {
                Spacer(minLength: 0)
            }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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

    private var regularSessionDetails: some View {
        GroupBox("Debug Session") {
            VStack(alignment: .leading, spacing: 8) {
                if let selection = presentation.selection {
                    Text("Ready")
                        .fontWeight(.semibold)
                    Text(verbatim: selection.configuration)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: selection.device)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("VM Service Disconnected")
                        .foregroundStyle(.secondary)
                } else if let session, session.project != nil || session.displayMessage != nil {
                    Text(session.status.title).fontWeight(.semibold)
                    if let launch = session.activeLaunch {
                        Text(verbatim: "\(launch.configurationName) · \(launch.device.name)")
                            .lineLimit(2)
                        Text(session.vmConnected ? "VM Service Connected" : "VM Service Disconnected")
                            .foregroundStyle(.secondary)
                    }
                    if let issue = session.displayMessage, session.recoveryMessage == nil {
                        Text(session.configurationIsStale && !session.choices.isEmpty ? "Configuration Out of Date · \(issue)" : issue)
                            .foregroundStyle(.secondary)
                    }
                    RecoveryDetails(session: session)
                    if session.sdkIssue != nil, let openFlutterSettings {
                        Button("Open Flutter Settings", action: openFlutterSettings)
                    }
                    if let issue = session.taskIssue, issue != session.displayMessage {
                        Text(issue).foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Debug Session")
                        .foregroundStyle(.secondary)
                }

                SessionFeedbackView(session: session)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func recoveryFailureDetails(_ session: SessionController) -> some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.recoveryFailure?.message ?? session.recoveryMessage ?? session.status.title)
                    .fontWeight(.semibold)
                if session.canRunAfterRecovery {
                    Text(RecoveryRetryButton.runHint)
                } else if let blocker = session.recoveryRunBlocker {
                    Text(blocker).foregroundStyle(.secondary)
                }
                if session.recoveryAction == .openProject {
                    RecoveryDetails(session: session, showMessage: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            RecoveryRetryButton(session: session)
        }
        .padding(10)
        .background(.red.opacity(0.13), in: .rect(cornerRadius: 6))
    }

    private var logs: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("Run Logs")
                Spacer(minLength: 0)
                Button("Copy Logs", systemImage: "doc.on.doc") { session?.copyLogs() }
                    .help("Copy Logs")
                    .disabled(session?.logs.isEmpty != false)
                Button("Clear Logs", systemImage: "trash") { session?.clearLogs() }
                    .help("Clear Logs")
                    .disabled(session?.logs.isEmpty != false)
                let title = isLogExpanded ? Self.collapseLogsTitle : Self.expandLogsTitle
                Button {
                    isLogExpanded.toggle()
                } label: {
                    Label {
                        Text(title)
                    } icon: {
                        Image(systemName: isLogExpanded ? "chevron.down" : "chevron.right")
                    }
                }
                .help(Text(title))
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)

            if isLogExpanded {
                SessionLogView(contents: logContents, trimmedUTF16: session?.logTrimmedUTF16 ?? 0)
                    .id(session?.logGeneration)
                    .frame(maxWidth: .infinity, minHeight: 96, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color(nsColor: .separatorColor))
                            .allowsHitTesting(false)
                    }
            }
        }
    }

    static let collapseLogsTitle: LocalizedStringResource = "Collapse Logs"
    static let expandLogsTitle: LocalizedStringResource = "Expand Logs"

    private var logContents: String {
        if let session, !session.logs.isEmpty { return session.logs }
        if session?.didClearLogs == true { return locale.appString("Logs cleared. New output will appear here.") }
        return locale.appString("No run logs yet. Output will appear here after debugging starts.")
    }
}

struct DeviceSelectionControls: View {
    @Environment(\.locale) private var locale
    @State private var isShowing = false
    @FocusState private var isTriggerFocused: Bool

    let session: SessionController?
    let demoDevice: String?

    var body: some View {
        if let session, session.usesFlutterToolchain, session.project != nil {
            Button {
                isShowing.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "iphone")
                        .accessibilityHidden(true)
                    if let device = session.selectedDeviceChoice {
                        Text(verbatim: device.name)
                        Text(device.kind.title)
                            .foregroundStyle(.secondary)
                            .layoutPriority(-1)
                    } else {
                        Text("Select a debug device")
                    }
                    Spacer(minLength: 4)
                    if let device = session.selectedDeviceChoice {
                        availabilityDot(device.availability)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
                .lineLimit(1)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Device for Next Run")
            .accessibilityValue(summary(session.selectedDeviceChoice))
            .help(summary(session.selectedDeviceChoice))
            .focused($isTriggerFocused)
            .popover(isPresented: $isShowing, arrowEdge: .bottom) {
                choices(for: session)
                    .environment(\.locale, locale)
            }
            .onChange(of: isShowing) { _, showing in
                if !showing { isTriggerFocused = true }
            }
        } else {
            PresentationField(field: .device, value: session?.selection?.launch?.deviceID ?? demoDevice)
        }
    }

    private func choices(for session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Select a debug device")
                    .font(.headline)
                Spacer()
                Button("Refresh Devices", systemImage: "arrow.clockwise", action: session.refreshDevices)
                    .labelStyle(.iconOnly)
                    .help("Refresh Devices")
                    .disabled(!session.canRefreshDevices || session.isRefreshingDevices || session.isStartingSimulator)
            }
            Text("The selected device is used for the next run.")
                .foregroundStyle(.secondary)
            if session.isBusy {
                Text("Showing the last device scan.")
                    .foregroundStyle(.secondary)
            }
            if session.isRefreshingDevices || session.isStartingSimulator {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(session.isStartingSimulator ? "Starting iOS Simulator" : "Refreshing Devices")
                }
            }
            if let issue = session.deviceIssue ?? session.sdkIssue ?? session.simulatorIssue {
                Text(issue).foregroundStyle(.secondary)
            }
            if session.deviceChoices.isEmpty, !session.isRefreshingDevices {
                Text("No debug devices found. Connect a device or start a simulator, then refresh devices.")
                    .foregroundStyle(.secondary)
            }
            if !session.deviceChoices.isEmpty {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(session.deviceChoices) { device in
                            Button {
                                if session.canSelectNextDevice {
                                    session.selectDevice(device.id)
                                    isShowing = false
                                }
                            } label: {
                                deviceRow(device, selected: device.id == session.selectedDeviceID)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel(summary(device))
                            .accessibilityAddTraits(device.id == session.selectedDeviceID ? .isSelected : [])
                            .help(summary(device))
                            .disabled(!session.canSelectNextDevice)
                        }
                    }
                }
                .frame(maxHeight: 224)
            }
            if !session.simulators.isEmpty {
                Menu("Start iOS Simulator", systemImage: "iphone") {
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
        .padding(12)
        .frame(width: 316, alignment: .leading)
    }

    private func deviceRow(_ device: DeviceChoice, selected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: selected ? "checkmark" : "iphone")
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: device.name)
                    .fixedSize(horizontal: false, vertical: true)
                Text(device.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(availabilityTitle(device.availability))
                .font(.caption)
                .foregroundStyle(.secondary)
            availabilityDot(device.availability)
        }
        .multilineTextAlignment(.leading)
        .padding(.vertical, 3)
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
        case .online: .green
        case .offline: .red
        case .unknown: .secondary
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
    let session: SessionController
    static let runHint: LocalizedStringResource = "Click Run to try recovery and start debugging"

    var body: some View {
        if session.status == .recoveryFailed, session.recoveryAction == .retry {
            Button("Retry Recovery", systemImage: "arrow.triangle.2.circlepath",
                   action: session.retryRecovery)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .foregroundStyle(Color.teal)
                .help("Retry Recovery")
                .disabled(!session.canPerformRecoveryAction)
        }
    }
}

struct SessionBrand: View {
    var body: some View {
        HStack(spacing: 6) {
            Image("BrandGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 16)
                .accessibilityHidden(true)
            Text("FlutterRunlet").font(.headline)
        }
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

    private let logText = NSTextView(frame: .zero)
    private let logFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
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
        logText.textColor = .textColor
        logText.textContainerInset = NSSize(width: 6, height: 4)
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
            let attributes: [NSAttributedString.Key: Any] = [.font: logFont, .foregroundColor: NSColor.textColor]
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

enum SessionField {
    case project, configuration, device

    var title: LocalizedStringResource {
        switch self {
        case .project: "Project"
        case .configuration: "Configuration"
        case .device: "Device"
        }
    }

    var fullNameAction: LocalizedStringResource {
        switch self {
        case .project: "Show Full Project Name"
        case .configuration: "Show Full Configuration Name"
        case .device: "Show Full Device Name"
        }
    }
}

struct PresentationField: View {
    let field: SessionField
    let value: String?
    var fallback: LocalizedStringResource = "—"
    var originalValue: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.title)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Group {
                    if let value {
                        Text(verbatim: value)
                    } else {
                        Text(fallback)
                    }
                }
                .lineLimit(1)
                .truncationMode(.tail)
                .help(originalValue ?? value ?? "")

                FullNameButton(field: field, name: originalValue ?? value)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FullNameButton: View {
    let field: SessionField
    let name: String?
    @State private var isShowing = false

    var body: some View {
        if let name {
            Button {
                isShowing = true
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text(field.fullNameAction))
            .help(Text(field.fullNameAction))
            .popover(isPresented: $isShowing, arrowEdge: .bottom) {
                Text(verbatim: name)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 360, alignment: .leading)
                    .padding()
            }
        }
    }
}

struct ProjectControls: View {
    @Environment(\.locale) private var locale
    @State private var isShowingHistory = false
    @FocusState private var isFolderFocused: Bool
    @FocusState private var isHistoryFocused: Bool

    static let historyTitle: LocalizedStringResource = "Recent Projects"
    static let folderTitle: LocalizedStringResource = "Open Project"
    static func removeTitle(_ name: String) -> LocalizedStringResource { "Remove \(name) from Recent Projects" }

    let session: SessionController?
    let demoName: String?
    var prepareForPicker: (() -> (() -> Void)?)? = nil

    var body: some View {
        HStack(spacing: 8) {
            let name = session?.project?.lastPathComponent ?? demoName
            Group {
                if let name {
                    Text(verbatim: name)
                } else {
                    Text("No project selected")
                        .foregroundStyle(.secondary)
                }
            }
            .fontWeight(.semibold)
            .lineLimit(1)
            .help(name ?? "")
            FullNameButton(field: .project, name: name)
            Spacer(minLength: 0)

            Button {
                isShowingHistory.toggle()
            } label: {
                Label {
                    Text(Self.historyTitle)
                } icon: {
                    Image(systemName: "clock.arrow.circlepath")
                }
                .labelStyle(.iconOnly)
            }
            .help(Text(Self.historyTitle))
            .focused($isHistoryFocused)
            .disabled(session?.canChangeProject != true)
            .popover(isPresented: $isShowingHistory, arrowEdge: .bottom) {
                if let session {
                    history(session)
                        .environment(\.locale, locale)
                }
            }
            .onChange(of: isShowingHistory) { _, showing in
                if !showing { isHistoryFocused = session?.canChangeProject == true }
            }

            Button(action: openProject) {
                Label {
                    Text(Self.folderTitle)
                } icon: {
                    Image(systemName: "folder")
                }
                .labelStyle(.iconOnly)
            }
            .help(Text(Self.folderTitle))
            .focused($isFolderFocused)
            .disabled(session?.canChangeProject != true)
        }
        .buttonStyle(.bordered)
    }

    private func history(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Self.historyTitle)
                .font(.headline)
            if session.recentProjects.isEmpty {
                Text("No recent projects")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(session.recentProjects, id: \.self) { project in
                            let name = project.lastPathComponent
                            HStack(spacing: 8) {
                                Button {
                                    if session.open(project) { isShowingHistory = false }
                                } label: {
                                    Text(verbatim: name)
                                        .lineLimit(1)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .help(project.path)
                                .disabled(!session.canChangeProject)

                                Button {
                                    session.removeRecentProject(project)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel(Text(Self.removeTitle(name)))
                                .help(Text(Self.removeTitle(name)))
                            }
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
        .padding(12)
        .frame(width: 280, alignment: .leading)
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
        // Restore the SwiftUI folder button as the focus destination after AppKit closes.
        if panel.runModal() == .OK, let url = panel.url { session.open(url) }
        restorePickerWindow?()
        isFolderFocused = session.canChangeProject
    }
}

struct SessionStatusLabel: View {
    let session: SessionController?
    let hasDemo: Bool

    var body: some View {
        let status = session?.status ?? (hasDemo ? .ready : .idle)
        let color: Color = switch status {
        case .running: .green
        case .restoringEnvironment, .recoveryPending: .orange
        case .recoveryFailed, .recoveryUnavailable, .processUnconfirmed: .red
        default: .secondary
        }
        Text(status.title)
            .lineLimit(1)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14), in: Capsule())
            .help(Text(status.title))
    }
}

struct SessionSettingsButton: View {
    let open: (() -> Void)?

    var body: some View {
        Button("Settings", systemImage: "gearshape") { open?() }
            .labelStyle(.iconOnly)
            .help("Settings")
            .disabled(open == nil)
    }
}

struct RunConfigurationControls: View {
    @Environment(\.locale) private var locale

    let session: SessionController?
    let demoConfiguration: String?
    let runDemo: () -> Void
    var source: DebugActionSource = .menuBar

    private var canRun: Bool {
        session?.canPerformDebugAction(.run, source: source) ?? (demoConfiguration != nil)
    }

    var body: some View {
        HStack(spacing: 4) {
            Button {
                if let session {
                    session.performDebugAction(.run, source: source)
                } else {
                    runDemo()
                }
            } label: {
                Image(systemName: "play.fill")
                    .foregroundStyle(canRun ? Color.green : .secondary)
            }
            .accessibilityLabel(Text(DebugControls.runAccessibilityLabel))
            .help(Text(DebugControls.runTitle))
            .disabled(!canRun)

            if let session {
                Picker("Configuration", selection: Binding(get: { session.selectedID }, set: session.select)) {
                    Text("Select a configuration").tag(nil as Int?)
                    ForEach(session.choices) { choice in
                        Text(choice.issue.map { "\(choice.title) · \($0)" } ?? choice.title)
                            .tag(choice.id as Int?)
                    }
                }
                .labelsHidden()
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity)
                .help(session.selection.map { locale.appString($0.title) } ?? "")
                .disabled(!session.canChangeConfiguration(source: source) || session.configurationIsStale || session.choices.isEmpty)
            } else {
                Text(demoConfiguration ?? locale.appString("Select a configuration"))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.secondary)
            }

            FullNameButton(field: .configuration, name: session?.selection.map { locale.appString($0.title) } ?? demoConfiguration)
            if let session, session.project != nil {
                Button("Reload Configuration", systemImage: "arrow.clockwise", action: session.reload)
                    .labelStyle(.iconOnly)
                    .disabled(!session.canChangeConfiguration(source: source))
                    .help("Reload Configuration")
            }
        }
        .buttonStyle(.bordered)
    }
}

struct DebugControls: View {
    static let runTitle: LocalizedStringResource = "Run"
    static let runAccessibilityLabel: LocalizedStringResource = "Run Current Debug Configuration"

    let session: SessionController?
    var equalWidths = false

    var body: some View {
        HStack(spacing: 6) {
            debugButton("Hot Reload", icon: "bolt", action: .reload)
            debugButton("Hot Restart", icon: "arrow.clockwise", action: .restart)
            debugButton("Stop", icon: "stop", action: .stop)
        }
        .buttonStyle(.bordered)
    }

    private func debugButton(_ title: LocalizedStringResource, icon: String, action: DebugAction) -> some View {
        Button {
            session?.performDebugAction(action)
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: icon)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: equalWidths ? .infinity : nil)
        }
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
                Button("Open DevTools") { session?.openBrowser(.devTools) }
                Button("Open Inspector") { session?.openBrowser(.inspector) }
            }
            .buttonStyle(.bordered)
            .disabled(session?.canOpenBrowser != true)
            if let session, session.vmConnected, !session.canOpenBrowser {
                Text("No DevTools address is available for the current session")
                    .foregroundStyle(.secondary)
            }
        }
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
