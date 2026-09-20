// MARK: - File: GeoAlarm/DesignSystem.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  DesignSystem.swift — Centralized design tokens for the entire app.
//
//  ┌───────────────────────────────────────────────────────────────────────────┐
//  │  COLOR THEORY RATIONALE — Rainforest Green Palette                      │
//  │                                                                         │
//  │  Inspiration: A deep, misty tropical rainforest — lush canopy greens,   │
//  │  dappled light filtering through leaves, and warm earthy undertones.    │
//  │                                                                         │
//  │  Primary (Deep Canopy Green — HSB 155°, 55%, 35%)                       │
//  │    A desaturated, dark green that evokes dense forest canopy.            │
//  │    Used for navigation titles, key buttons, and primary accents.        │
//  │    Avoids the "neon" feel of system green; feels mature and editorial.  │
//  │                                                                         │
//  │  Secondary (Misty Teal — HSB 170°, 35%, 55%)                            │
//  │    An analogous hue shifted 15° toward cyan (teal). Lighter and         │
//  │    cooler, like light filtering through mist. Used for secondary        │
//  │    actions, highlights, and icon backgrounds.                           │
//  │    Analogous colors (within 30° on the wheel) create visual harmony.   │
//  │                                                                         │
//  │  Accent (Warm Amber — HSB 38°, 70%, 90%)                                │
//  │    A complementary warm hue. Green sits at ~120° on the color wheel;   │
//  │    amber/gold at ~38° provides a split-complementary contrast that     │
//  │    draws the eye without clashing. Used for simulation mode badges,    │
//  │    warnings, and triggered-alarm highlights.                           │
//  │    "Split-complementary" = one color + two neighbors of its complement │
//  │    → high contrast with less tension than direct complementary.        │
//  │                                                                         │
//  │  Success (Bright Fern — HSB 145°, 60%, 60%)                             │
//  │    A brighter, more saturated sibling of the primary green.             │
//  │    Used for success states ("alarm triggered") where we want a          │
//  │    positive, celebratory feel within the same green family.            │
//  │                                                                         │
//  │  Backgrounds follow a "tinted neutral" approach:                        │
//  │    • appBackground: an off-white with a barely-perceptible green tint  │
//  │      (HSB 140°, 4%, 97%) — avoids harsh pure white while keeping the  │
//  │      interface airy.                                                   │
//  │    • cardBackground: a slightly warmer off-white (HSB 140°, 3%, 100%) │
//  │      that subtly lifts cards off the background.                       │
//  │    • In dark mode these invert to dark charcoal-greens for continuity. │
//  │                                                                         │
//  │  Accessibility:                                                         │
//  │    • Primary text on appBackground exceeds WCAG AA (contrast > 4.5:1). │
//  │    • Status badges combine color + text labels (never color-only).     │
//  │    • All interactive elements meet 44pt minimum touch target.          │
//  │    • Typography uses Apple's Dynamic Type–compatible `.body`, `.title` │
//  │      etc., so sizes scale with the user's system setting.             │
//  └───────────────────────────────────────────────────────────────────────────┘
//
//  ┌───────────────────────────────────────────────────────────────────────────┐
//  │  TYPOGRAPHY RATIONALE — Anthropic-Inspired Hierarchy                     │
//  │                                                                         │
//  │  Anthropic's website uses a clean sans-serif with generous spacing and  │
//  │  a clear size progression: large display → distinct subtitle → compact  │
//  │  body → small captions. We emulate this within Apple's SF Pro system:  │
//  │                                                                         │
//  │  • appTitle:     .title (28pt equivalent), .bold weight                │
//  │    Feels editorial and confident. Used for screen/nav titles.          │
//  │                                                                         │
//  │  • appHeadline:  .headline (17pt), .semibold                           │
//  │    For card titles and section emphasis.                                │
//  │                                                                         │
//  │  • appSubhead:   .subheadline (15pt), .medium weight                   │
//  │    Clear visual step-down for secondary labels and metadata.           │
//  │                                                                         │
//  │  • appBody:      .body (17pt), .regular weight                         │
//  │    Standard reading size, comfortable line spacing.                    │
//  │                                                                         │
//  │  • appCaption:   .caption (12pt), .regular weight                      │
//  │    Tertiary info: timestamps, coordinate strings, fine print.          │
//  │                                                                         │
//  │  • appMono:      .caption.monospaced()                                 │
//  │    For coordinate readouts. Mono ensures digits align visually.        │
//  │                                                                         │
//  │  • appButton:    .body.bold()                                          │
//  │    Distinct from body text to indicate interactivity.                  │
//  │                                                                         │
//  │  All styles use SF Pro (the system font) and Dynamic Type–compatible   │
//  │  text styles, so they scale gracefully with Accessibility settings.    │
//  └───────────────────────────────────────────────────────────────────────────┘
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

