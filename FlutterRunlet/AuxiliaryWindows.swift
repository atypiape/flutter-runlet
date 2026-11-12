import Foundation
import SwiftUI

struct SettingsView: View {
    var session: SessionController? = nil
    private enum Page: CaseIterable {
        case general
        case flutter

        var title: LocalizedStringKey {
            switch self {
            case .general: "通用"
            case .flutter: "Flutter"
            }
        }

        var symbol: String {
            switch self {
            case .general: "gearshape"
            case .flutter: "hammer"
            }
        }
    }

    @State private var selection: Page? = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(Page.allCases, id: \.self) { page in
                    Label(page.title, systemImage: page.symbol)
                        .tag(page)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(142)
        } detail: {
            VStack(alignment: .leading, spacing: 16) {
                Text((selection ?? .general).title)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                if (selection ?? .general) == .general, let session {
                    Toggle("记住最近打开的项目", isOn: Binding(
                        get: { session.rememberRecentProject },
                        set: { session.rememberRecentProject = $0 }
                    ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
        }
        .toolbar(removing: .sidebarToggle)
    }
}

struct AboutView: View {
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    private let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

    var body: some View {
        VStack(spacing: 12) {
            Image("BrandGlyph")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("FlutterRunlet 标志")

            Text("FlutterRunlet")
                .font(.title.weight(.semibold))
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 4) {
                if let version {
                    Text("版本 \(version)")
                }
                if let buildNumber {
                    Text("构建号 \(buildNumber)")
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
