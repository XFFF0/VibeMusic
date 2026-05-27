import Foundation
import GoogleSignIn
import Combine

@MainActor
class GoogleAuthService: ObservableObject {
    static let shared = GoogleAuthService()

    @Published var isSignedIn = false
    @Published var user: GIDGoogleUser?
    @Published var userProfile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    struct UserProfile: Codable {
        let id: String
        let name: String
        let email: String
        let avatarURL: String?
    }

    private init() {
        restorePreviousSignIn()
    }

    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            Task { @MainActor in
                if let user = user {
                    self?.handleSignIn(user: user)
                }
            }
        }
    }

    func signIn(presenting viewController: UIViewController) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: [
                    "https://www.googleapis.com/auth/youtube.readonly",
                    "https://www.googleapis.com/auth/youtube.force-ssl"
                ]
            )
            handleSignIn(user: result.user)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        user = nil
        userProfile = nil
        LibraryService.shared.clearUserData()
    }

    private func handleSignIn(user: GIDGoogleUser) {
        self.user = user
        self.isSignedIn = true
        self.userProfile = UserProfile(
            id: user.userID ?? "",
            name: user.profile?.name ?? "User",
            email: user.profile?.email ?? "",
            avatarURL: user.profile?.imageURL(withDimension: 200)?.absoluteString
        )
        LibraryService.shared.syncFromCloud()
    }

    var accessToken: String? {
        user?.accessToken.tokenString
    }
}
