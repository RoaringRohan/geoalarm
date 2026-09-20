// MARK: - File: GeoAlarm/Services/GeoAlarmStore.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  GeoAlarmStore is the single source of truth for all alarms in the app.
//
//  Responsibilities:
//    1. CRUD operations on the alarm list.
//    2. Persisting alarms to UserDefaults (simple; no Core Data needed for
//       a challenge project).
//    3. Reacting to location changes by calling `GeoAlarmEngine` to check
//       which alarms should trigger.
//    4. Exposing `triggeredAlarm` for the UI to show an alert/sheet.
//
//  Integration:
//    Inject as an @StateObject or @EnvironmentObject so all views share one
//    instance.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation
import CoreLocation
import Combine

class GeoAlarmStore: ObservableObject {

    // MARK: Published State

    /// All stored alarms.
    @Published var alarms: [GeoAlarm] = []

    /// The most recently triggered alarm, used to show an in-app alert.
    /// Set to `nil` after the user dismisses.
    @Published var triggeredAlarm: GeoAlarm?

    // MARK: Private

    /// Key for UserDefaults persistence.
    private static let storageKey = "com.geoalarm.savedAlarms"

    /// Cancellable subscription to location changes.
    private var cancellables = Set<AnyCancellable>()

    /// Reference to the LocationManager so we can observe location changes.
    private weak var locationManager: LocationManager?

    // MARK: Init

    /// Creates the store and optionally wires it to a LocationManager.
    ///
    /// - Parameter locationManager: The shared LocationManager instance.
    ///   Pass `nil` only in tests or previews where no location is needed.
    init(locationManager: LocationManager? = nil) {
        self.locationManager = locationManager
        loadAlarms()
        observeLocationChanges()
    }

    // MARK: CRUD

    /// Adds a new alarm, persists, and starts monitoring.
    func addAlarm(_ alarm: GeoAlarm) {
        alarms.append(alarm)
        saveAlarms()
    }

    /// Updates an existing alarm by its `id`.
    func updateAlarm(_ alarm: GeoAlarm) {
        if let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx] = alarm
            saveAlarms()
        }
    }

    /// Deletes alarms at the given index set (for SwiftUI `onDelete`).
    func deleteAlarms(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        saveAlarms()
    }

    /// Deletes a single alarm by ID.
    func deleteAlarm(id: UUID) {
        alarms.removeAll { $0.id == id }
        saveAlarms()
    }

    /// Resets a triggered alarm back to `.waiting` so it can fire again.
    func resetAlarm(id: UUID) {
        if let idx = alarms.firstIndex(where: { $0.id == id }) {
            alarms[idx].status = .waiting
            saveAlarms()
        }
    }

    /// Toggles an alarm's `isActive` flag.
    func toggleAlarm(id: UUID) {
        if let idx = alarms.firstIndex(where: { $0.id == id }) {
            alarms[idx].isActive.toggle()
            alarms[idx].status = alarms[idx].isActive ? .waiting : .disabled
            saveAlarms()
        }
    }

    // MARK: Trigger Evaluation

    /// Evaluates all alarms against a location transition.
    ///
    /// This is called automatically whenever the effective location changes.
    /// It can also be called manually for testing.
    ///
    /// - Parameters:
    ///   - previousLocation: Where the user was.
    ///   - currentLocation:  Where the user is now.
    func evaluateAlarms(previousLocation: CLLocationCoordinate2D?,
                        currentLocation: CLLocationCoordinate2D) {
        let prev = previousLocation.map {
            SimpleCoordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
        let curr = SimpleCoordinate(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude
        )

        let triggeredIDs = GeoAlarmEngine.evaluateTriggers(
            alarms: alarms,
            previousLocation: prev,
            currentLocation: curr
        )

        guard !triggeredIDs.isEmpty else { return }

        let now = Date()
        for id in triggeredIDs {
            if let idx = alarms.firstIndex(where: { $0.id == id }) {
                alarms[idx].status = .triggered(now)
            }
        }
        saveAlarms()

        // Surface the first triggered alarm for the alert.
        // (In a production app we might queue them; for the challenge one is fine.)
        if let firstID = triggeredIDs.first,
           let alarm = alarms.first(where: { $0.id == firstID }) {
            triggeredAlarm = alarm
        }
    }

    // MARK: Observation

    /// Subscribes to changes in LocationManager's effective location.
    private func observeLocationChanges() {
        guard let lm = locationManager else { return }

        // When in simulation mode, react to simulatedLocation changes.
        lm.$simulatedLocation
            .removeDuplicates { $0.latitude == $1.latitude && $0.longitude == $1.longitude }
            .sink { [weak self, weak lm] newLoc in
                guard let self = self, let lm = lm, lm.isSimulationMode else { return }
                self.evaluateAlarms(
                    previousLocation: lm.previousEffectiveLocation,
                    currentLocation: newLoc
                )
            }
            .store(in: &cancellables)

        // When in real mode, react to currentRealLocation changes.
        lm.$currentRealLocation
            .compactMap { $0 } // ignore nil
            .removeDuplicates { $0.latitude == $1.latitude && $0.longitude == $1.longitude }
            .sink { [weak self, weak lm] newLoc in
                guard let self = self, let lm = lm, !lm.isSimulationMode else { return }
                self.evaluateAlarms(
                    previousLocation: lm.previousEffectiveLocation,
                    currentLocation: newLoc
                )
            }
            .store(in: &cancellables)
    }

    // MARK: Persistence (UserDefaults — simple & sufficient for a challenge)

    /// Saves alarms to UserDefaults as JSON.
    private func saveAlarms() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    /// Loads alarms from UserDefaults.
    private func loadAlarms() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([GeoAlarm].self, from: data)
        else { return }
        alarms = decoded
    }
}
