// MARK: - File: GeoAlarm/Services/LocationManager.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  LocationManager is an ObservableObject that wraps CLLocationManager.
//
//  Responsibilities:
//    1. Request location authorization and track its status reactively.
//    2. Provide continuous location updates when authorized.
//    3. Manage a **Simulation Mode** that works identically from the UI's
//       perspective — when simulation is on, `effectiveLocation` returns the
//       simulated coordinate instead of the real one.
//    4. Automatically fall back to simulation when permission is denied,
//       restricted, or location services are unavailable.
//
//  Integration:
//    Add to your Xcode project's "Services" group.
//    Requires `NSLocationWhenInUseUsageDescription` in Info.plist.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation
import CoreLocation
import Combine

/// Wraps CLLocationManager into a SwiftUI-friendly ObservableObject.
///
/// Observers (views, stores) watch:
///   • `authorizationStatus`  — to show permission banners.
///   • `effectiveLocation`    — the coordinate the app should treat as "current."
///   • `isSimulationMode`     — to display the correct mode badge.
///   • `previousEffectiveLocation` — used by GeoAlarmEngine for transition detection.
class LocationManager: NSObject, ObservableObject {

    // MARK: Published Properties

    /// The current CLAuthorizationStatus, published so views can react.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// The latest real device location (nil until the first fix).
    @Published var currentRealLocation: CLLocationCoordinate2D?

    /// Whether the app is in Simulation Mode.
    ///
    /// This is `true` when:
    ///   - Location permission is denied or restricted.
    ///   - Location services are entirely unavailable.
    ///   - The user manually toggled simulation in Settings.
    @Published var isSimulationMode: Bool = false

    /// The position the user chose in simulation mode.
    /// Defaults to the "Home" preset so the app is immediately usable.
    @Published var simulatedLocation: CLLocationCoordinate2D = PresetLocation.presets[0].coordinate

    /// Tracks the previous effective location for trigger transition detection.
    @Published var previousEffectiveLocation: CLLocationCoordinate2D?

    // MARK: Derived Property

    /// The location the rest of the app should use.
    /// In Real mode it's the GPS fix; in Simulation mode it's the simulated pin.
    var effectiveLocation: CLLocationCoordinate2D? {
        isSimulationMode ? simulatedLocation : currentRealLocation
    }

    // MARK: Private

    /// The underlying CoreLocation manager.
    private let clManager = CLLocationManager()

    // MARK: Init

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        // Read initial status synchronously; delegate will update it later.
        authorizationStatus = clManager.authorizationStatus
        updateModeForAuthorizationStatus()
    }

    // MARK: Public API

    /// Requests when-in-use authorization. Call this from the PermissionView
    /// or onboarding flow. The result arrives asynchronously via the delegate.
    func requestAuthorization() {
        clManager.requestWhenInUseAuthorization()
    }

    /// Starts continuous location updates (only useful in Real mode).
    func startUpdating() {
        guard !isSimulationMode else { return }
        clManager.startUpdatingLocation()
    }

    /// Stops continuous location updates.
    func stopUpdating() {
        clManager.stopUpdatingLocation()
    }

    /// Updates the simulated location and stores the previous one.
    ///
    /// Call this from `SimulationControlView` whenever the user moves the
    /// simulated pin or selects a preset.
    ///
    /// - Parameter newLocation: The new simulated coordinate.
    func updateSimulatedLocation(_ newLocation: CLLocationCoordinate2D) {
        previousEffectiveLocation = simulatedLocation
        simulatedLocation = newLocation
    }

    /// Allows the user to turn simulation mode on/off manually (from Settings).
    ///
    /// When turning simulation OFF, the manager starts real updates if authorized.
    /// When turning simulation ON, it stops real updates.
    func setSimulationMode(_ on: Bool) {
        isSimulationMode = on
        if on {
            stopUpdating()
        } else if authorizationStatus == .authorizedWhenInUse ||
                  authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }

    // MARK: Private Helpers

    /// Decides whether simulation mode should be forced based on authorization.
    private func updateModeForAuthorizationStatus() {
        switch authorizationStatus {
        case .denied, .restricted:
            isSimulationMode = true
        case .authorizedWhenInUse, .authorizedAlways:
            // Only switch to real if user hasn't manually chosen simulation.
            break
        case .notDetermined:
            // Stay in whatever mode we're in.
            break
        @unknown default:
            isSimulationMode = true
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    /// Called whenever the authorization status changes.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = manager.authorizationStatus
            self.updateModeForAuthorizationStatus()

            // Auto-start updates if we just got authorized.
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                if !self.isSimulationMode {
                    self.startUpdating()
                }
            }
        }
    }

    /// Called with new location data from the GPS.
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.previousEffectiveLocation = self.currentRealLocation
            self.currentRealLocation = latest.coordinate
        }
    }

    /// Called when the location manager encounters an error.
    ///
    /// We treat errors gracefully: if we can't get a location, we fall back
    /// to simulation so the app remains fully usable.
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("LocationManager error: \(error.localizedDescription)")
        // Don't force simulation on transient errors; only on hard denials.
        if let clError = error as? CLError, clError.code == .denied {
            DispatchQueue.main.async { [weak self] in
                self?.isSimulationMode = true
            }
        }
    }
}
