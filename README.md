# GeoAlarm

An iOS alarm app that goes off when you **arrive at** or **leave** a place, not at a set time. Pick a
spot on the map, choose a radius, choose arrival or departure, and the app tells you the moment you
cross that boundary.

Built for the Apple Swift Student Challenge, in SwiftUI and CoreLocation with no third-party
dependencies.

## Who it's for

Anyone who wants a reminder tied to a place instead of a clock: "tell me when I get to the grocery
store", "tell me when I've left the office". Because a phone in a review room can't go anywhere,
the app also ships a **Simulation Mode** that lets a reviewer move a virtual location around and
watch alarms fire without leaving their desk.

## What it does

| | |
|---|---|
| **Location alarms** | A title, a trigger type (arrival or departure), a target location and a radius (100 m, 250 m, 500 m or 1 km). |
| **Real location mode** | Reads the device's GPS through CoreLocation and detects when you cross into or out of an alarm's region. |
| **Simulation mode** | A virtual location you can teleport to a preset, type in as coordinates, or "walk" toward an alarm with a slider, with a live map. |
| **Graceful fallback** | If location permission is denied or unavailable, the app switches to Simulation Mode and says so with a banner. |
| **Onboarding** | A two-page intro explaining the idea and asking for permission. |
| **Persistence** | Alarms are stored as JSON in `UserDefaults`; there is no account and no server. |

### The part worth reading

`GeoAlarm/Services/GeoAlarmEngine.swift` holds all the trigger logic as pure Swift, with no UI or
CoreLocation types: a Haversine distance, a point-in-region check, and a function that takes the
previous and current position and works out which alarms just fired. Arrival is an
outside-to-inside transition, departure is inside-to-outside, and an alarm that has already fired
or is switched off stays quiet. Keeping it free of the framework is what makes it unit-testable, and
it is why Simulation Mode and real GPS can drive exactly the same code path.

## Tech stack

Swift 5.9+, SwiftUI, CoreLocation, MapKit, Combine, XCTest. iOS 17+ (the map view uses the newer
`Map` initialiser). No package dependencies.

## Project layout

```
GeoAlarm/
├── GeoAlarmApp.swift               @main entry point
├── DesignSystem.swift              colour, type and spacing tokens
├── Models/GeoAlarm.swift           alarm, trigger type, status, preset locations, radius options
├── Services/
│   ├── GeoAlarmEngine.swift        pure-Swift distance, region and trigger logic
│   ├── LocationManager.swift       CLLocationManager wrapper + simulation mode
│   └── GeoAlarmStore.swift         alarm CRUD, persistence, trigger evaluation
└── Views/                          onboarding, home, add/edit, map picker, simulation, settings
GeoAlarmTests/
└── GeoAlarmTests.swift             17 unit tests for the engine, plus 5 documented scenarios
```

## Running locally

There is no `.xcodeproj` in the repository, so you create the project and drop the sources in. You
need a Mac with **Xcode 15 or later**.

1. In Xcode, create a new **iOS App** project (SwiftUI interface, Swift language) named `GeoAlarm`.
2. Delete the generated `ContentView.swift` and the generated `@main` app file.
3. Drag in the contents of the `GeoAlarm/` folder (uncheck "Copy items if needed" if you want to
   keep editing them in place). **Do not** add `GeoAlarmTests/` to the app target: it imports
   XCTest and will not compile there.
4. Add a location permission string to the target's Info (or `Info.plist`):

   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>GeoAlarm needs your location to trigger alarms when you arrive at or leave specific places.</string>
   ```
5. Pick an iOS 17+ simulator or a device and press **Run** (⌘R).

On first launch, choose "Allow While Using App" for real GPS, or decline and the app opens in
Simulation Mode. To try it without leaving your chair, open Simulation Mode, create an alarm at a
preset such as "School", and drag the walk slider toward it.

Alarms are evaluated while the app is open in the foreground: a fired alarm shows an in-app alert.
It does not schedule system notifications or track location in the background.

### Tests

1. **File → New → Target → Unit Testing Bundle**.
2. Move `GeoAlarmTests/GeoAlarmTests.swift` into that target. If your app module is not named
   `GeoAlarm`, adjust the `@testable import GeoAlarm` line to match.
3. Press **⌘U**.

The suite was written without access to a Swift toolchain, so the first ⌘U is its first real run.
It covers the distance calculation, inside/outside checks, arrival and departure detection, the
no-retrigger and disabled-alarm cases, several alarms at once, and the simulation slider's
interpolation.

## Credits

Built for the Apple Swift Student Challenge.