// MARK: - Color Palette

/// Centralized color tokens for the rainforest-green theme.
///
/// Usage: `Color.appPrimary`, `Color.appAccent`, etc.
/// All colors adapt to light/dark mode via `UIColor { traitCollection in … }`.
extension Color {

    // ── Primary: Deep Canopy Green ─────────────────────────────────
    // Light: HSB(155, 55%, 35%) → a rich, desaturated forest green.
    // Dark:  HSB(155, 40%, 65%) → lifted for readability on dark backgrounds.
    static let appPrimary = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 155/360, saturation: 0.40, brightness: 0.65, alpha: 1)
                : UIColor(hue: 155/360, saturation: 0.55, brightness: 0.35, alpha: 1)
        }
    )

    // ── Secondary: Misty Teal ──────────────────────────────────────
    // Analogous to primary (+15° hue). Cooler, lighter.
    // Light: HSB(170, 35%, 55%)
    // Dark:  HSB(170, 30%, 70%)
    static let appSecondary = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 170/360, saturation: 0.30, brightness: 0.70, alpha: 1)
                : UIColor(hue: 170/360, saturation: 0.35, brightness: 0.55, alpha: 1)
        }
    )

    // ── Accent: Warm Amber ─────────────────────────────────────────
    // Split-complementary to green. Draws attention for simulation
    // badges, warnings, and triggered states.
    // Light: HSB(38, 70%, 90%)
    // Dark:  HSB(38, 55%, 85%)
    static let appAccent = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 38/360, saturation: 0.55, brightness: 0.85, alpha: 1)
                : UIColor(hue: 38/360, saturation: 0.70, brightness: 0.90, alpha: 1)
        }
    )

    // ── Success: Bright Fern ───────────────────────────────────────
    // A saturated sibling of the primary for positive/success states.
    // Light: HSB(145, 60%, 60%)
    // Dark:  HSB(145, 45%, 70%)
    static let appSuccess = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 145/360, saturation: 0.45, brightness: 0.70, alpha: 1)
                : UIColor(hue: 145/360, saturation: 0.60, brightness: 0.60, alpha: 1)
        }
    )

    // ── Warning: Muted Coral ───────────────────────────────────────
    // A warm, low-saturation coral for destructive/warning hints.
    // Light: HSB(10, 55%, 75%)
    // Dark:  HSB(10, 40%, 80%)
    static let appWarning = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 10/360, saturation: 0.40, brightness: 0.80, alpha: 1)
                : UIColor(hue: 10/360, saturation: 0.55, brightness: 0.75, alpha: 1)
        }
    )

    // ── Backgrounds ────────────────────────────────────────────────
    // Main screen background: a green-tinted off-white.
    // Light: HSB(140, 4%, 97%)   → nearly white with a whisper of green.
    // Dark:  HSB(155, 15%, 12%)  → very dark charcoal-green.
    static let appBackground = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 155/360, saturation: 0.15, brightness: 0.12, alpha: 1)
                : UIColor(hue: 140/360, saturation: 0.04, brightness: 0.97, alpha: 1)
        }
    )

    // Card / elevated surface background.
    // Light: pure white (cards float above the tinted background).
    // Dark:  HSB(155, 10%, 18%) → slightly lifted from the dark BG.
    static let appCardBackground = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 155/360, saturation: 0.10, brightness: 0.18, alpha: 1)
                : UIColor(hue: 0, saturation: 0, brightness: 1.0, alpha: 1)
        }
    )

    // Subtle border / divider for cards.
    // Light: HSB(155, 8%, 88%)
    // Dark:  HSB(155, 8%, 25%)
    static let appBorder = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 155/360, saturation: 0.08, brightness: 0.25, alpha: 1)
                : UIColor(hue: 155/360, saturation: 0.08, brightness: 0.88, alpha: 1)
        }
    )

    // ── Text Colors ────────────────────────────────────────────────
    // Primary text: near-black with a hint of green.
    // Light: HSB(150, 10%, 15%)
    // Dark:  HSB(150, 5%, 90%)
    static let appTextPrimary = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 150/360, saturation: 0.05, brightness: 0.90, alpha: 1)
                : UIColor(hue: 150/360, saturation: 0.10, brightness: 0.15, alpha: 1)
        }
    )

    // Secondary text: muted, less prominent.
    // Light: HSB(150, 6%, 45%)
    // Dark:  HSB(150, 5%, 60%)
    static let appTextSecondary = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 150/360, saturation: 0.05, brightness: 0.60, alpha: 1)
                : UIColor(hue: 150/360, saturation: 0.06, brightness: 0.45, alpha: 1)
        }
    )

    // ── Gradient backgrounds ───────────────────────────────────────
    /// A subtle top-to-bottom gradient for the Home screen, evoking
    /// light filtering down through a forest canopy.
    static let appGradientTop = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 155/360, saturation: 0.20, brightness: 0.14, alpha: 1)
                : UIColor(hue: 150/360, saturation: 0.08, brightness: 0.94, alpha: 1)
        }
    )

    static let appGradientBottom = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hue: 155/360, saturation: 0.12, brightness: 0.10, alpha: 1)
                : UIColor(hue: 140/360, saturation: 0.03, brightness: 0.98, alpha: 1)
        }
    )
}

