# Implementation Checklist

## Phase 0: Project setup
- [ ] Create Xcode project with watchOS app target.
- [ ] Add optional iOS companion only if needed for settings/history.
- [ ] Add WidgetKit extension for watch complication/accessory widget.
- [ ] Configure bundle identifiers and signing.
- [ ] Add required background mode for extended runtime session if used.

## Phase 1: Session core
- [ ] Create `SessionManager`.
- [ ] Create runtime states: idle, starting, active, stopping, saving, ended, interrupted.
- [ ] Implement `start()`.
- [ ] Implement `stop(reason:)`.
- [ ] Add max duration timer.
- [ ] Handle duplicate starts/stops.

## Phase 2: Haptics
- [ ] Create `HapticEngine` wrapper.
- [ ] Play beginning pulse.
- [ ] Start repeating timer.
- [ ] Stop repeating timer.
- [ ] Test haptic types on real Apple Watch.
- [ ] Tune default interval.

## Phase 3: Dark UI
- [ ] Build `CatalystSessionView` with black background.
- [ ] Add full-screen tap gesture to stop.
- [ ] Hide all text and controls in active session.
- [ ] Verify no completion message after stop.
- [ ] Add debug-only diagnostics flag if needed.

## Phase 4: Extended runtime
- [ ] Add `WKExtendedRuntimeSession` support.
- [ ] Move session ownership to app-scope manager.
- [ ] Implement delegate callbacks.
- [ ] Save interrupted records when runtime expires or invalidates.
- [ ] Test wrist-down/screen-off behavior on device.

## Phase 5: Data model and persistence
- [ ] Implement `SessionRecord`.
- [ ] Implement `MoonPhase` model.
- [ ] Implement `CoarseLocation` model.
- [ ] Implement JSON or SwiftData store.
- [ ] Append records.
- [ ] Delete all records.
- [ ] Unit test encode/decode.

## Phase 6: Moon phase
- [ ] Implement offline moon phase calculation.
- [ ] Map calculation to eight phase names.
- [ ] Unit test phase-name boundaries.
- [ ] Add attribution if using third-party code/package.

## Phase 7: Optional location
- [ ] Add location setting default off.
- [ ] Add location permission usage string.
- [ ] Request permission outside active session.
- [ ] Request one location update only.
- [ ] Round coordinates or store locality only.
- [ ] Handle denied/unavailable state.

## Phase 8: Complication
- [ ] Add WidgetKit complication/accessory widget.
- [ ] Use neutral icon/glyph.
- [ ] Configure tap to launch Catalyst Mode.
- [ ] Test on multiple watch faces.

## Phase 9: Settings/history
- [ ] Build settings outside active session.
- [ ] Add max duration setting.
- [ ] Add haptic pattern setting if desired.
- [ ] Add delete-all.
- [ ] Add simple history only if it does not complicate MVP.

## Phase 10: Privacy review
- [ ] Confirm no microphone permission.
- [ ] Confirm no HealthKit entitlement.
- [ ] Confirm no analytics SDK.
- [ ] Add privacy manifest.
- [ ] Fill App Store privacy labels accurately.
- [ ] Review location disclosures.

## Phase 11: Manual test on hardware
- [ ] Launch from complication.
- [ ] Verify haptic start latency.
- [ ] Verify haptics after wrist down.
- [ ] Verify tap to stop.
- [ ] Verify no visible prompt after stop.
- [ ] Verify record saved.
- [ ] Verify location denied path.
- [ ] Verify max duration end.
- [ ] Verify battery impact is acceptable.
