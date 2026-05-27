import SwiftUI
import GoogleSignIn

@main
struct VibeApp: App {
    @StateObject private var authService = GoogleAuthService.shared
    @StateObject private var playerService = AudioPlayerService.shared
    @StateObject private var libraryService = LibraryService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(playerService)
                .environmentObject(libraryService)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .preferredColorScheme(.dark)
        }
    }
}
