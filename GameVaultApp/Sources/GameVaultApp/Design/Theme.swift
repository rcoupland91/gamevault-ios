import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark, grey, purple, midnight, forest

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:   return "System"
        case .light:    return "Light"
        case .dark:     return "Dark"
        case .grey:     return "Steel"
        case .purple:   return "Purple"
        case .midnight: return "Midnight"
        case .forest:   return "Forest"
        }
    }

    var icon: String {
        switch self {
        case .system:   return "circle.lefthalf.filled"
        case .light:    return "sun.max.fill"
        case .dark:     return "moon.stars.fill"
        case .grey:     return "smoke.fill"
        case .purple:   return "sparkles"
        case .midnight: return "moon.fill"
        case .forest:   return "leaf.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:                          return nil
        case .light:                           return .light
        case .dark, .grey, .purple, .midnight, .forest: return .dark
        }
    }

    var accentColor: Color {
        switch self {
        case .system, .light, .dark: return Color.indigo
        case .grey:     return Color(white: 0.55)
        case .purple:   return Color(hue: 0.77, saturation: 0.75, brightness: 0.95)
        case .midnight: return Color(hue: 0.60, saturation: 0.60, brightness: 0.80)
        case .forest:   return Color(hue: 0.35, saturation: 0.65, brightness: 0.60)
        }
    }

    // Used for preview swatches in the theme picker
    var previewGradient: LinearGradient {
        switch self {
        case .system:
            return LinearGradient(colors: [Color(hex: "F5F5F7"), Color(hex: "1C1C1E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .light:
            return LinearGradient(colors: [Color(hex: "FFFFFF"), Color(hex: "E8E8F0")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .dark:
            return LinearGradient(colors: [Color(hex: "1A1A2E"), Color(hex: "0D0D1A")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .grey:
            return LinearGradient(colors: [Color(hex: "2C2C2E"), Color(hex: "1C1C1E")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple:
            return LinearGradient(colors: [Color(hex: "2D0050"), Color(hex: "0D0020")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .midnight:
            return LinearGradient(colors: [Color(hex: "001233"), Color(hex: "000814")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .forest:
            return LinearGradient(colors: [Color(hex: "1A3020"), Color(hex: "0D1A0D")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    // Background mesh colors for dynamic backgrounds
    var meshColors: [Color] {
        switch self {
        case .system, .light:
            return [.white, Color(hex: "F0EEFF"), Color(hex: "EBF5FF"), .white, Color(hex: "F5F0FF"), Color(hex: "FFF0F5"), Color(hex: "F0FFF5"), .white, .white]
        case .dark:
            return [Color(hex: "0D0D1A"), Color(hex: "1A0D2E"), Color(hex: "0D1A2E"), Color(hex: "1A1A2E"), Color(hex: "2E1A3D"), Color(hex: "1A2E3D"), Color(hex: "0D0D1A"), Color(hex: "1A1A2E"), Color(hex: "0D1A2E")]
        case .grey:
            return [Color(hex: "1C1C1E"), Color(hex: "2C2C2E"), Color(hex: "1C2426"), Color(hex: "2C2C2E"), Color(hex: "3A3A3C"), Color(hex: "2C3234"), Color(hex: "1C1C1E"), Color(hex: "2C2C2E"), Color(hex: "1C2426")]
        case .purple:
            return [Color(hex: "0D0020"), Color(hex: "1E0040"), Color(hex: "100030"), Color(hex: "1A0035"), Color(hex: "2D0050"), Color(hex: "200040"), Color(hex: "0D0020"), Color(hex: "1A0035"), Color(hex: "100030")]
        case .midnight:
            return [Color(hex: "000814"), Color(hex: "001233"), Color(hex: "00091A"), Color(hex: "001233"), Color(hex: "002855"), Color(hex: "001844"), Color(hex: "000814"), Color(hex: "001233"), Color(hex: "00091A")]
        case .forest:
            return [Color(hex: "0D1A0D"), Color(hex: "1A3020"), Color(hex: "0D1F0D"), Color(hex: "1A3020"), Color(hex: "254030"), Color(hex: "1A3020"), Color(hex: "0D1A0D"), Color(hex: "1A3020"), Color(hex: "0D1F0D")]
        }
    }
}

// MARK: - App Mode

enum AppMode: String, CaseIterable {
    case server = "server"
    case local  = "local"

    var displayName: String {
        switch self {
        case .server: return "GameVault Server"
        case .local:  return "App Only"
        }
    }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    var currentTheme: AppTheme {
        didSet { UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme") ?? "system"
        currentTheme = AppTheme(rawValue: saved) ?? .system
    }

    var accentColor: Color { currentTheme.accentColor }
    var colorScheme: ColorScheme? { currentTheme.colorScheme }
    var meshColors: [Color] { currentTheme.meshColors }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - View Extensions

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }

    @ViewBuilder
    func `if`<Content: View>(@ViewBuilder _ transform: (Self) -> Content) -> Content {
        transform(self)
    }
}
