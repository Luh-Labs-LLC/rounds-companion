import FirebaseAppCheck
import FirebaseCore
import SwiftData
import SwiftUI

@main
struct RoundsCompanionApp: App {
    init() {
        // App Check must be set up before FirebaseApp.configure().
        #if DEBUG
        // Debug builds print a debug token to the console; register it in the
        // Firebase console (App Check > Apps > Manage debug tokens). Never commit it.
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        // Release builds (including TestFlight) attest with App Attest.
        AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
        #endif
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Round.self, LoggedShot.self])
    }
}
