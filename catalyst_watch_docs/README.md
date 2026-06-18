# Catalyst Bell Watch App Handoff Package

This package contains product and engineering docs for building a minimal Apple Watch grounding app from scratch.

## Product summary
Catalyst Bell is a discreet Apple Watch app that can be launched from the watch face with one tap during emotionally intense catalyst. It displays a dark screen, provides repeating haptic feedback until stopped with one tap, then silently saves a small context record: start time, end time, duration, coarse location if permitted, and moon phase. It does not record audio, does not read health data, does not track biometrics, does not show visible prompts, and does not display a completion message on the watch.

## Recommended build order
1. Read `01_PRD.md` for the product definition.
2. Read `02_UX_SPEC.md` for watch interaction behavior.
3. Read `03_TECHNICAL_SPEC.md` for Apple platform choices.
4. Read `04_DATA_MODEL.md` for the local record schema.
5. Read `05_PRIVACY_AND_PERMISSIONS.md` before implementing location.
6. Use `06_CODEX_BUILD_PROMPT.md` as the direct prompt for Codex.
7. Use `07_ACCEPTANCE_CRITERIA.md` to verify the build.
8. Use `08_IMPLEMENTATION_CHECKLIST.md` to track progress.

## Key non-goals
- No conversation recording.
- No microphone access.
- No HealthKit.
- No heart rate, respiratory rate, perspiration, sleep, stress score, or physiological inference.
- No visible phrases during a catalyst session.
- No visible session-saved message after stopping.
- No social, cloud, analytics, account, or subscription layer in the MVP.

## Technical references
- Watch haptics: https://developer.apple.com/documentation/watchkit/wkinterfacedevice/play%28_%3A%29
- Extended runtime sessions: https://developer.apple.com/documentation/watchkit/wkextendedruntimesession
- Using extended runtime sessions: https://developer.apple.com/documentation/watchkit/using-extended-runtime-sessions
- WidgetKit watch complications: https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications
- Core Location: https://developer.apple.com/documentation/corelocation
- Requesting location authorization: https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
- Privacy manifest files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
