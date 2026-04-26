import SwiftUI

struct RootView: View {
    @State private var session = AppSession()

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
                    .environment(session)
            } else {
                AuthView()
                    .environment(session)
            }
        }
    }
}

@Observable
final class AppSession {
    var isAuthenticated: Bool = false
    var userID: String?
    var displayName: String?
}

struct MainTabView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem { Label("피드", systemImage: "square.stack") }

            CaptureView()
                .tabItem { Label("촬영", systemImage: "camera") }

            RoomsView()
                .tabItem { Label("방", systemImage: "person.3") }
        }
    }
}

#Preview {
    RootView()
}
