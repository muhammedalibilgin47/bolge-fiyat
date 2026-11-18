import SwiftUI

struct GameDetailView: View {
    @EnvironmentObject var catalog: CatalogStore
    @EnvironmentObject var pro: ProStore
    @AppStorage("unit") private var unitRaw: String = DisplayUnit.tl.rawValue

    let game: Game
    @State private var platform: Platform
    @State private var editionIndex = 0
    @State private var showPaywall = false
    @State private var showCompare = false

    init(game: Game, startPlatform: Platform) {
        self.game = game
        _platform = State(initialValue: game.isAvailable(on: startPlatform) ? startPlatform : (game.platforms.first ?? .ps))
    }

    private var unit: DisplayUnit { DisplayUnit(rawValue: unitRaw) ?? .tl }
    private var editions: [Edition] { game.editions(for: platform) }
    private var edition: Edition { editions.indices.contains(editionIndex) ? editions[editionIndex] : editions[0] }
    private var rows: [PriceRow] { catalog.rows(game: game, edition: edition, platform: platform) }

    /// Ücretsiz: en ucuz bölge + Türkiye. Pro: hepsi.
    private var visibleRows: [PriceRow] {
        if pro.isPro { return rows }
        return rows.enumerated().filter { $0.offset == 0 || $0.element.region.id == "tr" }.map(\.element)
    }
    private var lockedCount: Int { rows.count - visibleRows.count }

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    hero
                    if game.platforms.count > 1 {
                        PlatformPicker(selection: $platform, available: game.platforms)
                            .onChange(of: platform) { _, _ in editionIndex = 0 }
                    }
                    if editions.count > 1 { editionPicker }
                    if !rows.isEmpty { bestCard }
                    if let note = game.note {
                        Label(note, systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.secondary)
                            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                            .glass(16)
                    }
                    rowsList
                    compareButton
                    sources
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if pro.isPro { pro.toggleWish(game.id) } else { showPaywall = true }
                } label: {
                    Image(systemName: pro.isWished(game.id) ? "heart.fill" : "heart")
                }
                .accessibilityLabel("İstek listesi")
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showCompare) { CompareView(game: game) }
    }

    // MARK: Parçalar

    private var hero: some View {
        HStack(spacing: 16) {
            GameCover(game: game, size: 76)
            VStack(alignment: .leading, spacing: 8) {
                Text(game.name).font(.title2.weight(.bold)).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    if let r = game.releaseText {
                        Text((game.isUpcoming ? "Çıkış: " : "Çıktı: ") + r)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 9).padding(.vertical, 5)
                            .glass(12)
                    }
                    Text("✓ \(rows.count) bölge")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentGreen)
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .glass(12, tint: .green)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .glass(26, tint: Color(hue: game.hue, saturation: 0.7, brightness: 0.6))
        .padding(.top, 8)
    }

    private var editionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(editions.enumerated()), id: \.offset) { i, ed in
                    let locked = i > 0 && !pro.isPro
                    Button {
                        if locked { showPaywall = true } else { withAnimation(.snappy) { editionIndex = i } }
                    } label: {
                        HStack(spacing: 6) {
                            if locked { Image(systemName: "lock.fill").font(.caption2) }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ed.name).font(.subheadline.weight(.semibold))
                                if let p = startingPrice(ed) {
                                    Text(p).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 9)
                        .glass(16, tint: i == editionIndex ? .green : nil, interactive: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    private func startingPrice(_ ed: Edition) -> String? {
        guard let p = ed.prices[platform.rawValue] else { return nil }
        if let us = p["us"] { return catalog.local(us, currency: "USD") }
        if let tr = p["tr"] { return catalog.local(tr, currency: catalog.currency(platform: platform, region: "tr")) }
        return nil
    }

    private var bestCard: some View {
        let best = rows[0]
        let tr = rows.first { $0.region.id == "tr" }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rows.count > 1 ? "EN UCUZ BÖLGE" : "DOĞRULANMIŞ FİYAT")
                    .font(.caption.weight(.heavy)).foregroundStyle(Color.accentGreen)
                Spacer()
                Picker("Birim", selection: $unitRaw) {
                    ForEach(DisplayUnit.allCases) { u in Text(u.label).tag(u.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(best.region.flag) \(best.region.name)").font(.title2.weight(.bold))
                    Text("Mağaza fiyatı: \(catalog.local(best.local, currency: best.currency))")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Text(catalog.display(best, unit: unit))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentGreen)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            if rows.count > 1 {
                Text(savingText(best: best, tr: tr))
                    .font(.footnote).foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(18)
        .glass(24, tint: .green)
    }

    private func savingText(best: PriceRow, tr: PriceRow?) -> String {
        if let tr, tr.id != best.id {
            return "Türkiye'ye göre \(catalog.converted(usd: tr.usd - best.usd, unit: unit)) daha ucuz"
        }
        if tr?.id == best.id { return "Türkiye en ucuz bölge 🎉" }
        let maxUsd = rows.last?.usd ?? best.usd
        return "En pahalıya göre \(catalog.converted(usd: maxUsd - best.usd, unit: unit)) tasarruf"
    }

    private var rowsList: some View {
        VStack(spacing: 8) {
            let maxUsd = rows.last?.usd ?? 1
            ForEach(visibleRows) { row in
                let rank = (rows.firstIndex(of: row) ?? 0) + 1
                PriceRowView(row: row, rank: rank, maxUsd: maxUsd, unit: unit,
                             minUsd: rows.first?.usd ?? row.usd, showDiff: rows.count > 1,
                             url: platform.storeURL(region: row.region.id, query: game.name + (edition.name == "Standart" ? "" : " " + edition.name)))
            }
            if lockedCount > 0 {
                Button { showPaywall = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                        Text("\(lockedCount) bölge daha · Pro ile tam sıralamayı gör")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        ProBadge()
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .glass(18, tint: .orange, interactive: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var compareButton: some View {
        Button {
            if pro.isPro { showCompare = true } else { showPaywall = true }
        } label: {
            HStack {
                Image(systemName: "rectangle.split.3x1.fill")
                Text("Platformları karşılaştır").font(.subheadline.weight(.semibold))
                Spacer()
                if !pro.isPro { ProBadge() } else { Image(systemName: "chevron.right") }
            }
            .foregroundStyle(.white)
            .padding(16)
            .glass(18, interactive: true)
        }
        .buttonStyle(.plain)
        .opacity(game.platforms.count > 1 ? 1 : 0.5)
        .disabled(game.platforms.count < 2)
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Kaynaklar").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            ForEach(game.sources, id: \.url) { s in
                if let url = URL(string: s.url) {
                    Link(s.title, destination: url).font(.caption)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(16)
    }
}

struct PriceRowView: View {
    @EnvironmentObject var catalog: CatalogStore
    let row: PriceRow
    let rank: Int
    let maxUsd: Double
    let unit: DisplayUnit
    let minUsd: Double
    let showDiff: Bool
    let url: URL?

    var body: some View {
        HStack(spacing: 12) {
            Text(rankText)
                .font(rank <= 3 ? Font.title3 : Font.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("\(row.region.flag) \(row.region.name)").font(.subheadline.weight(.semibold))
                    if row.region.id == "tr" {
                        Text("SENİN BÖLGEN").font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.accentGreen.opacity(0.2), in: Capsule())
                            .foregroundStyle(Color.accentGreen)
                    }
                }
                Text("Mağaza: \(catalog.local(row.local, currency: row.currency))")
                    .font(.caption).foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.08))
                        Capsule().fill(rank == 1 ? Color.accentGreen : Color.accentBlue)
                            .frame(width: max(12, geo.size.width * row.usd / max(maxUsd, 0.01)))
                    }
                }
                .frame(height: 5)
            }
            VStack(alignment: .trailing, spacing: 4) {
                Text(catalog.display(row, unit: unit)).font(.headline).foregroundStyle(.white)
                if showDiff {
                    if rank == 1 {
                        Text("En iyi").font(.caption2.weight(.semibold)).foregroundStyle(Color.accentGreen)
                    } else {
                        Text("+" + catalog.converted(usd: row.usd - minUsd, unit: unit))
                            .font(.caption2).foregroundStyle(Color.warn)
                    }
                }
                if let url {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square").font(.footnote)
                    }
                    .accessibilityLabel("Mağazada gör")
                }
            }
        }
        .padding(14)
        .glass(18)
    }

    private var rankText: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }
}

struct CompareView: View {
    @EnvironmentObject var catalog: CatalogStore
    @AppStorage("unit") private var unitRaw: String = DisplayUnit.tl.rawValue
    @Environment(\.dismiss) private var dismiss
    let game: Game

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 10) {
                        let items: [(Platform, PriceRow)] = game.platforms
                            .compactMap { p -> (Platform, PriceRow)? in
                                guard let row = catalog.cheapest(game: game, platform: p) else { return nil }
                                return (p, row)
                            }
                            .sorted { $0.1.usd < $1.1.usd }
                        ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                            HStack(spacing: 14) {
                                Image(systemName: item.0.symbol)
                                    .font(.title2).foregroundStyle(item.0.color).frame(width: 36)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.0.name).font(.headline)
                                    Text("En ucuz: \(item.1.region.flag) \(item.1.region.name) · \(catalog.local(item.1.local, currency: item.1.currency))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(catalog.display(item.1, unit: DisplayUnit(rawValue: unitRaw) ?? .tl))
                                    .font(.headline)
                                    .foregroundStyle(i == 0 ? Color.accentGreen : .white)
                            }
                            .padding(16)
                            .glass(20, tint: i == 0 ? .green : nil)
                        }
                        Text("Her platformun standart sürümündeki en ucuz bölge gösterilir.")
                            .font(.caption).foregroundStyle(.secondary).padding(.top, 6)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Platform karşılaştırma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Kapat") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
