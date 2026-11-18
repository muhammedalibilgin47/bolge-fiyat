import SwiftUI

struct PlatformPicker: View {
    @Binding var selection: Platform
    var available: [Platform] = Platform.allCases

    var body: some View {
        HStack(spacing: 8) {
            ForEach(available) { p in
                Button {
                    withAnimation(.snappy) { selection = p }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: p.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(p.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selection == p ? Color.white : Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .glass(18, tint: selection == p ? p.color : nil, interactive: true)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == p ? .isSelected : [])
            }
        }
    }
}

struct GameCover: View {
    let game: Game
    var size: CGFloat = 64
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(game.coverGradient)
            .frame(width: size, height: size)
            .overlay(
                Text(game.initials)
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .minimumScaleFactor(0.5)
                    .padding(4)
            )
            .overlay(RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .strokeBorder(.white.opacity(0.18)))
    }
}

struct GameCard: View {
    @EnvironmentObject var catalog: CatalogStore
    let game: Game
    let platform: Platform

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Rectangle().fill(game.coverGradient).frame(height: 104)
                Text(game.initials)
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.22))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.trailing, 6)
                    .lineLimit(1)
                if game.is2026 {
                    Text(game.isUpcoming ? "YAKINDA" : "2026")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(game.isUpcoming ? Color.pink : Color.accentGreen, in: Capsule())
                        .foregroundStyle(game.isUpcoming ? Color.white : Color.black)
                        .padding(10)
                }
            }
            .frame(height: 104)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(game.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2, reservesSpace: true)
                    .foregroundStyle(.white)
                HStack {
                    Text(game.year).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    if let price = priceText {
                        Text(price).font(.caption.weight(.bold)).foregroundStyle(.white)
                    }
                }
            }
            .padding(12)
        }
        .frame(width: 170)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .glass(22)
    }

    private var priceText: String? {
        guard let ed = game.editions(for: platform).first, let prices = ed.prices[platform.rawValue] else { return nil }
        if let tr = prices["tr"] { return catalog.local(tr, currency: catalog.currency(platform: platform, region: "tr")) }
        if let us = prices["us"] { return catalog.local(us, currency: "USD") }
        return nil
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            if let trailing { Text(trailing).font(.footnote).foregroundStyle(.secondary) }
        }
    }
}

struct ProBadge: View {
    var body: some View {
        Label("PRO", systemImage: "crown.fill")
            .font(.caption2.weight(.heavy))
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .foregroundStyle(.black)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentGreen)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

struct ProFeature: Identifiable {
    let icon: String
    let title: String
    let detail: String
    var id: String { title }
}

enum ProFeatures {
    static let all: [ProFeature] = [
        ProFeature(icon: "list.number", title: "Tüm bölgeler",
                   detail: "Ücretsiz sürümde en ucuz bölge ve Türkiye görünür; Pro'da 12 bölgenin tam sıralaması açılır."),
        ProFeature(icon: "square.stack.3d.up.fill", title: "Tüm sürümler",
                   detail: "Ultimate, Deluxe, Vault gibi sürümlerin bölge fiyatları."),
        ProFeature(icon: "rectangle.split.3x1.fill", title: "Platform karşılaştırma",
                   detail: "Aynı oyunun PlayStation, Xbox, Steam ve Nintendo'daki en ucuz fiyatı yan yana."),
        ProFeature(icon: "heart.fill", title: "İstek listesi",
                   detail: "Oyunlarını kaydet, hepsinin en ucuz bölgesini tek ekranda gör.")
    ]
}
