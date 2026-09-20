// MARK: - File: GeoAlarm/Tests/GeoAlarmTests.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  Unit tests for GeoAlarmEngine — the pure-Swift logic layer.
//
//  These tests validate:
//    1. Haversine distance calculation.
//    2. Region membership (inside/outside).
//    3. On-arrival trigger detection (outside → inside transition).
//    4. On-departure trigger detection (inside → outside transition).
//    5. No re-trigger for already-triggered alarms.
//    6. Multiple alarms evaluated simultaneously.
//    7. Interpolation helper for simulation.
//
//  How to run:
//    1. In Xcode, add a test target (File → New → Target → Unit Testing Bundle).
//    2. Add this file to the test target.
//    3. Make sure the main app module is imported (@testable import GeoAlarm).
//    4. Press ⌘U to run all tests.
//
//  Because we're developing on Windows without a Swift runtime, these tests
//  are written to compile cleanly on Xcode 15+ / Swift 5.9+ and should
//  pass on the first run.
// ═══════════════════════════════════════════════════════════════════════════════

import XCTest
@testable import GeoAlarm

final class GeoAlarmEngineTests: XCTestCase {

    // MARK: - Test Coordinates

    //  "Home" preset:      37.7749, -122.4194
    //  "School" preset:    37.7855, -122.4064
    //  A point far away:   37.80,   -122.45   (roughly 3 km north-west of Home)
    //  A point very close: 37.7750, -122.4195 (~ 15 m from Home)

    let home      = SimpleCoordinate(latitude: 37.7749,  longitude: -122.4194)
    let school    = SimpleCoordinate(latitude: 37.7855,  longitude: -122.4064)
    let farAway   = SimpleCoordinate(latitude: 37.80,    longitude: -122.45)
    let nearHome  = SimpleCoordinate(latitude: 37.77495, longitude: -122.41945)

    // MARK: - Distance Tests

    /// Test 1: Haversine distance between two known points is within expected range.
    ///
    /// Home → School is roughly 1.5–1.7 km.
    func testDistanceHomeToSchool() {
        let distance = GeoAlarmEngine.haversineDistance(from: home, to: school)
        // Should be approximately 1,600 m (±200 m for rounding).
        XCTAssertGreaterThan(distance, 1200, "Home→School should be > 1.2 km")
        XCTAssertLessThan(distance, 2000,    "Home→School should be < 2.0 km")
    }

    /// Test 2: Distance from a point to itself is zero.
    func testDistanceToSelfIsZero() {
        let distance = GeoAlarmEngine.haversineDistance(from: home, to: home)
        XCTAssertEqual(distance, 0, accuracy: 0.001)
    }

    /// Test 3: A point ~15 m away should report a small distance.
    func testDistanceNearby() {
        let distance = GeoAlarmEngine.haversineDistance(from: home, to: nearHome)
        XCTAssertLessThan(distance, 50, "Near-home point should be < 50 m from home")
    }

    // MARK: - Region Tests

    /// Test 4: A point within 250 m of an alarm center is inside the region.
    func testInsideRegion() {
        let alarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        let result = GeoAlarmEngine.isInsideRegion(location: nearHome, alarm: alarm)
        XCTAssertTrue(result, "nearHome should be inside a 250 m radius of home")
    }

    /// Test 5: A point far away is outside the region.
    func testOutsideRegion() {
        let alarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        let result = GeoAlarmEngine.isInsideRegion(location: school, alarm: alarm)
        XCTAssertFalse(result, "School should be outside a 250 m radius of home")
    }

    // MARK: - Trigger Tests

