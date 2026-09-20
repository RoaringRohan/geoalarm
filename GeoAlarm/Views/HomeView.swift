// MARK: - File: GeoAlarm/Views/HomeView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  HomeView is the main screen of the app.
//
//  Design refinements (rainforest theme):
//    • Subtle gradient background (canopy top → lighter bottom).
//    • ModePill badge in the toolbar (amber=simulation, fern=real).
//    • Alarm rows rendered as themed cards with appCardModifier.
//    • Empty state uses appPrimary icon and appTextSecondary copy.
//    • Toolbar add/settings icons use appPrimary via the global tint.
//    • Triggered alarm alert wording unchanged (logic not touched).
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

struct HomeView: View {

    // MARK: Environment

    @EnvironmentObject var alarmStore: GeoAlarmStore
    @EnvironmentObject var locationManager: LocationManager

    // MARK: State

    /// Controls the Add Alarm sheet.
    @State private var showingAddAlarm = false

    /// Controls the Settings sheet.
    @State private var showingSettings = false

    /// Controls the Simulation Controls sheet.
    @State private var showingSimulation = false

    /// Controls the triggered-alarm alert.
    @State private var showingTriggeredAlert = false

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background that hints at a rainforest canopy.
                LinearGradient(
                    colors: [Color.appGradientTop, Color.appGradientBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode banner
                    modeBanner

                    // Alarm list or empty state
                    if alarmStore.alarms.isEmpty {
                        emptyState
                    } else {
                        alarmList
                    }
                }
            }
            .navigationTitle("GeoAlarm")
            .toolbar { toolbarContent }

            // MARK: Sheets
            .sheet(isPresented: $showingAddAlarm) {
                AddEditAlarmView(mode: .add)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingSimulation) {
                SimulationControlView()
            }

            // MARK: Triggered Alarm Alert
            .alert(
                "🔔 Alarm Triggered!",
                isPresented: $showingTriggeredAlert,
                presenting: alarmStore.triggeredAlarm
            ) { alarm in
                Button("Dismiss") {
                    alarmStore.triggeredAlarm = nil
                }
                Button("Reset Alarm") {
                    alarmStore.resetAlarm(id: alarm.id)
                    alarmStore.triggeredAlarm = nil
                }
            } message: { alarm in
                Text("\(alarm.title)\n\(alarm.triggerType.description) at \(alarm.locationName).")
            }
            // Watch for triggers from the store.
            .onChange(of: alarmStore.triggeredAlarm?.id) { _, newValue in
                if newValue != nil {
                    showingTriggeredAlert = true
                }
            }
        }
    }

    // MARK: - Mode Banner
    // Uses a pill-shaped ModePill badge (from DesignSystem) plus an optional
    // "Controls" button for simulation mode. The banner sits in a gently
    // tinted strip whose color matches the mode.

    private var modeBanner: some View {
        HStack(spacing: 10) {
            ModePill(isSimulation: locationManager.isSimulationMode)

            if locationManager.isSimulationMode {
                Text("Using simulated location")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            if locationManager.isSimulationMode {
                Button {
                    showingSimulation = true
                } label: {
                    Label("Controls", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.appAccent.opacity(0.15))
                        .foregroundStyle(Color.appAccent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            (locationManager.isSimulationMode ? Color.appAccent : Color.appSuccess)
                .opacity(0.06)
        )
    }

    // MARK: - Alarm List
    // Uses a ScrollView + LazyVStack with card-styled rows instead of a
    // plain List. This gives us full control over card styling (rounded
    // corners, shadows, border) while retaining swipe and context menu support.

    private var alarmList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(alarmStore.alarms) { alarm in
                    AlarmRowView(
                        alarm: alarm,
                        isSimulation: locationManager.isSimulationMode
                    )
                    .appCard()
                    .contextMenu {
                        if case .triggered = alarm.status {
                            Button {
                                alarmStore.resetAlarm(id: alarm.id)
                            } label: {
                                Label("Reset to Waiting", systemImage: "arrow.counterclockwise")
                            }
                        }
                        Button {
                            alarmStore.toggleAlarm(id: alarm.id)
                        } label: {
                            Label(
                                alarm.isActive ? "Disable Alarm" : "Enable Alarm",
                                systemImage: alarm.isActive ? "bell.slash" : "bell.fill"
                            )
                        }
                        Button(role: .destructive) {
                            alarmStore.deleteAlarm(id: alarm.id)
                        } label: {
                            Label("Delete Alarm", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 64))
                .foregroundStyle(Color.appPrimary.opacity(0.4))
            Text("No GeoAlarms Yet")
                .font(.appHeadline)
                .foregroundStyle(Color.appTextPrimary)
            Text("Tap **+** to create your first\nlocation-based reminder.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
        }
        .padding()
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingAddAlarm = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
            }
        }
    }
}
