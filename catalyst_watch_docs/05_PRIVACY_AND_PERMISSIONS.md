# Privacy and Permissions: Catalyst Bell

## 1. Privacy posture
Catalyst Bell should be private by design. The user launches it during socially sensitive moments, so the app must avoid collecting anything that could harm trust.

The MVP should collect no data beyond the minimal local session context the user explicitly expects.

## 2. No biometric data
Do not use HealthKit. Do not request permissions for:
- heart rate
- respiratory rate
- sleep
- workouts
- electrodermal activity
- mindfulness minutes
- any physiological or health measurement

## 3. No recording
Do not request microphone permission.
Do not record audio.
Do not transcribe conversations.
Do not summarize arguments.
Do not store names of people involved.

## 4. Location
Location is optional. Although the user described date, time, location, and moon phase as public-context data, device location is still personally sensitive.

Implementation rules:
- Default location logging to off unless the user turns it on during setup.
- Ask location permission outside the active catalyst session.
- Use coarse location only.
- Do not store exact address.
- Do not store continuous location history.
- Request one location fix at session start or end, then stop.
- If location permission is denied, app still functions normally.

Suggested location permission copy:

> Catalyst Bell can save an approximate location with each session so you can later notice context patterns. It never tracks you continuously.

Info.plist usage string draft:

> Catalyst Bell uses your approximate location only when saving a grounding session, if you enable location logging.

## 5. Moon phase
Compute moon phase offline from the session date. This avoids network calls and keeps the app simple.

## 6. Network
MVP should work offline.

Do not add analytics or telemetry. If crash reporting is added later, it must be explicitly documented and should avoid session metadata.

## 7. App Store privacy labels
Expected MVP privacy labels depend on exact implementation:

If no location is used:
- Data collected: likely none, if session records stay only on device and are not transmitted.

If location is stored locally only:
- Review Apple’s current App Store privacy label rules carefully. Even local-only collection can still require disclosure depending on Apple’s definitions and app behavior.

If iPhone companion sync uses WatchConnectivity only between the user’s own devices and no server:
- Still disclose accurately according to Apple’s rules.

## 8. Privacy manifest
Include a privacy manifest file consistent with the app’s actual collected data and required reason APIs. Apple requires privacy manifest information for apps and SDKs on watchOS and other platforms.

## 9. User controls
Required:
- Location logging toggle.
- Delete all records.

Recommended:
- Export records as JSON/CSV in future iPhone companion.
- Auto-delete setting in future version.

## 10. Ethical product boundary
The app should not help the user gather evidence against another person. It should help the user regulate their own response. This is why recording, transcription, and biometrics are excluded.
