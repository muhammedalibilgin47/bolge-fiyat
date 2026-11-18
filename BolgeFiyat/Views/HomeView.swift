import SwiftUI

struct HomeView: View {
    @EnvironmentObject var catalog: CatalogStore
    @AppStorage("platform") private var platformRaw: String = Platform.ps.rawValue
    @State private var query = ""
    @State private var path = NavigationPath()

    private var platform: Binding<Platform> {
        Binding(get: { Platform(rawValue: platformRaw) ?? .ps },
                set: { platformRaw = $0.rawValue })
    }

    private var newGames: [Game] {
        catalog.games(for: platform.wrappedValue).filter(\.is2026)
            .sorted { ($0.date ?? "9999") > ($1.date ?? "9999") }
    }

    private var popularGames: [Game] {
        catalog.games(for: platform.wrappedValue).filter { !$0.is2026 }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        Text("Hangi ülkenin mağazasında daha ucuz? Platformunu seç, oyununu ara.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        PlatformPicker(selection: platform)

                        if query.isEmpty {
                            gtaBanner
                            gameRail(title: "2026'nın oyunları", games: newGames)
                            gameRail(title: "Popüler oyunlar", games: popularGames)
                            footer
                        } else {
                            searchResults
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("Bölge Fiyat")
            .searchable(text: $query, prompt: "Oyun ara… GTA 6, FC 27, Elden Ring")
            .navigationDestination(for: Game.self) { game in
                GameDetailView(game: game, startPlatform: platform.wrappedValue)
            }
        }
    }

    // MARK: Bölümler

    @ViewBuilder
    private var gtaBanner: some View {
        if let gta = catalog.games.first(where: { $0.id.hasPrefix("grand-theft-auto-vi") }),
           let release = gta.releaseDate {
            let days = Calendar.current.dateComponents([.day],
                                                       from: Calendar.current.startOfDay(for: Date()),
                                                       to: release).day ?? 0
            NavigationLink(value: gta) {
                HStack(spacing: 14) {
                    GameCover(game: gta, size: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(bannerTitle(days: days)).font(.headline).foregroundStyle(.white)
                        Text("Bölge fiyatlarına bak").font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                }
                .padding(14)
                .glass(22, tint: .pink, interactive: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func bannerTitle(days: Int) -> String {
        if days > 1 { return "GTA VI \(days) gün sonra çıkıyor" }
        if days == 1 { return "GTA VI yarın çıkıyor" }
        if days == 0 { return "GTA VI bugün çıktı" }
        return "GTA VI çıktı"
    }

    private func gameRail(title: String, games: [Game]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, trailing: "\(games.count) oyun")
            if games.isEmpty {
                Text("Bu platformda henüz oyun yok.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16).glass(18)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(games) { g in
                            NavigationLink(value: g) {
                                GameCard(game: g, platform: platform.wrappedValue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let results = catalog.search(query)
        let here = results.filter { $0.isAvailable(on: platform.wrappedValue) }
        let elsewhere = results.filter { !$0.isAvailable(on: platform.wrappedValue) }

        VStack(alignment: .leading, spacing: 10) {
            if results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("“\(query)” listede yok").font(.headline)
                    Text("Fiyatını doğruladığımız oyunlar arasında bulunamadı. Mağazada doğrudan arayabilirsin:")
                        .font(.footnote).foregroundStyle(.secondary)
                    ForEach(["tr", "us"], id: \.self) { r in
                        if let url = platform.wrappedValue.storeURL(region: r, query: query),
                           let reg = catalog.region(r) {
                            Link(destination: url) {
                                Label("\(reg.flag) \(reg.name) mağazasında ara", systemImage: "arrow.up.right.square")
                            }
                            .glassButton()
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glass(20)
            }
            ForEach(here) { g in resultRow(g, note: nil) }
            if !elsewhere.isEmpty {
                Text("\(platform.wrappedValue.name)'da yok, şuralarda var:")
                    .font(.footnote).foregroundStyle(.secondary).padding(.top, 6)
                ForEach(elsewhere) { g in
                    resultRow(g, note: g.platforms.map(\.name).joined(separator: ", "))
                }
            }
        }
    }

    private func resultRow(_ g: Game, note: String?) -> some View {
        NavigationLink(value: g) {
            HStack(spacing: 12) {
                GameCover(game: g, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(g.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                    Text(note ?? (g.editions.count > 1 ? "\(g.year) · \(g.editions.count) sürüm" : g.year))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.footnote).foregroundStyle(.secondary)
            }
            .padding(12)
            .glass(18, interactive: true)
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        Text("Fiyatlar mağazaların standart liste fiyatlarıdır, indirimler dahil değildir. Yabancı para birimlerinin TL karşılığı yaklaşıktır. Başka ülkenin mağazasından almak o ülkeye ait hesap gerektirir ve mağaza kurallarına aykırı olabilir.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(14)
            .glass(18)
    }
}
