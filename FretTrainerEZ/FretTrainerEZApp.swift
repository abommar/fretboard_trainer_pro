import SwiftUI

@main
struct FretTrainerEZApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
            } else {
                OnboardingView { hasSeenOnboarding = true }
            }
        }
    }
}
