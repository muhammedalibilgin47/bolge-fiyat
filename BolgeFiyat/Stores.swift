import SwiftUI

// MARK: - Katalog (oyunlar + fiyatlar)

final class CatalogStore: ObservableObject {
    @Published private(set) var catalog: Catalog

    init() {
        if let url = Bundle.main.url(forResource: "games", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(Catalog.self, from: data) {
            catalog = decoded
        } else {
            catalog = Catalog(updated: "-", usdTry: 50, fx: ["USD": 1], symbols: ["USD": "$"], regions: [], games: [])
        }
    }

    var games: [Game] { catalog.games }

    func region(_ id: String) -> Region? { catalog.regions.first { $0.id == id } }

    /// Bazı mağazalar o ülkede dolarla satar.
    func currency(platform: Platform, region: String) -> String {
        if platform == .steam && (region == "tr" || region == "ar") { return "USD" }
        if platform == .ps && region == "ar" { return "USD" }
        return self.region(region)?.cur ?? "USD"
    }

    func rows(game: Game, edition: Edition, platform: Platform) -> [PriceRow] {
        guard let prices = edition.prices[platform.rawValue] else { return [] }
        return prices.compactMap { entry -> PriceRow? in
            guard let reg = region(entry.key) else { return nil }
            let cur = currency(platform: platform, region: entry.key)
            let rate = catalog.fx[cur] ?? 1
            return PriceRow(region: reg, local: entry.value, currency: cur, usd: entry.value * rate)
        }
        .sorted { $0.usd < $1.usd }
    }

    /// Oyunun bir platformdaki en ucuz satırı (ilk uygun sürüm)
    func cheapest(game: Game, platform: Platform) -> PriceRow? {
        guard let ed = game.editions(for: platform).first else { return nil }
        return rows(game: game, edition: ed, platform: platform).first
    }

    func games(for platform: Platform) -> [Game] {
        games.filter { $0.isAvailable(on: platform) }
    }

    func search(_ text: String) -> [Game] {
        let t = Self.normalize(text)
        guard !t.isEmpty else { return [] }
        return games.filter { g in
            Self.normalize(g.name).contains(t) ||
            g.aliases.contains { a in
                let na = Self.normalize(a)
                return na.contains(t) || t.contains(na)
            }
        }
    }

    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
        let mapped = folded.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(mapped).split(separator: " ").joined(separator: " ")
    }

    // MARK: Biçimlendirme

    static func number(_ v: Double, decimals: Bool) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals ? 2 : 0
        f.maximumFractionDigits = decimals ? 2 : 0
        return f.string(from: NSNumber(value: v)) ?? String(v)
    }

    func local(_ v: Double, currency: String) -> String {
        let whole = ["JPY", "INR", "ARS", "UAH", "TRY", "ZAR"].contains(currency) && v.rounded() == v
        let sym = catalog.symbols[currency] ?? currency + " "
        return sym + Self.number(v, decimals: !whole)
    }

    func converted(usd: Double, unit: DisplayUnit) -> String {
        switch unit {
        case .tl: return "₺" + Self.number((usd * catalog.usdTry).rounded(), decimals: false)
        case .usd: return "$" + Self.number(usd, decimals: true)
        }
    }

    /// Satırın ana fiyat metni: TL modunda Türkiye satırı tam fiyat, diğerleri yaklaşık.
    func display(_ row: PriceRow, unit: DisplayUnit) -> String {
        if unit == .tl && row.currency == "TRY" { return local(row.local, currency: "TRY") }
        if unit == .usd && row.currency == "USD" { return local(row.local, currency: "USD") }
        return "≈ " + converted(usd: row.usd, unit: unit)
    }
}

// MARK: - Pro abonelik (şimdilik ödemesiz deneme)

enum ProPlan: String, CaseIterable, Identifiable {
    case monthly, yearly
    var id: String { rawValue }
    var title: String { self == .monthly ? "Aylık" : "Yıllık" }
    var price: String { self == .monthly ? "49,99 ₺ / ay" : "399,99 ₺ / yıl" }
    var badge: String? { self == .yearly ? "%33 tasarruf" : nil }
}

final class ProStore: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published private(set) var proUntil: Date?
    @Published private(set) var plan: ProPlan?
    @Published private(set) var wishlist: [String]

    init() {
        let t = defaults.double(forKey: "proUntil")
        proUntil = t > 0 ? Date(timeIntervalSince1970: t) : nil
        plan = defaults.string(forKey: "proPlan").flatMap(ProPlan.init(rawValue:))
        wishlist = defaults.stringArray(forKey: "wishlist") ?? []
    }

    var isPro: Bool { (proUntil ?? .distantPast) > Date() }

    var daysLeft: Int {
        guard let until = proUntil else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: until).day ?? 0)
    }

    func startTrial(_ plan: ProPlan) {
        let until = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        proUntil = until
        self.plan = plan
        defaults.set(until.timeIntervalSince1970, forKey: "proUntil")
        defaults.set(plan.rawValue, forKey: "proPlan")
    }

    func cancel() {
        proUntil = nil
        plan = nil
        defaults.removeObject(forKey: "proUntil")
        defaults.removeObject(forKey: "proPlan")
    }

    func isWished(_ id: String) -> Bool { wishlist.contains(id) }

    func toggleWish(_ id: String) {
        if let i = wishlist.firstIndex(of: id) { wishlist.remove(at: i) } else { wishlist.append(id) }
        defaults.set(wishlist, forKey: "wishlist")
    }
}
