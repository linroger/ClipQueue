import SwiftUI
import AppKit

// MARK: - Liquid Glass Style Configuration

struct LiquidGlassStyle {
    static let shadowRadius: CGFloat = 8
    static let shadowOpacity: CGFloat = 0.12

    /// Returns corner radius based on user preference
    static func cornerRadius(for style: CornerStyle = Preferences.shared.cornerStyle) -> CGFloat {
        style.radius
    }

    /// Returns item corner radius (slightly smaller than container)
    static func itemCornerRadius(for style: CornerStyle = Preferences.shared.cornerStyle) -> CGFloat {
        max(style.radius - 4, 4)
    }

    /// Returns the appropriate material based on user preferences
    static func material(
        vibrancy: Bool = Preferences.shared.useVibrancy,
        thickness: MaterialThickness = Preferences.shared.materialThickness
    ) -> Material {
        guard vibrancy else { return .bar }
        switch thickness {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        }
    }

    /// Returns container material based on glass variant and thickness
    static func containerMaterial(
        variant: GlassVariant = Preferences.shared.glassVariant,
        thickness: MaterialThickness = Preferences.shared.materialThickness,
        vibrancy: Bool = Preferences.shared.useVibrancy
    ) -> Material {
        guard vibrancy else { return .bar }
        switch variant {
        case .regular:
            return material(vibrancy: vibrancy, thickness: thickness)
        case .clear:
            // Clear variant uses thinner materials for more transparency
            switch thickness {
            case .ultraThin, .thin: return .ultraThinMaterial
            case .regular: return .thinMaterial
            case .thick: return .regularMaterial
            }
        }
    }

    /// Returns thin material for search fields and inputs
    static func thinMaterial(vibrancy: Bool = Preferences.shared.useVibrancy) -> Material {
        vibrancy ? .thinMaterial : .bar
    }

    /// Returns accent color based on user preference
    static func accentColor(for option: AccentColorOption = Preferences.shared.accentColorOption) -> Color {
        option.color
    }

    /// Returns shadow opacity based on preferences
    static func shadowOpacity(showShadows: Bool = Preferences.shared.showShadows) -> CGFloat {
        showShadows ? 0.12 : 0
    }

    /// Returns blur intensity multiplier
    static func blurMultiplier(intensity: Double = Preferences.shared.blurIntensity) -> CGFloat {
        CGFloat(intensity)
    }
}

// MARK: - Liquid Glass Container

struct LiquidGlassContainer<Content: View>: View {
    @ObservedObject var preferences = Preferences.shared
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    private var cornerRadius: CGFloat {
        LiquidGlassStyle.cornerRadius(for: preferences.cornerStyle)
    }

    private var backgroundFill: some ShapeStyle {
        if preferences.useVibrancy {
            return AnyShapeStyle(LiquidGlassStyle.containerMaterial(
                variant: preferences.glassVariant,
                thickness: preferences.materialThickness,
                vibrancy: true
            ))
        } else {
            return AnyShapeStyle(Color(NSColor.windowBackgroundColor))
        }
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
                    .opacity(preferences.windowTranslucency)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: Color.black.opacity(LiquidGlassStyle.shadowOpacity(showShadows: preferences.showShadows)),
                radius: LiquidGlassStyle.shadowRadius,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Glass Item Card

struct GlassItemCard<Content: View>: View {
    @ObservedObject var preferences = Preferences.shared
    let isSelected: Bool
    let content: Content

    init(isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    private var cornerRadius: CGFloat {
        LiquidGlassStyle.itemCornerRadius(for: preferences.cornerStyle)
    }

    private var accentColor: Color {
        LiquidGlassStyle.accentColor(for: preferences.accentColorOption)
    }

    private var backgroundFill: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(accentColor.opacity(0.15))
        } else if preferences.useVibrancy {
            // Use thinner material for cards based on glass variant
            let material: Material = preferences.glassVariant == .clear ? .ultraThinMaterial : .thinMaterial
            return AnyShapeStyle(material)
        } else {
            return AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.5))
        }
    }

    private var borderColor: Color {
        if isSelected {
            return accentColor.opacity(0.5)
        } else {
            return Color(NSColor.separatorColor).opacity(preferences.showBorders ? 0.4 : 0)
        }
    }

    var body: some View {
        content
            .padding(.horizontal, preferences.rowDensity.horizontalPadding)
            .padding(.vertical, preferences.rowDensity.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: preferences.showBorders || isSelected ? 1 : 0)
            )
    }
}

enum GlassBarEdge {
    case top
    case bottom
}

struct GlassBar<Content: View>: View {
    @ObservedObject var preferences = Preferences.shared
    let edge: GlassBarEdge
    let content: Content

    init(edge: GlassBarEdge = .bottom, @ViewBuilder content: () -> Content) {
        self.edge = edge
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(minHeight: 40)
            .background(
                LiquidGlassStyle.material(
                    vibrancy: preferences.useVibrancy,
                    thickness: preferences.materialThickness
                )
            )
            .overlay(alignment: edge == .top ? .bottom : .top) {
                Rectangle()
                    .fill(Color(NSColor.separatorColor).opacity(preferences.showBorders ? 0.5 : 0.25))
                    .frame(height: 0.5)
            }
    }
}

struct GlassSearchField: View {
    @ObservedObject var preferences = Preferences.shared
    @Binding var text: String
    var showClearButton: Bool = true
    @FocusState private var isFocused: Bool

    private var cornerRadius: CGFloat {
        LiquidGlassStyle.itemCornerRadius(for: preferences.cornerStyle)
    }

