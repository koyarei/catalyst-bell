# Acceptance Criteria: Catalyst Bell MVP

## 1. Launch
- [ ] App installs on Apple Watch.
- [ ] A watch-face complication/accessory widget is available.
- [ ] Tapping the complication launches Catalyst Mode, not settings.
- [ ] Haptics start without requiring another tap.

## 2. Active screen
- [ ] Active screen is black or nearly black.
- [ ] No text appears during active session.
- [ ] No timer appears during active session.
- [ ] No animation appears during active session.
- [ ] No logo or icon appears during active session.

## 3. Haptics
- [ ] Haptic loop begins on session start.
- [ ] Haptic loop repeats gently.
- [ ] Haptic loop continues until stopped, max duration, or system interruption.
- [ ] Haptic loop stops immediately when user taps.
- [ ] Haptic loop is not too frequent or alarming on real Apple Watch hardware.

## 4. Stop behavior
- [ ] Tapping anywhere on active screen stops the session.
- [ ] After stopping, no “saved,” “done,” “complete,” or other visible message appears.
- [ ] The app either remains dark or returns naturally; it does not show a prompt.

## 5. Data saving
- [ ] A session record is saved after stop.
- [ ] Record contains start time.
- [ ] Record contains end time.
- [ ] Record contains duration.
- [ ] Record contains end reason.
- [ ] Record contains moon phase.
- [ ] Record omits location if location is disabled or denied.
- [ ] Record contains only coarse location if enabled and granted.

## 6. Privacy exclusions
- [ ] App does not request microphone permission.
- [ ] App does not include audio recording code.
- [ ] App does not include speech recognition.
- [ ] App does not include HealthKit entitlement.
- [ ] App does not read heart rate or any physiological data.
- [ ] App does not include analytics SDKs.
- [ ] App does not require a user account.
- [ ] App works offline.

## 7. Location behavior
- [ ] Location permission is never requested during active Catalyst Mode.
- [ ] If location is disabled, app works fully.
- [ ] If location permission is denied, app works fully.
- [ ] If location is enabled, only one coarse location value is stored per session.

## 8. Moon phase
- [ ] Moon phase is computed offline.
- [ ] Moon phase calculation does not require network.
- [ ] Moon phase enum maps into one of the eight expected names.

## 9. Settings
- [ ] Settings are not shown during active Catalyst Mode.
- [ ] Settings allow delete-all records.
- [ ] Settings allow location logging toggle if location is implemented.
- [ ] Settings allow max duration adjustment or at least define a fixed default.

## 10. Reliability
- [ ] If extended runtime expires, haptics stop and an interrupted record is saved if possible.
- [ ] If app is reopened during an active session, state remains coherent.
- [ ] Duplicate taps do not corrupt records.
- [ ] Max duration ends the session safely.
