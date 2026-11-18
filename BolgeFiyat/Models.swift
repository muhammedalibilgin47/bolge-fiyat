import SwiftUI

// MARK: - Veri modelleri (Resources/games.json)

struct Region: Codable, Identifiable, Hashable {
    let id: String
    let flag: String
    let name: String
    let cur: String
}

struct SourceLink: Codable, Hashable {
    let title: String
    let url: String
}

struct Edition: Codable, Hashable {
    let name: String
    /// platform -> bölge -> mağaza fiyatı (mağazanın kendi para biriminde)
    let prices: [String: [String: Double]]
}

struct Game: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let aliases: [String]
    let date: String?
    let initials: String
    let editions: [Edition]
    let note: String?
    let sources: [SourceLink]

    func isAvailable(on platform: Platform) -> Bool {
        editions.contains { $0.prices[platform.rawValue] != nil }
    }

    func editions(for platform: Platform) -> [Edition] {
        editions.filter { $0.prices[platform.rawValue] != nil }
    }

    var platforms: [Platform] {
        Platform.allCases.filter { isAvailable(on: $0) }
    }

    var releaseDate: Date? {
        guard let date else { return nil }
        return DateFormatters.iso.date(from: date)
    }

    var year: String {
        if let date { return String(date.prefix(4)) }
        return "2026"
    }

    var is2026: Bool { date == nil || date!.hasPrefix("2026") }

    var isUpcoming: Bool {
        guard let d = releaseDate else { return false }
        return d > Calendar.current.startOfDay(for: Date())
    }

    var releaseText: String? {
        guard let d = releaseDate else { return nil }
        return DateFormatters.long.string(from: d)
    }

    /// İsimden türetilen sabit renk tonu (kapak görseli yerine)
    var hue: Double {
        var h: UInt32 = 0
        for s in name.unicodeScalars { h = h &* 31 &+ s.value }
        return Double(h % 360) / 360.0
    }

    var coverGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.7, brightness: 0.62),
                Color(hue: (hue + 0.14).truncatingRemainder(dividingBy: 1), saturation: 0.75, brightness: 0.28)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct Catalog: Codable {
    let updated: String
    let usdTry: Double
    let fx: [String: Double]
    let symbols: [String: String]
    let regions: [Region]
    let games: [Game]
}

struct PriceRow: Identifiable, Hashable {
    var id: String { region.id }
    let region: Region
    let local: Double
    let currency: String
    let usd: Double
}

// MARK: - Platformlar

enum Platform: String, CaseIterable, Identifiable, Codable {
    case ps, xbox, steam, nin

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ps: return "PlayStation"
        case .xbox: return "Xbox"
        case .steam: return "Steam"
        case .nin: return "Nintendo"
        }
    }

    var symbol: String {
        switch self {
        case .ps: return "playstation.logo"
        case .xbox: return "xbox.logo"
        case .steam: return "desktopcomputer"
        case .nin: return "gamecontroller.fill"
        }
    }

    var color: Color {
        switch self {
        case .ps: return Color(red: 0.18, green: 0.42, blue: 1.0)
        case .xbox: return Color(red: 0.18, green: 0.68, blue: 0.23)
        case .steam: return Color(red: 0.16, green: 0.62, blue: 0.85)
        case .nin: return Color(red: 0.91, green: 0.22, blue: 0.29)
        }
    }

    func storeURL(region: String, query: String) -> URL? {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let ps = ["us": "en-us", "tr": "en-tr", "ua": "uk-ua", "in": "en-in", "jp": "ja-jp", "br": "pt-br",
                  "ar": "es-ar", "pl": "pl-pl", "eu": "de-de", "uk": "en-gb", "za": "en-za", "mx": "es-mx"]
        let xb = ["us": "en-US", "tr": "tr-TR", "ua": "uk-UA", "in": "en-IN", "jp": "ja-JP", "br": "pt-BR",
                  "ar": "es-AR", "pl": "pl-PL", "eu": "de-DE", "uk": "en-GB", "za": "en-ZA", "mx": "es-MX"]
        let st = ["us": "us", "tr": "tr", "ua": "ua", "in": "in", "jp": "jp", "br": "br",
                  "ar": "ar", "pl": "pl", "eu": "de", "uk": "gb", "za": "za", "mx": "mx"]
        switch self {
        case .ps: return URL(string: "https://store.playstation.com/\(ps[region] ?? "en-us")/search/\(q)")
        case .xbox: return URL(string: "https://www.xbox.com/\(xb[region] ?? "en-US")/search?q=\(q)")
        case .steam: return URL(string: "https://store.steampowered.com/search/?term=\(q)&cc=\(st[region] ?? "us")")
        case .nin: return URL(string: "https://eshop-prices.com/games?q=\(q)")
        }
    }
}

enum DisplayUnit: String, CaseIterable, Identifiable {
    case tl, usd
    var id: String { rawValue }
    var label: String { self == .tl ? "₺ TL" : "$ USD" }
}

enum DateFormatters {
    static let iso: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static let long: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy"
        return f
    }()
}
