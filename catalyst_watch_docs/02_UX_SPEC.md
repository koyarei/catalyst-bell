# UX Spec: Catalyst Bell

## 1. Design principle
The active session is not a screen to read. It is a tactile anchor.

The screen should do as close to nothing as possible. The haptic pattern is the product.

## 2. Watch-face complication
### Purpose
Provide one-tap launch from the watch face.

### Visual style
- Minimal icon only.
- No words such as “calm,” “breathe,” “catalyst,” or “argument.”
- Prefer neutral glyph: small circle, ripple, dot, crescent, or simple bell.
- Avoid spiritual/religious symbols.
- Avoid emotionally loaded colors in complication artwork.

### Tap behavior
Tap opens Catalyst Mode immediately. No menu should appear first.

## 3. Active Catalyst Mode
### Visual behavior
- Full-screen black background.
- No visible text.
- No timer.
- No progress ring.
- No animation.
- No session status.
- No completion view.

If a completely black screen makes accidental state unclear during testing, developers may use a hidden debug build flag that shows tiny diagnostics. Diagnostics must not appear in production.

### Haptic behavior
Start haptic pattern immediately on session start.

Recommended default pattern:
- one firmer start pulse to mark beginning
- then repeating gentle pulses every few seconds
- optional cycle: two soft pulses separated by a long pause

Avoid haptics that feel alarming, punitive, or like an emergency notification.

The pattern should feel like:
- return
- breathe
- soften
- stay

It should not feel like:
- warning
- countdown
- alarm
- failure

## 4. Stop interaction
A single tap anywhere on the screen stops the session.

After stop:
- haptics stop
- session record is saved silently
- no visible message appears
- app returns to watch face if technically appropriate, or remains on a dark idle screen

If returning to the watch face is unreliable or not allowed in a clean way, remain on a dark idle screen and let the system naturally return. Do not show text.

## 5. Settings screen
Settings must not be part of active Catalyst Mode.

Settings can be accessible from the watch app when not in an active session, or preferably from an iPhone companion.

Possible settings:
- haptic pattern: Gentle, Slow, Steady
- max duration: 2, 5, 10, 15 minutes
- location logging: Off / Coarse only
- delete all history
- export local data, if iPhone companion exists

Settings screens may use normal UI and text because they are not used during conflict.

## 6. Session history
Prefer history on iPhone, not watch.

History should show simple rows:
- date
- start time
- duration
- moon phase
- coarse location if enabled

Do not show charts in MVP. Do not score or judge sessions.

## 7. Accessibility
- Haptic-only use is intentional, but the settings area should support VoiceOver.
- The active screen should not rely on color or text.
- Provide a visible stop affordance only in settings/debug or if accessibility testing shows a need. Default product intent remains dark.

## 8. Copywriting rules
Because the active screen has no copy, copy exists only in setup/settings.

Tone:
- plain
- non-clinical
- non-judgmental
- non-spiritual in public-facing App Store copy unless the user wants that framing

Avoid words like:
- stress score
- relationship tracker
- argument recorder
- biomarker
- surveillance
- proof

Suggested App Store-style description:

> A discreet haptic grounding app for Apple Watch. Start a tactile anchor from your watch face, stop it with one tap, and privately save a minimal time record for later reflection.
