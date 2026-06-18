# Engineering Notes and Decisions

## 1. Why no active-session text
The app is used during socially sensitive catalyst. A visible phrase on the watch could become another point of conflict. The active screen must therefore be dark and non-expressive. Haptics carry the instruction.

## 2. Why no completion message
After the user stops the session, they may still be in the argument or near the other person. A visible saved state could invite questions. Save silently.

## 3. Why no biometrics
Biometrics would shift the app toward self-surveillance, stress optimization, and possible misinterpretation. The MVP is a grounding ritual, not a health monitor.

## 4. Why no recording
Recording could distort trust and turn the app into an evidence collector. It is outside the product's ethical boundary.

## 5. Why moon phase is acceptable
Moon phase is context rather than surveillance. It adds a gentle time marker and can be computed offline. It should not be interpreted as causing catalyst.

## 6. Why location must be optional
Location can reveal sensitive patterns. It must be optional, coarse, and never required for the grounding function.

## 7. Suggested default haptic patterns
Test these on real hardware:

### Gentle
- `.click` every 4 seconds

### Slow Breath
- `.click`, 5-second gap, `.click`, 7-second gap

### Steady
- `.click` every 3 seconds

Avoid complicated patterns until hardware testing proves they are distinguishable and calming.

## 8. Debug mode
Developers may need visible debug UI. Keep it behind a compile-time flag:

```swift
#if DEBUG
Text("Active")
#endif
```

Never ship active-session text in production.

## 9. App icon direction
Neutral visual language:
- dot
- ripple
- crescent
- bell outline
- dark circle

Avoid:
- argument imagery
- stressed face
- heart rate line
- religious iconography
- therapy/medical iconography

## 10. Product positioning
Best positioning:

> A discreet haptic anchor for emotionally intense moments.

Avoid positioning:

> Tracks arguments, stress, or relationship conflict.
