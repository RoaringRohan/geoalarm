// MARK: - File: GeoAlarm/Views/OnboardingView.swift
// ═══════════════════════════════════════════════════════════════════════════════
//  GeoAlarm — Location-Based Alarm App (Swift Student Challenge)
//
//  OnboardingView presents a friendly 2-page introduction:
//    Page 1 — Explains the concept of location-based alarms.
//    Page 2 — Permission request with graceful fallback to simulation.
//
//  Design:
//    • Rainforest-themed gradient background (canopy-to-mist feel).
//    • Anthropic-style typography: large bold title, readable body,
//      clear hierarchy between heading and supporting text.
//    • Scenario cards use the appCardBackground token with appBorder stroke.
//    • Primary CTA buttons use AppPrimaryButtonStyle (deep canopy green).
//    • The "simulation mode" info blurb uses appAccent (warm amber) to
//      signal that this is an alternate path, not the primary flow.
// ═══════════════════════════════════════════════════════════════════════════════

import SwiftUI

struct OnboardingView: View {

    // MARK: Bindings & Environment

    /// Set to `true` to dismiss onboarding and go to HomeView.
    @Binding var hasCompletedOnboarding: Bool

    @EnvironmentObject var locationManager: LocationManager

    /// Tracks the currently visible onboarding page.
    @State private var currentPage = 0

    /// Whether we're waiting for the user to respond to the system permission dialog.
    @State private var isRequestingPermission = false

    // MARK: Body

    var body: some View {
        ZStack {
            // Background gradient — a subtle top-to-bottom canopy effect.
            // Uses the design-system gradient tokens so it adapts to dark mode.
            LinearGradient(
                colors: [Color.appGradientTop, Color.appGradientBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                permissionPage.tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // Big icon — uses appPrimary instead of system blue.
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 80))
                .foregroundStyle(Color.appPrimary)

            Text("Welcome to GeoAlarm")
                .font(.appTitle)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)

            Text("Set alarms that trigger when you **arrive at** or **leave** a location — not at a specific time.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            // Example scenario cards
            VStack(spacing: 12) {
                scenarioCard(
                    icon: "message.fill",
                    text: "\"Text Mom when I arrive at school.\""
                )
                scenarioCard(
                    icon: "cart.fill",
                    text: "\"Buy milk when I'm near the store.\""
                )
                scenarioCard(
                    icon: "clock.badge.checkmark.fill",
                    text: "\"Clock out when I leave the office.\""
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Label("Continue", systemImage: "arrow.right")
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 2: Permission

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.appPrimary)

            Text("Location Access")
                .font(.appTitle)
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)

            Text("GeoAlarm uses your location to know when you enter or leave an area.\n\nYour location data stays on your device — it is **never** sent anywhere.")
                .font(.appBody)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            // Permission action area
            VStack(spacing: 16) {
                Button {
                    isRequestingPermission = true
                    locationManager.requestAuthorization()
                } label: {
                    Label("Enable Location", systemImage: "location.fill")
                }
                .buttonStyle(AppPrimaryButtonStyle())
                .disabled(isRequestingPermission)

                Button {
                    // Skip permission — go straight to simulation mode.
                    locationManager.setSimulationMode(true)
                    hasCompletedOnboarding = true
                } label: {
                    Text("Skip — Use Simulation Mode")
                }
                .buttonStyle(AppSecondaryButtonStyle())
            }
            .padding(.horizontal, 32)

            // Info about simulation — uses appAccent to signal an alternate path.
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color.appAccent)
                Text("If you skip or deny, GeoAlarm runs in **Simulation Mode** — fully functional with a virtual location you control.")
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        // React to authorization changes while this page is showing.
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            guard isRequestingPermission else { return }
            switch newStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                // Permission granted — proceed to Home in real mode.
                locationManager.setSimulationMode(false)
                hasCompletedOnboarding = true
            case .denied, .restricted:
                // Permission denied — proceed to Home in simulation mode.
                locationManager.setSimulationMode(true)
                hasCompletedOnboarding = true
            default:
                break
            }
        }
    }

    // MARK: - Scenario Card Helper

    /// Each card uses the design-system card tokens: appCardBackground + appBorder.
    /// Icon color is appSecondary (misty teal) for visual variety against the
    /// appPrimary title above.
    private func scenarioCard(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.appSecondary)
                .frame(width: 36)
            Text(text)
                .font(.appSubhead)
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
        }
        .padding()
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.appBorder, lineWidth: 0.5)
        )
    }
}
