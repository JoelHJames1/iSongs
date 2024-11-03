import SwiftUI

// Define Theme Colors
enum ThemeColor {
    case background
    case accent
    case text
    case secondaryText
    case divider
    case error
    case success
    
    var color: Color {
        switch self {
        case .background:
            return Color(red: 0.1, green: 0.1, blue: 0.2)
        case .accent:
            return Color.blue
        case .text:
            return Color.white
        case .secondaryText:
            return Color.gray
        case .divider:
            return Color.gray.opacity(0.3)
        case .error:
            return Color.red
        case .success:
            return Color.green
        }
    }
}

// Define Gradients
struct ThemeGradient {
    static let primary = [
        Color(red: 0.1, green: 0.1, blue: 0.2),
        Color(red: 0.2, green: 0.1, blue: 0.3),
        Color(red: 0.3, green: 0.1, blue: 0.4)
    ]
    
    static let secondary = [
        Color(red: 0.2, green: 0.1, blue: 0.3),
        Color(red: 0.3, green: 0.1, blue: 0.4),
        Color(red: 0.4, green: 0.1, blue: 0.5)
    ]
}

// Define Shadow Properties
struct Shadow {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
}

struct ThemeShadow {
    static let small = Shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    static let medium = Shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 4)
    static let large = Shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 6)
}

// Define Animations
struct ThemeAnimation {
    static let standard = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let slow = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let fast = Animation.spring(response: 0.2, dampingFraction: 0.8)
}

// Define Metrics
struct ThemeMetrics {
    struct Padding {
        static let small: CGFloat = 8
        static let medium: CGFloat = 15
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 30
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 30
    }
    
    struct IconSize {
        static let small: CGFloat = 20
        static let medium: CGFloat = 24
        static let large: CGFloat = 30
        static let extraLarge: CGFloat = 40
    }
}

// Define Fonts
struct ThemeFont {
    static func title(_ size: FontSize = .medium) -> Font {
        .system(size: size.value, weight: .bold)
    }
    
    static func headline(_ size: FontSize = .medium) -> Font {
        .system(size: size.value, weight: .semibold)
    }
    
    static func body(_ size: FontSize = .medium) -> Font {
        .system(size: size.value, weight: .regular)
    }
    
    static func caption(_ size: FontSize = .medium) -> Font {
        .system(size: size.value, weight: .regular)
    }
    
    enum FontSize {
        case small
        case medium
        case large
        case extraLarge
        
        var value: CGFloat {
            switch self {
            case .small: return 12
            case .medium: return 16
            case .large: return 20
            case .extraLarge: return 24
            }
        }
    }
}

// Define View Modifiers
struct ThemeBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: ThemeGradient.primary),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
    }
}

struct ThemeCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(ThemeMetrics.Padding.medium)
            .background(Color.white.opacity(0.1))
            .cornerRadius(ThemeMetrics.CornerRadius.medium)
            .shadow(color: ThemeShadow.small.color, radius: ThemeShadow.small.radius, x: ThemeShadow.small.x, y: ThemeShadow.small.y)
    }
}

struct ThemeButtonModifier: ViewModifier {
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, ThemeMetrics.Padding.large)
            .padding(.vertical, ThemeMetrics.Padding.medium)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(ThemeMetrics.CornerRadius.medium)
            .shadow(color: ThemeShadow.small.color, radius: ThemeShadow.small.radius, x: ThemeShadow.small.x, y: ThemeShadow.small.y)
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return ThemeColor.accent.color
        case .secondary:
            return Color.white.opacity(0.1)
        case .destructive:
            return ThemeColor.error.color
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .white
        case .destructive:
            return .white
        }
    }
}

// View Extensions
extension View {
    func themeBackground() -> some View {
        modifier(ThemeBackgroundModifier())
    }
    
    func themeCard() -> some View {
        modifier(ThemeCardModifier())
    }
    
    func themeButton(style: ThemeButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(ThemeButtonModifier(style: style))
    }
}

// Common Components
struct ThemeLoadingView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.3))
    }
}

struct ThemeErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: ThemeMetrics.Padding.large) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: ThemeMetrics.IconSize.extraLarge))
                .foregroundColor(ThemeColor.error.color)
            
            Text(message)
                .font(ThemeFont.body())
                .foregroundColor(ThemeColor.text.color)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                retryAction()
            }
            .themeButton(style: .primary)
        }
        .padding()
        .themeCard()
    }
}

struct ThemeEmptyStateView: View {
    let icon: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: ThemeMetrics.Padding.large) {
            Image(systemName: icon)
                .font(.system(size: ThemeMetrics.IconSize.extraLarge))
                .foregroundColor(ThemeColor.secondaryText.color)
            
            Text(message)
                .font(ThemeFont.body())
                .foregroundColor(ThemeColor.secondaryText.color)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .themeButton(style: .secondary)
            }
        }
        .padding()
    }
}
