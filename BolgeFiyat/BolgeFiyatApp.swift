import SwiftUI

@main
struct BolgeFiyatApp: App {
    @StateObject private var catalog = CatalogStore()
    @StateObject private var pro = ProStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(catalog)
                .environmentObject(pro)
                .preferredColorScheme(.dark)
                .tint(.accentGreen)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Keşfet", systemImage: "sparkle.magnifyingglass") }
            WishlistView()
                .tabItem { Label("Listem", systemImage: "heart") }
            ProView()
                .tabItem { Label("Pro", systemImage: "crown") }
        }
    }
}
