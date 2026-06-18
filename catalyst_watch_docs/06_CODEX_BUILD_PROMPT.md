# Codex Build Prompt

Use this prompt directly with Codex or another coding agent.

---

Build a new Apple Watch app from scratch called **Catalyst Bell**.

## Product goal
Create a minimal watchOS grounding app. The user launches it from a watch-face complication during an emotionally intense moment. It shows a dark screen, starts repeating haptic feedback, and continues until the user taps once anywhere on the screen. When stopped, it silently saves a minimal local session record with date/time/duration/moon phase and optional coarse location. It must not show any visible completion message.

## Hard requirements
- Native Swift / SwiftUI.
- watchOS app target.
- WidgetKit complication/accessory widget for watch-face launch.
- Active session screen is black with no text, no timer, no visible prompt, no animation, no completion message.
- Tapping anywhere on active screen stops the session.
- Haptics repeat until stopped, max duration reached, or system interruption.
- Use WatchKit haptics: `WKInterfaceDevice.current().play(...)`.
- Evaluate/use `WKExtendedRuntimeSession` so haptics can continue after wrist down/screen off when supported.
- Save a local `SessionRecord` after stop.
- Compute moon phase offline from the session start date.
- Location logging is optional and off by default. If implemented, request permission only from settings/onboarding, never during the active catalyst session. Store coarse location only.
- No HealthKit.
- No microphone.
- No audio recording.
- No speech recognition.
- No biometrics.
- No network calls in MVP.
- No analytics.
- No accounts.
- No cloud sync.

## Suggested architecture
Create these components:

- `CatalystBellApp`: SwiftUI app entry.
- `CatalystSessionView`: full-screen black active view; tap anywhere to stop.
- `SessionManager`: app-scope observable object that owns state, timers, haptics, and extended runtime session.
- `HapticEngine`: wrapper around WatchKit haptic calls and timer intervals.
- `SessionStore`: local JSON or SwiftData persistence.
- `MoonPhaseCalculator`: offline calculation with phase name enum.
- `LocationProvider`: optional coarse location service, disabled by default.
- `SettingsView`: location toggle, haptic pattern, max duration, delete history.
- `ComplicationWidget`: WidgetKit accessory widget that deep-links into active Catalyst Mode.

## Runtime behavior
1. User taps complication.
2. App opens directly into `CatalystSessionView`.
3. `SessionManager.start()` records start date and starts extended runtime session if possible.
4. Haptic loop begins immediately.
5. Screen is black and remains black.
6. User taps anywhere.
7. `SessionManager.stop(reason: .userStopped)` stops haptics, ends runtime session, saves record, and shows no completion message.
8. App remains dark or lets the system return naturally. Do not show “Saved,” “Done,” or any prompt.

## Haptic loop
Use a slow, gentle pattern. Start with:
- one beginning pulse
- then one haptic pulse every 4 seconds

Allow haptic type and interval to be constants or settings.

Add max duration safeguard, default 10 minutes.

## Data model
Implement:

```swift
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    let schemaVersion: Int
    let startDate: Date
    let endDate: Date
    let durationSeconds: TimeInterval
    let endReason: EndReason
    let launchSource: LaunchSource
    let moonPhase: MoonPhase
    let location: CoarseLocation?
    let createdAt: Date
    let appVersion: String
}
```

Enums:
- `EndReason`: userStopped, maxDurationReached, runtimeExpired, systemInterrupted, appTerminated, unknown
- `LaunchSource`: complication, appIcon, shortcut, debug, unknown
- `MoonPhaseName`: newMoon, waxingCrescent, firstQuarter, waxingGibbous, fullMoon, waningGibbous, lastQuarter, waningCrescent

## Persistence
Use simple local JSON persistence unless SwiftData is simpler for the chosen project template. Include delete-all.

## Permissions
Do not include permission strings for microphone or HealthKit.
If location is implemented, include a clear location usage string explaining approximate location is saved only with sessions if enabled.

## Testing
Add unit tests for:
- moon phase phase-name mapping
- duration calculation
- session record encoding/decoding
- store append/delete
- max duration stop logic if feasible

Manual test checklist:
- complication launches app
- haptics start quickly
- dark screen has no visible text
- one tap stops
- no completion message appears
- record saved
- location denied path works
- airplane mode works
- real Apple Watch haptics feel gentle

## Do not build
- Do not add AI.
- Do not add chat.
- Do not add recording.
- Do not add health data.
- Do not add stress scoring.
- Do not add cloud/backend.
- Do not add analytics.
- Do not add visible active-session text.

Deliver a clean, compiling project with comments only where helpful.
