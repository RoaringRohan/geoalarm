// MARK: - File: GeoAlarm/Services/GeoAlarmEngine.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  GeoAlarmEngine contains **pure Swift** geometry and trigger-evaluation logic.
//  It has NO dependency on CoreLocation at runtime — it works with raw
//  latitude/longitude `Double` values.  This means:
//    1. It can be unit-tested without a device or simulator.
//    2. It powers both Real Location mode and Simulation mode identically.
//
//  Key methods:
//    • `haversineDistance`    — great-circle distance between two coordinates.
//    • `isInsideRegion`      — is a point within an alarm's radius?
//    • `evaluateTriggers`    — given a location change, which alarms should fire?
//
//  Integration:
//    Add this file to your Xcode project's "Services" group.
//    No external dependencies.
// ═══════════════════════════════════════════════════════════════════════════════

import Foundation

// MARK: - SimpleCoordinate
/// A lightweight coordinate type that avoids importing CoreLocation in
/// pure-logic contexts. We convert `CLLocationCoordinate2D` ↔ `SimpleCoordinate`
/// at the boundary between the location layer and the engine.
struct SimpleCoordinate: Equatable {
    let latitude: Double
    let longitude: Double
}

// MARK: - GeoAlarmEngine
/// A stateless engine that evaluates alarm triggers.
///
/// All methods are `static` so you never need to create an instance.
/// This makes the engine trivially testable and thread-safe.
enum GeoAlarmEngine {

    // MARK: Constants

    /// Mean radius of the Earth in meters (WGS-84 approximation).
    private static let earthRadiusMeters: Double = 6_371_000

    // MARK: Distance Calculation

    /// Returns the great-circle distance in **meters** between two coordinates
    /// using the Haversine formula.
    ///
    /// The Haversine formula is:
    /// ```
    /// a = sin²(Δlat/2) + cos(lat1) · cos(lat2) · sin²(Δlon/2)
    /// c = 2 · atan2(√a, √(1−a))
    /// d = R · c
    /// ```
    ///
    /// This is accurate to within ~0.5 % for typical alarm radii (< 10 km)
    /// and avoids importing CoreLocation's `CLLocation.distance(from:)`.
    ///
    /// - Parameters:
    ///   - from: The first coordinate.
    ///   - to:   The second coordinate.
    /// - Returns: Distance in meters.
    static func haversineDistance(from c1: SimpleCoordinate,
                                  to c2: SimpleCoordinate) -> Double {
        let lat1 = c1.latitude  * .pi / 180
        let lat2 = c2.latitude  * .pi / 180
        let dLat = (c2.latitude  - c1.latitude)  * .pi / 180
        let dLon = (c2.longitude - c1.longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2)
              + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusMeters * c
    }

    // MARK: Region Check

    /// Checks whether a given coordinate is inside an alarm's circular region.
    ///
    /// - Parameters:
    ///   - location: The coordinate to test.
    ///   - alarm: The alarm whose region we're checking.
    /// - Returns: `true` if `location` is within `alarm.radius` meters of
    ///   the alarm's center.
    static func isInsideRegion(location: SimpleCoordinate,
                               alarm: GeoAlarm) -> Bool {
        let center = SimpleCoordinate(
            latitude: alarm.latitude,
            longitude: alarm.longitude
        )
        let dist = haversineDistance(from: location, to: center)
        return dist <= alarm.radius
    }

    // MARK: Trigger Evaluation

    /// Evaluates which alarms should transition to `.triggered` given a
    /// location change.
    ///
    /// **Algorithm:**
    /// For each active, waiting alarm:
    /// 1. Compute whether `previousLocation` was inside/outside the region.
    /// 2. Compute whether `currentLocation` is inside/outside the region.
    /// 3. If the alarm's trigger type matches the transition, include it in
    ///    the returned set:
    ///    - `.onArrival`   → was outside, now inside  (entered the region).
    ///    - `.onDeparture` → was inside, now outside   (exited the region).
    ///
    /// Already-triggered or disabled alarms are **not** re-evaluated, which
    /// prevents annoying repeated triggers.
    ///
    /// - Parameters:
    ///   - alarms: All alarms to consider.
    ///   - previousLocation: Where the user was before this update (can be `nil`
    ///     on the very first location update).
    ///   - currentLocation: Where the user is now.
    /// - Returns: A `Set` of alarm `UUID`s that should be triggered.
    static func evaluateTriggers(
        alarms: [GeoAlarm],
        previousLocation: SimpleCoordinate?,
        currentLocation: SimpleCoordinate
    ) -> Set<UUID> {
        var triggered = Set<UUID>()

        for alarm in alarms {
            // Skip alarms that aren't active or are already triggered/disabled.
            guard alarm.isActive else { continue }
            guard case .waiting = alarm.status else { continue }

            let isNowInside = isInsideRegion(location: currentLocation, alarm: alarm)

            // If there is no previous location (first update), we can only
            // detect arrival by checking if the user is already inside.
            // We treat that as an arrival event for `.onArrival` alarms.
            guard let prev = previousLocation else {
                if alarm.triggerType == .onArrival && isNowInside {
                    triggered.insert(alarm.id)
                }
                continue
            }

            let wasInside = isInsideRegion(location: prev, alarm: alarm)

            switch alarm.triggerType {
            case .onArrival:
                // Transition: outside → inside
                if !wasInside && isNowInside {
                    triggered.insert(alarm.id)
                }
            case .onDeparture:
                // Transition: inside → outside
                if wasInside && !isNowInside {
                    triggered.insert(alarm.id)
                }
            }
        }

        return triggered
    }

    // MARK: - Interpolation Helper (Simulation)

    /// Returns a coordinate that is linearly interpolated between `from` and
    /// `to` by factor `t` (0 = from, 1 = to).
    ///
    /// This is used by the simulation slider to "walk" from one location to
    /// another. A simple linear interpolation on lat/lon is fine for the
    /// short distances we deal with in simulation.
    ///
    /// - Parameters:
    ///   - from: Start coordinate.
    ///   - to:   End coordinate.
    ///   - t:    Interpolation factor in [0, 1].
    /// - Returns: The interpolated coordinate.
    static func interpolate(from: SimpleCoordinate,
                            to: SimpleCoordinate,
                            t: Double) -> SimpleCoordinate {
        let clampedT = min(max(t, 0), 1)
        return SimpleCoordinate(
            latitude:  from.latitude  + (to.latitude  - from.latitude)  * clampedT,
            longitude: from.longitude + (to.longitude - from.longitude) * clampedT
        )
    }
}