// MARK: - Typography

/// Scalable font tokens that emulate a clean, editorial hierarchy.
///
/// All styles use Apple's built-in text styles (`.title`, `.body`, etc.)
/// which automatically participate in Dynamic Type. This means fonts
/// scale when the user changes their preferred text size in Settings.
extension Font {
    /// Large screen/navigation title — bold, confident, editorial.
    static let appTitle: Font = .title.bold()

    /// Card titles, section headings — clear emphasis without overwhelming.
    static let appHeadline: Font = .headline

    /// Secondary labels, metadata rows — visually subordinate.
    static let appSubhead: Font = .subheadline.weight(.medium)

    /// Section header labels in Forms/Lists.
    static let appSectionHeader: Font = .footnote.weight(.semibold)

    /// Standard body text — comfortable reading size.
    static let appBody: Font = .body

    /// Small, tertiary info — timestamps, fine print, footers.
    static let appCaption: Font = .caption

    /// Monospaced captions for coordinate readouts (digits align).
    static let appMono: Font = .caption.monospaced()

    /// Button labels — bold body text to signal interactivity.
    static let appButton: Font = .body.bold()
}

// MARK: - Reusable View Modifiers

/// A primary action button style (rainforest green, full-width, rounded).
///
/// Usage:
/// ```
/// Button("Save") { ... }
///     .buttonStyle(AppPrimaryButtonStyle())
/// ```
struct AppPrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appButton)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(isDestructive ? Color.appWarning : Color.appPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A secondary/ghost button style — outlined, uses primary color.
struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appSubhead)
            .foregroundStyle(Color.appTextSecondary)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
    }
}

/// Card modifier: rounded corners, background, subtle shadow/border.
///
/// Usage: `.modifier(AppCardModifier())`
struct AppCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.appCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.appBorder, lineWidth: 0.75)
            )
            .shadow(color: Color.appPrimary.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

extension View {
    /// Applies the standard GeoAlarm card styling.
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}

/// Mode pill/badge shown at the top of the Home screen.
/// Adapts color between simulation (amber) and real (green).
struct ModePill: View {
    let isSimulation: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isSimulation ? "play.circle.fill" : "location.fill")
                .font(.caption.weight(.semibold))
            Text(isSimulation ? "Simulation" : "Real Location")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            (isSimulation ? Color.appAccent : Color.appSuccess).opacity(0.18)
        )
        .foregroundStyle(isSimulation ? Color.appAccent : Color.appSuccess)
        .clipShape(Capsule())
    }
}

/// Status badge for alarm states — combines color + text for accessibility.
struct StatusBadge: View {
    let status: GeoAlarmStatus
    let isSimulation: Bool

    /// Maps status → theme color.
    private var color: Color {
        switch status {
        case .waiting:   return .appSecondary
        case .triggered: return isSimulation ? .appAccent : .appSuccess
        case .disabled:  return .appTextSecondary.opacity(0.6)
        }
    }

    /// Override label for simulated triggered.
    private var label: String {
        if case .triggered = status, isSimulation {
            return "Sim Triggered"
        }
        return status.label
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
