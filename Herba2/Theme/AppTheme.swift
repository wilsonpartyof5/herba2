import SwiftUI

struct AppTheme {
    // MARK: - Colors
    static let colors = (
        background: Color(hex: "F5F5F0"), // Warm off-white
        accent: Color(hex: "B7C9A8"), // Sage green (was brown)
        secondary: Color(hex: "A8B38B"), // Sage green
        tertiary: Color(hex: "D4C4B7"), // Soft taupe
        text: Color(hex: "4A4A4A"), // Dark gray
        lightText: Color(hex: "8E8E8E"), // Medium gray
        success: Color(hex: "7D9F7D"), // Muted green
        warning: Color(hex: "D4A373"), // Warm orange
        error: Color(hex: "B56576"), // Muted red
        sageGreen: Color(hex: "B7C9A8") // Soft sage green
    )
    
    // MARK: - Typography
    struct Typography {
        static let title = Font.custom("Georgia", size: 24).weight(.bold)
        static let headline = Font.custom("Georgia", size: 20).weight(.semibold)
        static let subheadline = Font.custom("Georgia", size: 16).weight(.medium)
        static let body = Font.custom("Georgia", size: 16)
        static let caption = Font.custom("Georgia", size: 14)
        static let small = Font.custom("Georgia", size: 12)
    }
    
    // MARK: - Common Styles
    struct Styles {
        static let cardBackground = Color.white
        static let inputField = Color.white
        static let button = colors.accent
    }
    
    // MARK: - Common Components
    struct Components {
        static func primaryButton(title: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(title)
                    .font(Typography.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .background(Styles.button)
            .cornerRadius(20)
            .shadow(color: colors.accent.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        
        static func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Text(title)
                    .font(Typography.subheadline)
                    .foregroundColor(colors.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(colors.accent, lineWidth: 1)
            )
        }
        
        static func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
            content()
                .padding()
                .background(Styles.cardBackground)
                .cornerRadius(12)
                .shadow(color: colors.accent.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - View Extensions
extension View {
    func appCardStyle() -> some View {
        self
            .padding()
            .background(AppTheme.Styles.cardBackground)
            .cornerRadius(12)
            .shadow(color: AppTheme.colors.accent.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    func appInputStyle() -> some View {
        self
            .padding(12)
            .background(AppTheme.Styles.inputField)
            .cornerRadius(20)
            .shadow(color: AppTheme.colors.accent.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    func appButtonStyle() -> some View {
        self
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.Styles.button)
            .foregroundColor(.white)
            .cornerRadius(20)
            .shadow(color: AppTheme.colors.accent.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Text Extensions
extension Text {
    func appTitle() -> some View {
        self
            .font(AppTheme.Typography.title)
            .foregroundColor(AppTheme.colors.text)
    }
    
    func appHeadline() -> some View {
        self
            .font(AppTheme.Typography.headline)
            .foregroundColor(AppTheme.colors.text)
    }
    
    func appBody() -> some View {
        self
            .font(AppTheme.Typography.body)
            .foregroundColor(AppTheme.colors.text)
    }
    
    func appCaption() -> some View {
        self
            .font(AppTheme.Typography.caption)
            .foregroundColor(AppTheme.colors.lightText)
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 