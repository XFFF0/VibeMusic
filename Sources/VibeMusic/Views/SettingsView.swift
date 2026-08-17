import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var player: PlayerService
    @State private var streamQuality = 1   // 0=low, 1=high, 2=ultra
    @State private var downloadOnWifi = true
    @State private var showAbout = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings").font(.system(size: 28, weight: .black)).foregroundStyle(Color.vText)
                    .padding(.horizontal, 20).padding(.top, 60)

                // Playback
                SettingsSection(title: "Playback") {
                    SettingsPicker(icon: "hifispeaker.fill", label: "Stream Quality",
                                   options: ["Standard", "High (256kbps)", "Ultra (320kbps)"],
                                   selected: $streamQuality)
                    Divider().background(Color.vStroke).padding(.leading, 52)
                    SettingsToggle(icon: "wifi", label: "Download over WiFi only", value: $downloadOnWifi)
                }

                // Sources
                SettingsSection(title: "Music Sources") {
                    SettingsInfo(icon: "play.rectangle.fill", label: "YouTube", value: "Via Invidious API")
                    Divider().background(Color.vStroke).padding(.leading, 52)
                    SettingsInfo(icon: "cloud.fill", label: "SoundCloud", value: "Public API")
                }

                // Storage
                SettingsSection(title: "Storage") {
                    SettingsInfo(icon: "internaldrive.fill", label: "Downloaded Songs",
                                 value: "\(LibraryService.shared.downloads.count) tracks")
                    Divider().background(Color.vStroke).padding(.leading, 52)
                    Button {
                        // Clear cache
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "trash.fill").font(.system(size: 16)).foregroundStyle(.red).frame(width: 26)
                            Text("Clear Cache").font(.system(size: 15)).foregroundStyle(.red)
                            Spacer()
                        }.padding(.horizontal, 16).padding(.vertical, 13)
                    }
                }

                // About
                SettingsSection(title: "About") {
                    SettingsInfo(icon: "info.circle.fill", label: "Version", value: "1.0.0")
                    Divider().background(Color.vStroke).padding(.leading, 52)
                    SettingsInfo(icon: "waveform.circle.fill", label: "Vibe Music", value: "Open Source")
                }

                Spacer(minLength: 150)
            }
        }
        .background(Color.vBG.ignoresSafeArea())
    }
}

struct SettingsSection<Content: View>: View {
    let title: String; @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.vHint)
                .padding(.horizontal, 24)
            VStack(spacing: 0) { content }.glassCard(radius: 14).padding(.horizontal, 20)
        }
    }
}

struct SettingsInfo: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color.vGreen).frame(width: 26)
            Text(label).font(.system(size: 15)).foregroundStyle(Color.vText)
            Spacer()
            Text(value).font(.system(size: 13)).foregroundStyle(Color.vSubtext)
        }.padding(.horizontal, 16).padding(.vertical, 13)
    }
}

struct SettingsPicker: View {
    let icon: String; let label: String; let options: [String]; @Binding var selected: Int
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color.vGreen).frame(width: 26)
            Text(label).font(.system(size: 15)).foregroundStyle(Color.vText)
            Spacer()
            Menu {
                ForEach(0..<options.count, id: \.self) { i in
                    Button { selected = i } label: {
                        HStack { Text(options[i]); if selected == i { Image(systemName: "checkmark") } }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(options[selected]).font(.system(size: 13)).foregroundStyle(Color.vSubtext)
                    Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(Color.vHint)
                }
            }
        }.padding(.horizontal, 16).padding(.vertical, 13)
    }
}

struct SettingsToggle: View {
    let icon: String; let label: String; @Binding var value: Bool
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color.vGreen).frame(width: 26)
            Text(label).font(.system(size: 15)).foregroundStyle(Color.vText)
            Spacer()
            Toggle("", isOn: $value).tint(Color.vGreen).labelsHidden()
        }.padding(.horizontal, 16).padding(.vertical, 8)
    }
}
