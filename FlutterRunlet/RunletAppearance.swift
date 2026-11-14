import CoreText
import SwiftUI

/// Color pairs read from the v0.2 Figma appearance collection.
struct RunletAppearance {
    let dark: Bool

    init(_ scheme: ColorScheme) { dark = scheme == .dark }

    var window: Color { color(0x171e28, 0xf5f8fc) }
    var toolbar: Color { color(0x1d2632, 0xeaf0f7) }
    var raised: Color { color(0x222d3a, 0xffffff) }
    var field: Color { color(0x202a37, 0xffffff) }
    var border: Color { color(0x344252, 0xb9c8d9) }
    var divider: Color { color(0x2b3848, 0xd4dfea) }
    var primary: Color { color(0xf0f5fb, 0x192638) }
    var secondary: Color { color(0xb0bdcd, 0x46576b) }
    var muted: Color { color(0x8594a7, 0x546579) }
    var accent: Color { color(0x55cfff, 0x006d98) }
    var success: Color { color(0x6dd6a6, 0x136548) }
    var successSurface: Color { color(0x1d3a35, 0xddefe7) }
    var warning: Color { color(0xf6ca80, 0x79510f) }
    var warningSurface: Color { color(0x342d24, 0xfff2d8) }
    var error: Color { color(0xffaba1, 0x963b35) }
    var errorSurface: Color { color(0x3c292d, 0xffe7e3) }
    var console: Color { color(0x111822, 0xedf2f8) }
    var selected: Color { color(0x223d50, 0xd7eaf5) }

    private func color(_ darkValue: UInt32, _ lightValue: UInt32) -> Color {
        let value = dark ? darkValue : lightValue
        return Color(.sRGB, red: Double((value >> 16) & 255) / 255,
                     green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}

enum RunletType {
    private static let registeredFonts: Void = {
        for name in ["NotoSansSC-Regular", "NotoSansSC-Medium", "RobotoMono-Regular"] {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    static func localized(_ locale: Locale, size: CGFloat, medium: Bool = false) -> Font {
        if locale.language.languageCode?.identifier == "zh" {
            _ = registeredFonts
            return .custom(medium ? "NotoSansSC-Medium" : "NotoSansSC-Regular", fixedSize: size)
        }
        return .system(size: size, weight: medium ? .medium : .regular)
    }

    static func logFont() -> NSFont {
        _ = registeredFonts
        return NSFont(name: "RobotoMono-Regular", size: 11) ?? .monospacedSystemFont(ofSize: 11, weight: .regular)
    }
}

struct RunletIcon: View {
    let name: String
    let size: CGFloat

    init(_ name: String, size: CGFloat) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image("Runlet\(name)")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct RunletButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    @Environment(\.colorScheme) private var scheme

    enum Surface {
        case clear, field, outline, outlinedField
    }

    var surface: Surface = .clear
    var radius: CGFloat = 6
    var disabledOpacity = 0.44

    func makeBody(configuration: Configuration) -> some View {
        let palette = RunletAppearance(scheme)
        let shape = RoundedRectangle(cornerRadius: radius)
        let fill = surface == .field || surface == .outlinedField ? palette.field : Color.clear
        configuration.label
            .contentShape(Rectangle())
            .background(configuration.isPressed ? palette.selected : fill, in: shape)
            .overlay {
                if surface == .outline || surface == .outlinedField {
                    shape.strokeBorder(palette.border).allowsHitTesting(false)
                }
            }
            .opacity(enabled ? 1 : disabledOpacity)
    }
}

struct RunletPopup<Content: View>: View {
    @Environment(\.locale) private var locale
    @Environment(\.colorScheme) private var scheme

    let title: LocalizedStringResource
    let close: () -> Void
    var compactHeader = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        let palette = RunletAppearance(scheme)
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(RunletType.localized(locale, size: compactHeader ? 12 : 13, medium: true))
                Spacer()
                Button("Cancel", action: close)
                    .font(RunletType.localized(locale, size: compactHeader ? 12 : 11))
                    .foregroundStyle(palette.secondary)
                    .buttonStyle(RunletButtonStyle())
            }
            .padding(.horizontal, compactHeader ? 0 : 5)
            .frame(minHeight: compactHeader ? 18 : 25)
            content()
        }
        .font(RunletType.localized(locale, size: 12))
        .foregroundStyle(palette.primary)
        .padding(10)
        .frame(width: 320)
        .background(palette.toolbar)
        .overlay { RoundedRectangle(cornerRadius: compactHeader ? 9 : 10).strokeBorder(palette.border).allowsHitTesting(false) }
        .clipShape(.rect(cornerRadius: compactHeader ? 9 : 10))
    }
}
