import SwiftUI
import GoogleSignIn

struct ProfileView: View {
    @EnvironmentObject var authService: GoogleAuthService
    @EnvironmentObject var playerService: AudioPlayerService

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(VibeColors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                if authService.isSignedIn, let profile = authService.userProfile {
                    // User card
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: profile.avatarURL ?? "")) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle().fill(VibeColors.surface)
                                .overlay(Image(systemName: "person.fill").font(.system(size: 32)).foregroundStyle(VibeColors.primary))
                        }
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(VibeColors.primary, lineWidth: 2))
                        .glowEffect()

                        VStack(spacing: 4) {
                            Text(profile.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(VibeColors.textPrimary)
                            Text(profile.email)
                                .font(.system(size: 14))
                                .foregroundStyle(VibeColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(cornerRadius: 20)
                    .padding(.horizontal, 20)

                    // Settings
                    VStack(spacing: 8) {
                        SettingsSection(title: "Playback") {
                            SettingsRow(icon: "hifispeaker.fill", title: "Audio Quality", value: playerService.quality.rawValue) {
                                // Open quality picker
                            }
                            SettingsRow(icon: "arrow.down.circle.fill", title: "Download Quality", value: "High (256kbps)") { }
                            SettingsRow(icon: "wifi.slash", title: "Offline Mode", value: "") { }
                        }

                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "icloud.and.arrow.up", title: "Sync Library", value: "On") { }
                            SettingsRow(icon: "trash.fill", title: "Clear Cache", value: formatBytes(DownloadService.shared.totalStorageUsed)) { }
                        }

                        SettingsSection(title: "About") {
                            SettingsRow(icon: "info.circle.fill", title: "Version", value: "1.0.0") { }
                            SettingsRow(icon: "heart.fill", title: "Rate Vibe Music", value: "") { }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Sign out
                    Button(action: { authService.signOut() }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .liquidGlass(cornerRadius: 16)
                    }
                    .padding(.horizontal, 20)

                } else {
                    // Sign in
                    VStack(spacing: 32) {
                        Spacer(minLength: 40)

                        VStack(spacing: 16) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 72))
                                .foregroundStyle(VibeColors.primary)
                                .glowEffect(radius: 24)

                            Text("Vibe Music")
                                .font(.system(size: 32, weight: .black))
                                .foregroundStyle(VibeColors.textPrimary)

                            Text("Sign in with Google to sync your library\nacross all devices")
                                .font(.system(size: 15))
                                .foregroundStyle(VibeColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        GoogleSignInButton()

                        Text("Your data stays private and synced securely")
                            .font(.system(size: 12))
                            .foregroundStyle(VibeColors.textTertiary)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer(minLength: 160)
            }
        }
        .background(VibeColors.background.ignoresSafeArea())
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}

struct GoogleSignInButton: View {
    @EnvironmentObject var authService: GoogleAuthService

    var body: some View {
        Button(action: signIn) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                Text(authService.isLoading ? "Signing in…" : "Continue with Google")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [VibeColors.primary, VibeColors.primaryGlow], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: VibeColors.primary.opacity(0.4), radius: 16)
        }
        .disabled(authService.isLoading)
    }

    private func signIn() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        Task { await authService.signIn(presenting: root) }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(VibeColors.textTertiary).padding(.leading, 8)
            VStack(spacing: 0) { content }
                .liquidGlass(cornerRadius: 16)
        }
    }
}

struct SettingsRow: View {
    let icon: String; let title: String; let value: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(VibeColors.primary).frame(width: 26)
                Text(title).font(.system(size: 15)).foregroundStyle(VibeColors.textPrimary)
                Spacer()
                if !value.isEmpty {
                    Text(value).font(.system(size: 13)).foregroundStyle(VibeColors.textTertiary)
                }
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(VibeColors.textTertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
        }
    }
}
