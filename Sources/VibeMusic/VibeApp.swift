import SwiftUI
import AVFoundation

@main
struct VibeApp: App {
    @StateObject private var player  = PlayerService.shared
    @StateObject private var library = LibraryService.shared

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(player)
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}