    private var accentColor: Color {
        LiquidGlassStyle.accentColor(for: preferences.accentColorOption)
    }

    private var fontSize: CGFloat {
        13 * preferences.textSize.scaleFactor
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(isFocused ? accentColor : .secondary)
                .font(.system(size: 12 * preferences.textSize.scaleFactor, weight: .medium))
            TextField("Search", text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: fontSize))
                .focused($isFocused)
            if showClearButton && !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 12 * preferences.textSize.scaleFactor))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(LiquidGlassStyle.thinMaterial(vibrancy: preferences.useVibrancy))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(isFocused ? accentColor.opacity(0.6) : Color(NSColor.separatorColor).opacity(0.4))
        )
        .frame(minWidth: 100)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    @ObservedObject var preferences = Preferences.shared
    var isDestructive: Bool = false
    var isPrimary: Bool = false

    private var accentColor: Color {
        LiquidGlassStyle.accentColor(for: preferences.accentColorOption)
    }

    private var cornerRadius: CGFloat {
        max(LiquidGlassStyle.itemCornerRadius(for: preferences.cornerStyle) - 2, 4)
    }

    func makeBody(configuration: Configuration) -> some View {
        let foregroundColor: Color = {
            if isDestructive { return .red }
            if isPrimary { return .white }
            return .primary
        }()

        let backgroundFill: AnyShapeStyle = {
            if isPrimary {
                return AnyShapeStyle(accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            } else if configuration.isPressed {
                return AnyShapeStyle(Color(NSColor.selectedControlColor).opacity(0.3))
            } else if preferences.useVibrancy {
                return AnyShapeStyle(Material.ultraThinMaterial)
            } else {
                return AnyShapeStyle(Color(NSColor.controlBackgroundColor))
            }
        }()

        configuration.label
            .font(.system(size: 12 * preferences.textSize.scaleFactor, weight: .medium))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(isPrimary ? Color.clear : Color(NSColor.separatorColor).opacity(preferences.showBorders ? 0.5 : 0.2))
            )
            .scaleEffect(configuration.isPressed && !preferences.reduceMotion ? 0.98 : 1.0)
            .animation(preferences.reduceMotion ? nil : .easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Glass Section Header

struct GlassSectionHeader: View {
    @ObservedObject var preferences = Preferences.shared
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    private var fontSize: CGFloat {
        11 * preferences.textSize.scaleFactor
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: fontSize, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

// MARK: - View Modifiers

extension View {
    func glassBackground(
        vibrancy: Bool = Preferences.shared.useVibrancy,
        cornerRadius: CGFloat? = nil,
        thickness: MaterialThickness = Preferences.shared.materialThickness,
        variant: GlassVariant = Preferences.shared.glassVariant
    ) -> some View {
        let radius = cornerRadius ?? LiquidGlassStyle.cornerRadius(for: Preferences.shared.cornerStyle)
        let material = LiquidGlassStyle.containerMaterial(variant: variant, thickness: thickness, vibrancy: vibrancy)
        return self
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(vibrancy ? AnyShapeStyle(material) : AnyShapeStyle(Color(NSColor.windowBackgroundColor)))
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func glassCard(
        isSelected: Bool = false,
        vibrancy: Bool = Preferences.shared.useVibrancy,
        showBorder: Bool = Preferences.shared.showBorders
    ) -> some View {
        let prefs = Preferences.shared
        let cornerRadius = LiquidGlassStyle.itemCornerRadius(for: prefs.cornerStyle)
        let accentColor = LiquidGlassStyle.accentColor(for: prefs.accentColorOption)
        let material: Material = prefs.glassVariant == .clear ? .ultraThinMaterial : .thinMaterial

        return self
            .padding(.horizontal, prefs.rowDensity.horizontalPadding)
            .padding(.vertical, prefs.rowDensity.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(accentColor.opacity(0.15)) : (vibrancy ? AnyShapeStyle(material) : AnyShapeStyle(Color(NSColor.controlBackgroundColor).opacity(0.5))))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(isSelected ? accentColor.opacity(0.5) : Color(NSColor.separatorColor).opacity(showBorder ? 0.4 : 0), lineWidth: showBorder || isSelected ? 1 : 0)
            )
    }

    /// Applies glass shadow when shadows are enabled
    func glassShadow(showShadows: Bool = Preferences.shared.showShadows) -> some View {
        self.shadow(
            color: Color.black.opacity(LiquidGlassStyle.shadowOpacity(showShadows: showShadows)),
            radius: LiquidGlassStyle.shadowRadius,
            x: 0,
            y: 2
        )
    }

    /// Applies animation respecting reduced motion preference
    func glassAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        let prefs = Preferences.shared
        return self.animation(prefs.reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - Glass Divider

struct GlassDivider: View {
    @ObservedObject var preferences = Preferences.shared

    var body: some View {
        Rectangle()
            .fill(Color(NSColor.separatorColor).opacity(preferences.showBorders ? 0.4 : 0.2))
            .frame(height: 0.5)
    }
}

// MARK: - Glass Toggle Style

struct GlassToggleStyle: ToggleStyle {
    @ObservedObject var preferences = Preferences.shared

    private var accentColor: Color {
        LiquidGlassStyle.accentColor(for: preferences.accentColorOption)
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? accentColor : Color(NSColor.separatorColor).opacity(0.3))
                    .frame(width: 40, height: 24)

                Circle()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .frame(width: 20, height: 20)
                    .offset(x: configuration.isOn ? 8 : -8)
            }
            .onTapGesture {
                if !preferences.reduceMotion {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        configuration.isOn.toggle()
                    }
                } else {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}
