# Catalyst Bell: Single-File PRD for Quick Handoff

## Summary
Catalyst Bell is a minimal Apple Watch app for emotionally intense moments. The user taps a watch-face complication. The app opens to a dark screen and starts repeating haptic feedback. The user taps once anywhere to stop. The app shows no visible text or completion message. It silently saves only a minimal context record: start time, end time, duration, moon phase, and optional coarse location.

## Core rule
During catalyst, the watch should not ask for attention. It should return attention to the body.

## MVP requirements
- watchOS SwiftUI app.
- WidgetKit complication/accessory widget for launch.
- Dark active screen with no text, timer, animation, or prompt.
- Immediate haptic loop on launch.
- One tap anywhere to stop.
- Silent local session save.
- Offline moon phase calculation.
- Optional coarse location, off by default.
- No visible post-session message.

## Must not include
- audio recording
- microphone
- transcription
- HealthKit
- biometrics
- heart rate
- respiratory rate
- perspiration
- weather in MVP
- AI interpretation
- analytics
- account
- cloud backend
- active-session text

## Data model
Fields:
- id UUID
- schemaVersion
- startDate
- endDate
- durationSeconds
- endReason
- launchSource
- moonPhaseName
- optional moonPhaseFraction
- optional coarseLocation
- createdAt
- appVersion

## Suggested implementation
Use:
- `WKInterfaceDevice.current().play(_:)` for haptics.
- `WKExtendedRuntimeSession` for continued haptics after wrist down/screen off where supported.
- WidgetKit complication/accessory widget for launch.
- Core Location only if optional location is enabled.
- Local JSON or SwiftData for persistence.

## Acceptance test
The app passes MVP when tapping the watch-face complication starts a haptic loop on a black screen, a single tap stops it, nothing visible appears after stopping, and a minimal session record is saved without using microphone, HealthKit, recording, analytics, or network.
