import AppKit
import SwiftUI

struct SettingsView: View {
    static let windowSize = CGSize(width: 520, height: 520)

    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme
    @FocusState private var languageButtonFocused: Bool

    var session: SessionController? = nil
    enum Page: CaseIterable {
        case general, flutter, about

        var title: LocalizedStringResource {
            switch self {
            case .general: "General"
            case .flutter: "Flutter"
            case .about: "About"
            }
        }
    }

    @Binding var selection: Page?
    @Bindable var language: AppLanguageSettings
    var loginItem: LoginItemSettings? = nil
    @State private var showsDoctorOutput = false
    @State private var showsLanguages = false

    private var palette: RunletAppearance { RunletAppearance(scheme) }
    private var page: Page { selection ?? .general }

    static func launchWindowPreference(_ session: SessionController) -> Binding<Bool> {
        Binding(get: { session.showMainWindowOnLaunch }, set: { session.showMainWindowOnLaunch = $0 })
    }

    var body: some View {
        AuxiliaryWindowLayout(title: "Settings", kind: .settings) {
            HStack(spacing: 0) {
                sidebar
                palette.divider.frame(width: 1)
                ScrollView {
                    VStack(alignment: .leading, spacing: 7) {
                        Text(page.title)
                            .font(page == .flutter ? .system(size: 17, weight: .semibold)
                                  : RunletType.localized(locale, size: 17, medium: true))
                            .frame(height: 23)
                            .accessibilityAddTraits(.isHeader)
                        switch page {
                        case .general: generalSettings
                        case .flutter:
                            if let session, session.usesFlutterToolchain { flutterSettings(session) }
                        case .about: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 14)
                }
            }
        }
        .onExitCommand { if showsLanguages { showsLanguages = false } }
        .onChange(of: selection, initial: true) {
            if selection == .flutter { session?.checkFlutterSDKIfNeeded() }
            else { loginItem?.refresh() }
        }
        .onChange(of: session?.doctorResult != nil) {
            if session?.doctorResult == nil { showsDoctorOutput = false }
        }
        .sheet(isPresented: $showsDoctorOutput) {
            if let result = session?.doctorResult {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Environment Check Output").font(.headline)
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 12) {
                            doctorOutput("Standard Output", text: result.stdout)
                            doctorOutput("Standard Error", text: result.stderr)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack {
                        Spacer()
                        Button("Dismiss") { showsDoctorOutput = false }
                            .keyboardShortcut(.cancelAction)
                    }
                }
                .padding(20)
                .frame(width: 560, height: 360)
                .environment(\.locale, language.locale)
            }
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Page.allCases, id: \.self) { option in
                let selected = page == option
                let prominentGear = page == .about && option == .general
                Button {
                    selection = option
                } label: {
                    HStack(spacing: 8) {
                        navigationIcon(option)
                            .foregroundStyle(selected || prominentGear ? palette.accent : palette.secondary)
                        Text(option.title)
                            .font(option == .flutter ? .system(size: 13, weight: selected ? .semibold : .regular)
                                  : RunletType.localized(locale, size: 13, medium: selected || prominentGear))
                            .foregroundStyle(selected || prominentGear ? palette.primary : palette.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: option == .about ? 37 : 33)
                }
                .buttonStyle(AuxiliaryButtonStyle(surface: selected ? .selected : .clear, radius: 6))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer()
            if let version = AboutInformation().versionLabel {
                Text(verbatim: version)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondary)
                    .frame(height: 16)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(version)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .frame(width: 116)
        .frame(maxHeight: .infinity)
        .background(palette.toolbar)
    }

    @ViewBuilder
    private func navigationIcon(_ option: Page) -> some View {
        switch option {
        case .general:
            RunletIcon("Settings", size: 15)
        case .flutter:
            Path { path in
                path.addLines([CGPoint(x: 5, y: 3.75), CGPoint(x: 1.25, y: 7.5), CGPoint(x: 5, y: 11.25)])
                path.addLines([CGPoint(x: 10, y: 3.75), CGPoint(x: 13.75, y: 7.5), CGPoint(x: 10, y: 11.25)])
                path.addLines([CGPoint(x: 8.75, y: 1.875), CGPoint(x: 6.25, y: 13.125)])
            }
            .stroke(style: StrokeStyle(lineWidth: 1.0625, lineCap: .round, lineJoin: .round))
            .frame(width: 15, height: 15)
            .accessibilityHidden(true)
        case .about:
            Text(verbatim: "ⓘ").font(.system(size: 14))
                .frame(width: 14, height: 23)
                .accessibilityHidden(true)
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 7) {
            groupTitle("Language")
            settingsCard {
                HStack(spacing: 8) {
                    Text("Interface Language").font(RunletType.localized(locale, size: 13))
                    Spacer()
                    languageMenu
                }
                .padding(.horizontal, 12)
                .frame(height: 45)
            }
            groupTitle("Startup & Projects")
            settingsCard {
                if let loginItem {
                    preferenceSwitch("Launch at Login", detail: "Automatically launch FlutterRunlet when you log in to macOS.",
                                     isOn: Binding(get: { loginItem.isRegistered }, set: loginItem.setRegistered),
                                     enabled: loginItem.canChange)
                    if loginItem.statusMessage != nil || loginItem.issue != nil {
                        VStack(alignment: .leading, spacing: 5) {
                            if let status = loginItem.statusMessage { Text(status) }
                            if let issue = loginItem.issue { Text(issue) }
                            Button("Open Login Items in System Settings", action: loginItem.openSystemSettings)
                                .buttonStyle(AuxiliaryButtonStyle())
                        }
                        .font(RunletType.localized(locale, size: 11))
                        .foregroundStyle(palette.secondary)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                }
                if let session {
                    if loginItem != nil { rule }
                    preferenceSwitch("Show Main Window on Launch", isOn: Self.launchWindowPreference(session))
                    rule
                    preferenceSwitch("Remember Last Opened Project", isOn: Binding(
                        get: { session.rememberRecentProject }, set: { session.rememberRecentProject = $0 }
                    ))
                }
            }
        }
    }

    private var languageMenu: some View {
        Button {
            showsLanguages.toggle()
        } label: {
            HStack(spacing: 8) {
                Text(language.selection.label)
                    .font(RunletType.localized(locale, size: 12))
                Path { path in
                    path.addLines([CGPoint(x: 4.375, y: 6.25), CGPoint(x: 7.5, y: 9.375), CGPoint(x: 10.625, y: 6.25)])
                }
                .stroke(style: StrokeStyle(lineWidth: 1.0625, lineCap: .round, lineJoin: .round))
                .foregroundStyle(palette.secondary)
                .frame(width: 15, height: 15)
                .accessibilityHidden(true)
            }
            .padding(.horizontal, 9)
            .frame(height: 29)
        }
        .buttonStyle(AuxiliaryButtonStyle())
        .focused($languageButtonFocused)
        .accessibilityLabel(Text("Choose Language"))
        .accessibilityValue(Text(language.selection.label))
        .popover(isPresented: $showsLanguages, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Choose Language")
                    .font(RunletType.localized(locale, size: 14, medium: true))
                    .frame(height: 23)
                    .accessibilityAddTraits(.isHeader)
                ForEach(AppLanguage.allCases, id: \.self) { option in
                    Button {
                        language.selection = option
                        showsLanguages = false
                    } label: {
                        Text(option.label)
                            .font(option == .english ? .system(size: 11, weight: .semibold)
                                  : RunletType.localized(locale, size: 11, medium: true))
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 26)
                    }
                    .buttonStyle(AuxiliaryButtonStyle())
                    .accessibilityAddTraits(language.selection == option ? .isSelected : [])
                }
            }
            .padding(13)
            .frame(width: 310)
            .foregroundStyle(palette.primary)
            .background(palette.toolbar)
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(palette.divider).allowsHitTesting(false) }
            .onExitCommand { showsLanguages = false }
            .environment(\.locale, language.locale)
        }
        .onChange(of: showsLanguages) { _, isShowing in
            if !isShowing { languageButtonFocused = true }
        }
    }

