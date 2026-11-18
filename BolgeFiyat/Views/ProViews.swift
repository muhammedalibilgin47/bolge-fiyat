import SwiftUI

// MARK: - Abonelik ekranı (ödeme henüz bağlı değil: 7 günlük ücretsiz deneme)

struct PaywallView: View {
    @EnvironmentObject var pro: ProStore
    @Environment(\.dismiss) private var dismiss
    @State private var plan: ProPlan = .yearly

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                            .padding(22)
                            .glass(40, tint: .orange)
                        Text("Bölge Fiyat Pro").font(.largeTitle.weight(.heavy))
                        Text("Her oyunun her bölgedeki fiyatını gör, en ucuzunu kaçırma.")
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)

                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(ProFeatures.all) { f in
                            FeatureRow(icon: f.icon, title: f.title, detail: f.detail)
                        }
                    }
                    .padding(18)
                    .glass(24)

                    VStack(spacing: 10) {
                        ForEach(ProPlan.allCases) { p in
                            Button { withAnimation(.snappy) { plan = p } } label: {
                                HStack {
                                    Image(systemName: plan == p ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(plan == p ? Color.accentGreen : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.title).font(.headline)
                                        Text(p.price).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let b = p.badge {
                                        Text(b).font(.caption.weight(.bold))
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Color.accentGreen, in: Capsule())
                                            .foregroundStyle(.black)
                                    }
                                }
                                .foregroundStyle(.white)
                                .padding(16)
                                .glass(20, tint: plan == p ? .green : nil, interactive: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        pro.startTrial(plan)
                        dismiss()
                    } label: {
                        Text("7 gün ücretsiz başlat")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .glassButton(prominent: true, tint: .green)
                    .controlSize(.large)

                    Text("Ödeme sistemi henüz bağlı değil. Deneme süresince tüm Pro özellikler açık ve senden hiçbir ücret alınmaz.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)

                    Button("Şimdi değil") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Pro sekmesi

struct ProView: View {
    @EnvironmentObject var pro: ProStore
    @EnvironmentObject var catalog: CatalogStore
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        statusCard

                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pro'da neler var?").font(.headline)
                            ForEach(ProFeatures.all) { f in
                                FeatureRow(icon: f.icon, title: f.title, detail: f.detail)
                            }
                        }
                        .padding(18)
                        .glass(24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hakkında").font(.headline)
                            Text("\(catalog.games.count) oyun, 12 bölge, 4 platform. Fiyatlar \(catalog.catalog.updated) tarihli mağaza verilerinden alınmıştır; indirimler dahil değildir. 1 $ ≈ \(CatalogStore.number(catalog.catalog.usdTry, decimals: true)) ₺ kuruyla çevrilir.")
                                .font(.footnote).foregroundStyle(.secondary)
                            Text("Başka ülkenin mağazasından almak o ülkeye ait hesap ve genelde o ülkenin hediye kartını gerektirir; bu, mağaza kurallarına aykırı olabilir.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .glass(24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Pro")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private var statusCard: some View {
        if pro.isPro {
            VStack(alignment: .leading, spacing: 12) {
                HStack { ProBadge(); Spacer() }
                Text("Pro aktif").font(.title2.weight(.bold))
                Text("\(pro.plan?.title ?? "") plan · ücretsiz deneme · \(pro.daysLeft) gün kaldı")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button(role: .destructive) { pro.cancel() } label: {
                    Text("Denemeyi bitir").frame(maxWidth: .infinity)
                }
                .glassButton()
            }
            .padding(18)
            .glass(24, tint: .orange)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ücretsiz sürümdesin").font(.title2.weight(.bold))
                Text("En ucuz bölge ve Türkiye fiyatı herkese açık. Tüm bölgeler, sürümler, karşılaştırma ve istek listesi Pro'da.")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button { showPaywall = true } label: {
                    Label("Pro'yu 7 gün ücretsiz dene", systemImage: "crown.fill")
                        .frame(maxWidth: .infinity)
                }
                .glassButton(prominent: true, tint: .orange)
                .controlSize(.large)
            }
            .padding(18)
            .glass(24)
        }
    }
}

// MARK: - İstek listesi (Pro)

struct WishlistView: View {
    @EnvironmentObject var pro: ProStore
    @EnvironmentObject var catalog: CatalogStore
    @AppStorage("unit") private var unitRaw: String = DisplayUnit.tl.rawValue
    @State private var showPaywall = false

    private var games: [Game] {
        pro.wishlist.compactMap { id in catalog.games.first { $0.id == id } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 12) {
                        if !pro.isPro {
                            VStack(spacing: 14) {
                                Image(systemName: "heart.text.square.fill").font(.system(size: 44)).foregroundStyle(.pink)
                                Text("İstek listesi Pro'da").font(.title3.weight(.bold))
                                Text("Oyunlarını kaydet, hepsinin en ucuz bölgesini tek ekranda gör.")
                                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                                Button("Pro'yu ücretsiz dene") { showPaywall = true }
                                    .glassButton(prominent: true, tint: .pink)
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .glass(26)
                        } else if games.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "heart").font(.system(size: 40)).foregroundStyle(.secondary)
                                Text("Listen boş").font(.headline)
                                Text("Bir oyunun sayfasındaki kalp simgesine dokunarak ekle.")
                                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            }
                            .padding(24).frame(maxWidth: .infinity).glass(26)
                        } else {
                            ForEach(games) { g in
                                NavigationLink(value: g) { wishRow(g) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Listem")
            .navigationDestination(for: Game.self) { g in
                GameDetailView(game: g, startPlatform: g.platforms.first ?? .ps)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private func wishRow(_ g: Game) -> some View {
        let best = g.platforms
            .compactMap { p -> (Platform, PriceRow)? in
                guard let row = catalog.cheapest(game: g, platform: p) else { return nil }
                return (p, row)
            }
            .min { $0.1.usd < $1.1.usd }
        return HStack(spacing: 12) {
            GameCover(game: g, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text(g.name).font(.subheadline.weight(.semibold)).foregroundStyle(.white)
                if let best {
                    Text("En ucuz: \(best.0.name) · \(best.1.region.flag) \(best.1.region.name)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let best {
                Text(catalog.display(best.1, unit: DisplayUnit(rawValue: unitRaw) ?? .tl))
                    .font(.headline).foregroundStyle(Color.accentGreen)
            }
            Button { pro.toggleWish(g.id) } label: {
                Image(systemName: "heart.fill").foregroundStyle(.pink)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Listeden çıkar")
        }
        .padding(14)
        .glass(20, interactive: true)
    }
}