    /// Test 6: Moving from outside → inside triggers an .onArrival alarm.
    func testOnArrivalTrigger() {
        let alarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        // Start far away, end near home.
        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: farAway,
            currentLocation: nearHome
        )
        XCTAssertTrue(triggered.contains(alarm.id),
                      "On-arrival alarm should trigger when moving from outside to inside")
    }

    /// Test 7: Moving from inside → outside triggers an .onDeparture alarm.
    func testOnDepartureTrigger() {
        let alarm = makeAlarm(at: home, radius: 250, triggerType: .onDeparture)
        // Start near home, end far away.
        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: nearHome,
            currentLocation: farAway
        )
        XCTAssertTrue(triggered.contains(alarm.id),
                      "On-departure alarm should trigger when moving from inside to outside")
    }

    /// Test 8: Staying inside does not trigger an .onArrival alarm (no transition).
    func testStayingInsideDoesNotTriggerArrival() {
        let alarm = makeAlarm(at: home, radius: 500, triggerType: .onArrival)
        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: nearHome,
            currentLocation: nearHome  // still inside
        )
        XCTAssertTrue(triggered.isEmpty,
                      "Staying inside should not trigger an on-arrival alarm")
    }

    /// Test 9: Staying outside does not trigger an .onDeparture alarm.
    func testStayingOutsideDoesNotTriggerDeparture() {
        let alarm = makeAlarm(at: home, radius: 250, triggerType: .onDeparture)
        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: farAway,
            currentLocation: school  // still outside
        )
        XCTAssertTrue(triggered.isEmpty,
                      "Staying outside should not trigger an on-departure alarm")
    }

    /// Test 10: An already-triggered alarm is NOT re-triggered.
    func testNoRetriggerForTriggeredAlarm() {
        var alarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        alarm.status = .triggered(Date())

        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: farAway,
            currentLocation: nearHome
        )
        XCTAssertTrue(triggered.isEmpty,
                      "Already-triggered alarm must not re-trigger")
    }

    /// Test 11: A disabled alarm is NOT triggered.
    func testDisabledAlarmDoesNotTrigger() {
        var alarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        alarm.isActive = false
        alarm.status = .disabled

        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: farAway,
            currentLocation: nearHome
        )
        XCTAssertTrue(triggered.isEmpty, "Disabled alarm must not trigger")
    }

    /// Test 12: Multiple alarms — only the correct subset triggers.
    func testMultipleAlarms() {
        let arrivalAlarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        let departureAlarm = makeAlarm(at: home, radius: 250, triggerType: .onDeparture)

        // Moving from outside → inside: only the arrival alarm should fire.
        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [arrivalAlarm, departureAlarm],
            previousLocation: farAway,
            currentLocation: nearHome
        )
        XCTAssertTrue(triggered.contains(arrivalAlarm.id))
        XCTAssertFalse(triggered.contains(departureAlarm.id))
    }

    /// Test 13: First location update (nil previous) triggers arrival if inside.
    func testFirstUpdateInsideTriggersArrival() {
        let alarm = makeAlarm(at: home, radius: 250, triggerType: .onArrival)
        let triggered = GeoAlarmEngine.evaluateTriggers(
            alarms: [alarm],
            previousLocation: nil,     // first fix
            currentLocation: nearHome  // already inside
        )
        XCTAssertTrue(triggered.contains(alarm.id),
                      "First update inside the region should trigger on-arrival")
    }

    // MARK: - Interpolation Tests

    /// Test 14: Interpolation at t=0 returns the start coordinate.
    func testInterpolationAtZero() {
        let result = GeoAlarmEngine.interpolate(from: home, to: school, t: 0)
        XCTAssertEqual(result.latitude, home.latitude, accuracy: 0.00001)
        XCTAssertEqual(result.longitude, home.longitude, accuracy: 0.00001)
    }

    /// Test 15: Interpolation at t=1 returns the end coordinate.
    func testInterpolationAtOne() {
        let result = GeoAlarmEngine.interpolate(from: home, to: school, t: 1)
        XCTAssertEqual(result.latitude, school.latitude, accuracy: 0.00001)
        XCTAssertEqual(result.longitude, school.longitude, accuracy: 0.00001)
    }

    /// Test 16: Interpolation at t=0.5 returns the midpoint.
    func testInterpolationMidpoint() {
        let result = GeoAlarmEngine.interpolate(from: home, to: school, t: 0.5)
        let expectedLat = (home.latitude + school.latitude) / 2
        let expectedLon = (home.longitude + school.longitude) / 2
        XCTAssertEqual(result.latitude, expectedLat, accuracy: 0.00001)
        XCTAssertEqual(result.longitude, expectedLon, accuracy: 0.00001)
    }

    /// Test 17: Interpolation clamps t outside [0, 1].
    func testInterpolationClamping() {
        let below = GeoAlarmEngine.interpolate(from: home, to: school, t: -0.5)
        XCTAssertEqual(below.latitude, home.latitude, accuracy: 0.00001)

        let above = GeoAlarmEngine.interpolate(from: home, to: school, t: 1.5)
        XCTAssertEqual(above.latitude, school.latitude, accuracy: 0.00001)
    }

    // MARK: - Helper

    /// Creates a test alarm at the given coordinate.
    private func makeAlarm(
        at coord: SimpleCoordinate,
        radius: Double = 250,
        triggerType: TriggerType
    ) -> GeoAlarm {
        GeoAlarm(
            title: "Test Alarm",
            triggerType: triggerType,
            latitude: coord.latitude,
            longitude: coord.longitude,
            radius: radius,
            locationName: "Test Location"
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Conceptual Scenario Tests (documented in comments)
// ═══════════════════════════════════════════════════════════════════════════════
//
// These scenarios describe end-to-end flows that require the full app running
// on a device or simulator. They are documented here so a reviewer can
// manually verify them.
//
// ── Scenario A: Permission Denied → Simulation Mode ─────────────────────────
//  1. Launch the app for the first time.
//  2. On the onboarding's permission page, tap "Skip — Use Simulation Mode"
//     OR deny the system location prompt.
//  3. Expected: HomeView shows an orange "Simulation Mode" banner.
//  4. Tap "+" to create an alarm:
//       Title: "Arrive Home"
//       Trigger: On Arrival
//       Location: Home preset
//       Radius: 250 m
//  5. Tap "Save". The alarm appears in the list with "Waiting" status.
//  6. Tap "Controls" on the Simulation banner.
//  7. In SimulationControlView:
//       a. Select "Walk Toward Alarm" → "Arrive Home".
//       b. Drag the slider from 0 toward 1.
//  8. Expected: When the simulated position enters the 250 m radius,
//     an alert appears: "🔔 Alarm Triggered! Arrive Home".
//  9. Tap "Dismiss" or "Reset Alarm" to reset the alarm.
//
// ── Scenario B: Permission Granted → Real Location Mode ─────────────────────
//  1. Launch the app and grant location permission.
//  2. Expected: HomeView shows a green "Real Location Mode" banner.
//  3. Create an alarm near your current location.
//  4. Walk (in real life) into the alarm's region.
//  5. Expected: The alarm triggers with an in-app alert.
//  6. Note: This requires a real device and physical movement, or the
//     Xcode Simulator's "Simulate Location" > "Custom Location" feature.
//
// ── Scenario C: Toggle Simulation On While Authorized ───────────────────────
//  1. With location permission granted, open Settings.
//  2. Toggle "Simulation Mode" ON.
//  3. Expected: Banner changes to orange "Simulation Mode".
//  4. GPS stops updating; simulated location is used instead.
//  5. Use Simulation Controls to trigger alarms from a desk.
//  6. Toggle "Simulation Mode" OFF.
//  7. Expected: Banner returns to green; real GPS resumes.
//
// ── Scenario D: Empty State ───────────────────────────────────────────────────
//  1. Launch app with no saved alarms.
//  2. Expected: HomeView shows a friendly empty state:
//     "No GeoAlarms Yet. Tap + to create your first location-based reminder."
//
// ── Scenario E: Multiple Alarms at Similar Locations ────────────────────────
//  1. Create two alarms both centered at "Home" with 250 m radius:
//       Alarm 1: "Text Mom" — On Arrival
//       Alarm 2: "Start Laundry" — On Arrival
//  2. Simulate moving into the Home region.
//  3. Expected: Both alarms trigger (one alert at a time;
//     the second shows after dismissing the first, or both appear in the list
//     as "Triggered").
//
// ═══════════════════════════════════════════════════════════════════════════════
