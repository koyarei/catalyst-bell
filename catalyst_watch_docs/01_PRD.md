# PRD: Catalyst Bell

## 1. Product name
Working name: **Catalyst Bell**

Other possible names:
- Return
- Stillpoint
- Anchor
- One Breath
- Ripple

## 2. One-sentence description
Catalyst Bell is a discreet Apple Watch grounding app that starts a repeating haptic anchor from the watch face and runs until the user stops it with one tap, then silently logs only minimal public-context data for later reflection.

## 3. Philosophy and product intent
The app exists for moments when emotional catalyst is already active: heated argument, witnessing conflict, sudden shame, fear, defensiveness, overwhelm, envy, or a strong unpleasant feeling. Its purpose is not to analyze the event, score stress, prove what happened, or capture another person. Its purpose is to help the user return to the body before the first reactive impulse becomes speech or behavior.

The guiding principle:

> During catalyst, the watch should not ask for attention. It should return attention to the body.

The app should feel more like touching a mala bead, taking one breath, or silently placing a hand on the heart than like opening a productivity app.

## 4. Target user
Primary user:
- An Apple Watch user who wants a low-friction physical reminder during emotionally charged moments.
- The user may be in a social or relational situation and cannot safely or gracefully look at a visible prompt.
- The user values privacy, minimalism, and non-surveillance.

Secondary user:
- Someone who wants a haptic meditation anchor during anxiety, conflict, or public stress.

## 5. Core use case
The user is in a heated emotional moment. They tap a watch-face complication. The app opens to a dark screen and starts a repeating haptic pattern. The user does not need to read anything. When ready, the user taps the screen once to stop. The watch shows no completion message. A minimal log is saved silently.

## 6. MVP scope
### Included
- Apple Watch app built with SwiftUI.
- Watch-face complication or accessory widget for fast launch.
- Dark active-session screen with no visible text.
- Haptic pulse loop while session is active.
- One-tap stop anywhere on the active screen.
- Silent local session log:
  - start timestamp
  - end timestamp
  - duration seconds
  - coarse location if permission granted
  - moon phase
  - app version/schema version
- Basic settings screen outside the active catalyst flow:
  - enable/disable location logging
  - choose haptic pattern
  - choose maximum session duration
  - view simple local session history, preferably on iPhone companion if implemented
- No visible post-session message on the watch.

### Excluded
- Audio recording.
- Transcription.
- Microphone permission.
- HealthKit.
- Biometric or physiological data.
- Heart rate, respiratory rate, perspiration, electrodermal activity.
- Weather in MVP.
- AI interpretation.
- Relationship analysis.
- Stress scoring.
- Push notifications.
- Cloud sync.
- Accounts.
- Analytics.
- Ads.

## 7. User stories
### Launch and ground
As a user in an emotionally charged moment, I want to start haptic grounding with one tap from the watch face so I can return to my body without looking at instructions.

### Stop discreetly
As a user, I want to stop the session with one tap anywhere on the dark screen so I do not need to navigate UI during a conversation.

### Stay visually private
As a user, I want the active screen to be dark with no text so another person does not ask what is on my watch.

### Silent logging
As a user, I want the app to silently save the date, time, duration, coarse location, and moon phase so I can later notice patterns without tracking private conversation content or body data.

### No post-session prompt
As a user, I do not want any watch message after stopping because I may still be in the middle of a sensitive interaction.

### Later review
As a user, I may want to review previous sessions later, away from the argument, to notice repeating contexts.

## 8. Functional requirements
### FR-1: Watch-face launch
The app must provide a complication/accessory widget that can be placed on the Apple Watch face and used to open the app quickly.

### FR-2: Immediate haptic start
When launched into catalyst mode, the app should start the haptic loop as soon as practical. Avoid intermediate setup screens.

### FR-3: Dark active screen
The active screen must be black or nearly black, with no text, no visible prompt, no decorative graphic, and no session timer by default.

### FR-4: One-tap stop
A tap anywhere on the active screen must stop haptics, end the session, save the record, and exit or return to an idle dark state without a visible completion message.

### FR-5: Silent save
When a session ends, save the session record locally. Saving must not show a confirmation on the watch.

### FR-6: Haptic loop
The app must play repeating haptic pulses until stopped, interrupted by the system, or ended by a configured maximum duration.

### FR-7: Maximum duration safeguard
The app must have a default maximum duration, such as 10 minutes, to protect battery and avoid forgotten sessions. This should be configurable in settings outside the active session.

### FR-8: Moon phase
The app must compute moon phase from the session start date. Prefer offline calculation, not a network API.

### FR-9: Location
If enabled and permission is granted, the app may save coarse location. If permission is not granted, the app still works fully and saves no location.

### FR-10: No prohibited data
The app must not request HealthKit, microphone, speech recognition, contacts, photos, or calendar permissions in the MVP.

## 9. Nonfunctional requirements
- Extremely low cognitive load.
- Launch-to-haptic latency should feel immediate.
- Active screen must be socially discreet.
- Must function without network access.
- Must degrade gracefully if location permission is denied.
- Must be battery-conscious.
- Must avoid private or relationship-surveillance framing.
- Must be App Store review friendly by being accurate about privacy behavior.

## 10. Success criteria
The MVP succeeds if:
- A user can place a complication on the watch face.
- Tapping the complication opens the app and starts haptics.
- The screen stays dark and unreadable to others.
- Tapping once stops haptics.
- No message appears on the watch after stopping.
- A local record is saved with date/time/duration/moon phase and optional coarse location.
- The app uses no microphone, no HealthKit, and no analytics.

## 11. Product risks
### Risk: watchOS haptic/background limitations
Mitigation: use WatchKit haptics and evaluate WKExtendedRuntimeSession with a mindfulness or self-care background mode. Test on real hardware.

### Risk: visible UI causes social friction
Mitigation: dark screen only, no visible words, one-tap stop.

### Risk: location feels too sensitive
Mitigation: make location optional, ask permission outside catalyst flow, store coarse location only, and allow deletion of history.

### Risk: app becomes self-surveillance
Mitigation: no scores, no body data, no charts framed as performance. Later review should be gentle and optional.

## 12. Future versions
Potential later features:
- iPhone companion for session history and reflection.
- Optional manual one-word tag after the fact, only on iPhone.
- Optional weather context.
- Optional export to CSV/JSON.
- Optional custom haptic patterns.
- Optional Apple Shortcuts support.
- Optional iCloud sync, disabled by default.

Do not add these to the MVP unless explicitly requested.
