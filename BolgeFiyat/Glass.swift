import SwiftUI

// MARK: - Liquid Glass yardımcıları
// iOS 26'da gerçek Liquid Glass (glassEffect) kullanılır.
// Eski iOS sürümlerinde ve eski Xcode ile derlemede buzlu cam (material) görünümüne düşer.

extension View {
    @ViewBuilder
    func glass(_ radius: CGFloat = 22, tint: Color? = nil, interactive: Bool = false) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            self.glassEffect(liquidGlass(tint: tint, interactive: interactive),
                             in: RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            self.modifier(FallbackGlass(radius: radius, tint: tint))
        }
        #else
        self.modifier(FallbackGlass(radius: radius, tint: tint))
        #endif
    }

    @ViewBuilder
    func glassButton(prominent: Bool = false, tint: Color? = nil) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if prominent {
                self.buttonStyle(.glassProminent).tint(tint)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            self.fallbackButton(prominent: prominent, tint: tint)
        }
        #else
        self.fallbackButton(prominent: prominent, tint: tint)
        #endif
    }

    @ViewBuilder
    fileprivate func fallbackButton(prominent: Bool, tint: Color?) -> some View {
        if prominent {
            self.buttonStyle(.borderedProminent).tint(tint)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}

#if compiler(>=6.2)
@available(iOS 26.0, *)
private func liquidGlass(tint: Color?, interactive: Bool) -> Glass {
    var g = Glass.regular
    if let tint { g = g.tint(tint.opacity(0.35)) }
    if interactive { g = g.interactive() }
    return g
}
#endif

private struct FallbackGlass: ViewModifier {
    let radius: CGFloat
    let tint: Color?
    func body(content: Content) -> some View {
        content.background {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            shape.fill(.ultraThinMaterial)
                .overlay(shape.fill((tint ?? .clear).opacity(0.22)))
                .overlay(shape.strokeBorder(.white.opacity(0.14), lineWidth: 1))
        }
    }
}

// MARK: - Arka plan (camın arkasında renk olsun diye)

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.13),
                                    Color(red: 0.02, green: 0.02, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(red: 0.17, green: 0.42, blue: 1.0).opacity(0.55))
                .frame(width: 360, height: 360).blur(radius: 90).offset(x: -150, y: -320)
            Circle().fill(Color(red: 0.1, green: 0.76, blue: 0.49).opacity(0.40))
                .frame(width: 320, height: 320).blur(radius: 90).offset(x: 170, y: 20)
            Circle().fill(Color(red: 0.69, green: 0.24, blue: 1.0).opacity(0.38))
                .frame(width: 320, height: 320).blur(radius: 100).offset(x: -80, y: 400)
        }
        .ignoresSafeArea()
    }
}

extension Color {
    static let accentGreen = Color(red: 0.49, green: 0.95, blue: 0.61)
    static let accentBlue = Color(red: 0.42, green: 0.66, blue: 1.0)
    static let warn = Color(red: 1.0, green: 0.71, blue: 0.33)
}
