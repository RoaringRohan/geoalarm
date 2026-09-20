// MARK: - File: GeoAlarm/GeoAlarmApp.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  This is the @main entry point for the app.
//
//  Architecture overview:
//    • `LocationManager` is created as a @StateObject and injected into the
//      environment so every view can access location state.
//    • `GeoAlarmStore` is created with a reference to the LocationManager so
//      it can react to location changes and evaluate alarm triggers.
//    • `AppState` tracks whether onboarding has been completed (persisted in
//      @AppStorage / UserDefaults).
//
//  Xcode integration:
//    1. Create a new SwiftUI iOS App project in Xcode 15+.
//    2. Delete the auto-generated ContentView.swift.
//    3. Replace the auto-generated @main App struct with this file's contents.
//    4. Add all other .swift files from the GeoAlarm folder.
//    5. In your Info.plist, add:
//         NSLocationWhenInUseUsageDescription =
//         "GeoAlarm needs your location to trigger alarms when you arrive at
//          or leave specific places."
//    6. Build & Run on Simulator or device.
//
//  Swift Playgrounds (.swiftpm) integration:
//    1. Open Swift Playgrounds on iPad or Mac.
//    2. Create a new App project.
//    3. Add all .swift files into the project.
//    4. Make sure this file is the entry point (@main).
//    5. In the project's Package.swift, the
//       `NSLocationWhenInUseUsageDescription` can be added via the
//       `infoPlistValues` parameter of the `.executableTarget`.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

@main
struct GeoAlarmApp: App {
    // MARK: State Objects

    /// The location service — created once, shared with all views.
    @StateObject private var locationManager = LocationManager()

    /// Tracks whether the user has completed onboarding.
    /// Persisted so the onboarding only shows on first launch.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: Body

    var body: some Scene {
        WindowGroup {
            // Create the store here so it can reference locationManager.
            // We use a wrapper view to bridge @StateObject creation timing.
            RootView(
                locationManager: locationManager,
                hasCompletedOnboarding: $hasCompletedOnboarding
            )
        }
    }
}

// MARK: - RootView
/// A thin wrapper that creates `GeoAlarmStore` after `LocationManager` is
/// available, then routes between onboarding and the main home screen.
struct RootView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var hasCompletedOnboarding: Bool

    /// The alarm store — created with the location manager so it can observe
    /// location changes.
    @StateObject private var alarmStore: GeoAlarmStore

    init(locationManager: LocationManager,
         hasCompletedOnboarding: Binding<Bool>) {
        self.locationManager = locationManager
        self._hasCompletedOnboarding = hasCompletedOnboarding
        // Initialize the store with the location manager.
        self._alarmStore = StateObject(
            wrappedValue: GeoAlarmStore(locationManager: locationManager)
        )
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .environmentObject(locationManager)
        .environmentObject(alarmStore)
        // Apply the rainforest-green tint app-wide so navigation bars,
        // toggles, and default button tints all use our primary color.
        .tint(Color.appPrimary)
    }
}