    private func groupTitle(_ title: LocalizedStringResource, systemFont: Bool = false) -> some View {
        Text(title)
            .font(systemFont ? .system(size: 12, weight: .semibold) : RunletType.localized(locale, size: 12, medium: true))
            .foregroundStyle(palette.secondary)
            .frame(height: 19)
            .accessibilityAddTraits(.isHeader)
    }

    private func settingsCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .padding(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.field, in: RoundedRectangle(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(palette.divider).allowsHitTesting(false) }
    }

    private var rule: some View { palette.divider.frame(height: 1) }

    private func preferenceSwitch(_ title: LocalizedStringResource, detail: LocalizedStringResource? = nil,
                                  isOn: Binding<Bool>, enabled: Bool = true) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(RunletType.localized(locale, size: 13))
                    .frame(minHeight: 19)
                if let detail {
                    Text(detail)
                        .font(RunletType.localized(locale, size: 11))
                        .foregroundStyle(palette.secondary)
                        .frame(minHeight: 16)
                }
            }
        }
        .toggleStyle(AuxiliarySwitchStyle())
        .accessibilityLabel(Text(title))
        .accessibilityHint(detail.map { Text($0) } ?? Text(verbatim: ""))
        .disabled(!enabled)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func flutterSettings(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if session.isCheckingSDK {
                ProgressView("Checking Flutter SDK")
                    .controlSize(.small)
            }
            if let sdk = session.sdk {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                    sdkRow("Source", value: locale.appString(sdk.source.title))
                    sdkRow("Path", value: sdk.directory.path)
                    sdkRow("Flutter", value: sdk.flutterVersion)
                    sdkRow("Dart", value: sdk.dartVersion)
                    if let fvmVersion = sdk.projectFVMVersion {
                        sdkRow("Project FVM Version", value: fvmVersion)
                    }
                }
            }
            if let issue = session.sdkIssue {
                Text(issue).foregroundStyle(.secondary)
            }

            Toggle("Prefer Project FVM", isOn: Binding(
                get: { session.preferProjectFVM }, set: session.setPreferProjectFVM
            ))
            .disabled(!session.canEditFlutterSDK)

            if let path = session.manualSDKPath, session.sdk?.source != .manual {
                Text(verbatim: path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(path)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Button("Select Flutter SDK Path") { chooseSDK(for: session) }
                if session.manualSDKPath != nil {
                    Button("Clear Manual Path", action: session.clearManualFlutterSDK)
                }
            }
            .disabled(!session.canEditFlutterSDK)
            if session.isCheckingSDKSelection {
                ProgressView("Validating Selected Path").controlSize(.small)
            } else if !session.canEditFlutterSDK {
                Text("Stop the current session and finish environment recovery to change SDK settings.")
                    .foregroundStyle(.secondary)
            }
            if let issue = session.sdkSelectionIssue {
                Text(issue).foregroundStyle(.secondary)
            }
            Divider()
            environmentCheck(session)
        }
    }

    private func environmentCheck(_ session: SessionController) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if session.isCheckingEnvironment {
                    ProgressView("Checking Environment").controlSize(.small)
                    Button("Cancel", action: session.cancelEnvironmentCheck)
                } else {
                    Button(action: session.checkEnvironment) {
                        if session.doctorResult?.failure != nil { Text("Retry") }
                        else { Text("Check Environment") }
                    }
                    .disabled(!session.canCheckEnvironment)
                }
                if let result = session.doctorResult, !result.stdout.isEmpty || !result.stderr.isEmpty {
                    Button("View Full Output") { showsDoctorOutput = true }
                }
            }
            if let result = session.doctorResult {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    ForEach(FlutterDoctorResult.Tool.allCases, id: \.self) { tool in
                        GridRow {
                            Text(tool.title)
                            Text((result.summary[tool] ?? .unknown).title).foregroundStyle(.secondary)
                        }
                    }
                }
                if let failure = result.failure {
                    Text("Environment check could not complete: \(failure.reason). Check the Flutter SDK and try again.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func doctorOutput(_ title: LocalizedStringKey, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            if text.isEmpty {
                Text("No Output").foregroundStyle(.secondary)
            } else {
                Text(verbatim: text)
                    .font(.system(size: 12, design: .monospaced))
                    .fixedSize(horizontal: true, vertical: true)
                    .textSelection(.enabled)
            }
        }
    }

    private func sdkRow(_ title: LocalizedStringKey, value: String) -> some View {
        GridRow {
            Text(title).foregroundStyle(.secondary)
            Text(verbatim: value)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(value)
                .textSelection(.enabled)
        }
    }

    private func chooseSDK(for session: SessionController) {
        let panel = NSOpenPanel()
        panel.title = locale.appString("Select Flutter SDK Path")
        panel.message = locale.appString("Select the directory containing the Flutter SDK.")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if let path = session.manualSDKPath ?? session.sdk?.directory.path {
            panel.directoryURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        if panel.runModal() == .OK, let url = panel.url {
            session.selectFlutterSDK(url)
        }
    }
}

