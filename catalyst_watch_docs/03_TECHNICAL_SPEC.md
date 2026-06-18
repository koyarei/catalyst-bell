# Technical Spec: Catalyst Bell

## 1. Platform targets
Recommended MVP:
- watchOS app: SwiftUI + WatchKit
- iOS companion: optional but recommended for later history/settings
- WidgetKit extension for watch complications/accessory widgets

Avoid third-party dependencies in MVP unless needed for moon phase calculation. If a moon phase dependency is used, prefer a small MIT-licensed Swift Package or copy a clearly licensed offline algorithm into the project with attribution.

## 2. Apple APIs and framework choices
### Haptics
Use `WKInterfaceDevice.current().play(_:)` with standard `WKHapticType` values.

Important constraints:
- WatchKit haptics are predefined types.
- Do not assume fully custom Core Haptics patterns on watchOS.
- Avoid calling haptics too rapidly.
- Build a timer-driven loop around standard haptic events.

Possible haptic types to test on hardware:
- `.click`
- `.directionUp`
- `.start`
- `.stop`
- `.success` only if it feels too celebratory, avoid for active loop

Recommended MVP default: a gentle `.click` or other subtle type, repeated on a slow interval.

### Extended runtime
Use `WKExtendedRuntimeSession` so the session can continue if the user drops their wrist or stops interacting.

Recommended session category: evaluate `mindfulness` or `self-care` background mode based on Apple’s current definitions and App Store review fit.

Requirements:
- Session manager should live at app/service scope, not inside a transient view object.
- Handle session invalidation.
- Handle expiration.
- Save ended/interrupted sessions cleanly.
- Limit work during the session.

### Complication / accessory widget
Use WidgetKit watch complications/accessory widgets. The complication should launch the watch app into Catalyst Mode.

Implementation note:
- Define an app URL/deep link or app intent if appropriate.
- Ensure tapping the complication starts the haptic session rather than landing on settings.

### Location
Use Core Location only if user enables location logging.

Recommended strategy:
- Ask location permission outside the active catalyst flow.
- Use When In Use authorization.
- Request a single location update on session end or session start.
- Store coarse location only.
- If location is unavailable, save the record without location.

Coarse location options:
- Rounded coordinate, e.g. 2 decimal places, or
- City/locality string if reverse geocoding is implemented, or
- Location disabled/null

For privacy, prefer rounded coordinate or city-level text, not exact address.

### Moon phase
Compute offline from date/time. Location is not necessary for simple moon phase.

Options:
- Implement an offline synodic-month approximation.
- Use a small Swift package such as TinyMoon if licensing and platform compatibility are acceptable.

MVP moon fields:
- phase name: New Moon, Waxing Crescent, First Quarter, Waxing Gibbous, Full Moon, Waning Gibbous, Last Quarter, Waning Crescent
- phase fraction: 0.0 to 1.0 if available

### Storage
MVP options:
- JSON file in app container
- SwiftData if the chosen deployment target supports it cleanly on watchOS and iOS
- UserDefaults only if records are tiny and limited

Recommended: JSON file or SwiftData. Avoid overengineering.

### Watch-to-iPhone sync
If iOS companion is included:
- Use WatchConnectivity to transfer session records.
- Queue unsent records and retry.
- The watch remains source of truth until transfer succeeds.

If iOS companion is not included in MVP:
- Store locally on watch.
- Add export/sync later.

## 3. Runtime state machine
States:
1. `idle`
2. `starting`
3. `active`
4. `stopping`
5. `saving`
6. `ended`
7. `interrupted`

Transitions:
- complication tap -> `starting`
- haptic loop begins -> `active`
- screen tap -> `stopping`
- haptics stop -> `saving`
- save success/failure handled -> `ended`
- runtime session expires/system interruption -> `interrupted` then save partial record

## 4. Active session algorithm
Pseudocode:

```swift
func startCatalystSession(source: LaunchSource) {
    guard state == .idle else { return }
    state = .starting
    currentSession = SessionDraft(start: Date(), source: source)
    startExtendedRuntimeSessionIfAvailable()
    showDarkScreen()
    startHapticLoop()
    state = .active
}

func stopCatalystSession(reason: EndReason) {
    guard state == .active || state == .starting else { return }
    state = .stopping
    stopHapticLoop()
    endExtendedRuntimeSessionIfNeeded()
    currentSession.end = Date()
    currentSession.endReason = reason
    enrichWithContextAndSave(currentSession)
    state = .ended
    returnToDarkIdleOrLetSystemReturn()
}
```

## 5. Haptic loop algorithm
Pseudocode:

```swift
func startHapticLoop() {
    playStartPulse()
    timer = Timer.scheduledTimer(withTimeInterval: selectedInterval, repeats: true) { [weak self] _ in
        guard self?.state == .active else { return }
        WKInterfaceDevice.current().play(self?.selectedHapticType ?? .click)
    }
}
```

Implementation notes:
- Test with real hardware; simulator haptics are not enough.
- Avoid intervals shorter than 2 seconds unless testing proves it is comfortable and Apple-safe.
- Suggested default interval: 4 seconds.
- Suggested maximum session duration: 10 minutes.

## 6. App lifecycle handling
Handle:
- app entering background
- wrist down / screen off
- extended runtime session expiration
- user reopens app during active session
- duplicate launch while already active
- crash recovery if session draft exists without end time

For crash recovery, on next launch mark any open draft as `interrupted` with an estimated end time if reasonable, or discard if incomplete.

## 7. Privacy and entitlements
MVP should not include:
- HealthKit entitlement
- microphone usage description
- speech recognition
- analytics SDKs
- advertising SDKs

May include:
- Location usage description if location logging is enabled
- WeatherKit only in a future version if weather is added
- App Group if needed for widget/shared storage
- WatchConnectivity if iOS companion is included

Include a privacy manifest and App Store privacy labels consistent with actual behavior.

## 8. Testing requirements
Test on physical Apple Watch:
- haptic feel
- haptic loop duration
- wrist-down behavior
- screen-off behavior
- complication launch
- one-tap stop reliability
- location denied
- location allowed
- airplane mode / no network
- low battery mode, if relevant

## 9. Known technical risks
- Extended runtime sessions may have time limits and review constraints.
- Haptic patterns are limited to predefined types.
- The system may show the app in Always On/dimmed mode, so active UI must be visually empty.
- Returning programmatically to the watch face may not be desirable or reliable; dark idle is acceptable.
- Complication launch behavior must be tested across watch faces.

## 10. Development environment assumptions
- Xcode latest stable version available to the developer.
- SwiftUI-first implementation.
- Real Apple Watch available for testing haptics.
- Apple Developer account available if testing complications and permissions on device.