private extension FlutterSDK.Source {
    var title: LocalizedStringResource {
        switch self {
        case .projectFVM: "Project FVM"
        case .manual: "Manual"
        case .system: "System PATH"
        }
    }
}

struct AboutInformation {
    let version: String?
    let buildNumber: String?

    init(bundle: Bundle = .main) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    var versionLabel: String? {
        guard let version else { return nil }
        guard let buildNumber else { return "v\(version)" }
        return "v\(version) (build \(buildNumber))"
    }

    static let upstreamCopyright = "Copyright (c) 2026 huseyiniriss"

    enum Destination: CaseIterable {
        case project, documentation, license

        var title: LocalizedStringResource {
            switch self {
            case .project: "Project Home"
            case .documentation: "Documentation"
            case .license: "Project License"
            }
        }

        var url: URL {
            switch self {
            case .project: URL(string: "https://github.com/atypiape/flutter-runlet")!
            case .documentation: URL(string: "https://github.com/atypiape/flutter-runlet/blob/main/README.md")!
            case .license: URL(string: "https://github.com/atypiape/flutter-runlet/blob/main/LICENSE")!
            }
        }
    }
}

struct AboutView: View {
    private let information = AboutInformation()

    var body: some View {
        VStack(spacing: 12) {
            Image("BrandGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("FlutterRunlet Logo")

            Text("FlutterRunlet")
                .font(.title.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            Text("Lightweight Flutter debugging for macOS.")
                .multilineTextAlignment(.center)

            VStack(spacing: 4) {
                if let version = information.version {
                    Text("Version \(version)")
                }
                if let buildNumber = information.buildNumber {
                    Text("Build \(buildNumber)")
                }
            }
            .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("Inspired by Flutter GUI Runner")
                Text(verbatim: AboutInformation.upstreamCopyright)
                Text("MIT License")
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(AboutInformation.Destination.allCases, id: \.self) { destination in
                    Link(destination: destination.url) {
                        Text(destination.title)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AuxiliaryWindowLayout<Content: View>: View {
    enum Kind { case settings, about }

    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    let title: LocalizedStringResource
    let kind: Kind
    @ViewBuilder let content: () -> Content

    var body: some View {
        let palette = RunletAppearance(scheme)
        let settings = kind == .settings
        let size = settings ? SettingsView.windowSize : CGSize(width: 400, height: 412)
        VStack(spacing: 0) {
            Text(title)
                .font(RunletType.localized(locale, size: settings ? 14 : 12, medium: true))
                .padding(.leading, settings ? 75 : 0)
                .frame(maxWidth: .infinity, alignment: settings ? .leading : .center)
                .frame(height: settings ? 47 : 35)
                .background(palette.toolbar)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .accessibilityHidden(true)
            palette.divider.frame(height: 1)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(1)
        .frame(width: size.width, height: size.height)
        .foregroundStyle(palette.primary)
        .background(palette.window)
        .overlay {
            RoundedRectangle(cornerRadius: settings ? 13 : 14)
                .strokeBorder(settings ? palette.divider : palette.border)
                .allowsHitTesting(false)
        }
        .background(WindowChrome(title: locale.appString(title), kind: kind))
        .ignoresSafeArea()
    }

    private struct WindowChrome: NSViewRepresentable {
        let title: String
        let kind: Kind

        func makeNSView(context: Context) -> ChromeView { ChromeView() }

        func updateNSView(_ view: ChromeView, context: Context) {
            view.configuration = self
        }

        final class ChromeView: NSView {
            var configuration: WindowChrome? { didSet { updateWindow() } }

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                updateWindow()
            }

            private func updateWindow() {
                DispatchQueue.main.async { [weak self] in self?.configureWindow() }
            }

            private func configureWindow() {
                guard let window, let configuration else { return }
                window.title = configuration.title
                window.titleVisibility = .hidden
                if !window.styleMask.contains(.fullSizeContentView) {
                    window.styleMask.insert(.fullSizeContentView)
                }
                window.titlebarAppearsTransparent = true
                let size = configuration.kind == .settings ? SettingsView.windowSize : CGSize(width: 400, height: 412)
                if window.frame.size != size {
                    window.setFrame(NSRect(x: window.frame.minX, y: window.frame.maxY - size.height,
                                           width: size.width, height: size.height), display: true)
                }
                if configuration.kind == .about {
                    window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window.standardWindowButton(.zoomButton)?.isHidden = true
                }
            }
        }
    }
}

struct AuxiliaryButtonStyle: ButtonStyle {
    enum Surface { case clear, selected, raised, accent, link }

    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme

    var surface: Surface = .raised
    var radius: CGFloat = 5
    var preservesDisabledSurface = false

    func makeBody(configuration: Configuration) -> some View {
        let palette = RunletAppearance(scheme)
        let shape = RoundedRectangle(cornerRadius: radius)
        let fill: Color = switch surface {
        case .clear: .clear
        case .selected: palette.selected
        case .raised: palette.raised
        case .accent: palette.accent
        case .link: palette.field
        }
        let stroke: Color = switch surface {
        case .raised: palette.divider
        case .link: palette.border
        default: .clear
        }
        let visuallyEnabled = enabled || preservesDisabledSurface
        configuration.label
            .contentShape(Rectangle())
            .background(configuration.isPressed ? fill.opacity(0.75) : (visuallyEnabled ? fill : palette.disabled), in: shape)
            .overlay { shape.strokeBorder(stroke).allowsHitTesting(false) }
            .opacity(visuallyEnabled ? 1 : 0.7)
    }
}

private struct AuxiliarySwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme

    func makeBody(configuration: Configuration) -> some View {
        let palette = RunletAppearance(scheme)
        return Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                configuration.label
                Spacer(minLength: 0)
                Capsule()
                    .fill(configuration.isOn ? palette.accent : Color(.sRGB, red: 97/255, green: 102/255, blue: 115/255))
                    .frame(width: 32, height: 18)
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle().fill(.white)
                            .frame(width: 12, height: 12)
                            .padding(.horizontal, 3)
                    }
                    .opacity(enabled ? 1 : 0.55)
            }
        }
        .buttonStyle(AuxiliaryButtonStyle(surface: .clear))
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}
