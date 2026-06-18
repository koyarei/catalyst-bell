# Data Model: Catalyst Bell

## 1. Data minimization principle
Only store what is needed for later gentle reflection. Do not store data that can turn the app into surveillance, evidence gathering, or body monitoring.

## 2. SessionRecord schema
```json
{
  "id": "UUID",
  "schemaVersion": 1,
  "startDate": "2026-06-17T20:42:12-05:00",
  "endDate": "2026-06-17T20:46:31-05:00",
  "durationSeconds": 259,
  "endReason": "userStopped",
  "launchSource": "complication",
  "moonPhase": {
    "name": "Waxing Crescent",
    "fraction": 0.23,
    "calculationMethod": "offlineSynodicApproximation"
  },
  "location": {
    "permissionStatus": "allowed",
    "granularity": "coarseRoundedCoordinate",
    "latitudeRounded": 30.27,
    "longitudeRounded": -97.74,
    "locality": "Austin",
    "administrativeArea": "TX",
    "countryCode": "US"
  },
  "createdAt": "2026-06-17T20:46:32-05:00",
  "appVersion": "0.1.0"
}
```

## 3. Required fields
- `id`
- `schemaVersion`
- `startDate`
- `endDate`
- `durationSeconds`
- `endReason`
- `launchSource`
- `moonPhase.name`
- `createdAt`
- `appVersion`

## 4. Optional fields
- `moonPhase.fraction`
- `location`

## 5. Field definitions
### id
UUID generated at session start or save time.

### schemaVersion
Integer. Start at `1`.

### startDate
The exact timestamp when haptic grounding began.

### endDate
The exact timestamp when haptics stopped.

### durationSeconds
Computed as `endDate - startDate`.

### endReason
Enum:
- `userStopped`
- `maxDurationReached`
- `runtimeExpired`
- `systemInterrupted`
- `appTerminated`
- `unknown`

### launchSource
Enum:
- `complication`
- `appIcon`
- `shortcut`
- `debug`
- `unknown`

### moonPhase.name
Enum:
- `New Moon`
- `Waxing Crescent`
- `First Quarter`
- `Waxing Gibbous`
- `Full Moon`
- `Waning Gibbous`
- `Last Quarter`
- `Waning Crescent`

### moonPhase.fraction
Optional numeric value from 0.0 to 1.0, depending on algorithm.

### location.permissionStatus
Enum:
- `notRequested`
- `denied`
- `allowed`
- `unavailable`

### location.granularity
Enum:
- `none`
- `coarseRoundedCoordinate`
- `localityOnly`

### latitudeRounded / longitudeRounded
Coordinates rounded for privacy. Recommended rounding: 2 decimal places or less precise.

### locality / administrativeArea / countryCode
Optional fields if reverse geocoding is implemented.

## 6. Storage
Recommended MVP storage:
- local JSON file named `sessions.json`, or
- SwiftData model if target platform supports it comfortably

JSON storage shape:
```json
{
  "schemaVersion": 1,
  "records": []
}
```

## 7. Retention
MVP default: local indefinite retention with delete-all option.

Future option:
- auto-delete after 30/90/365 days
- export before deletion

## 8. Deletion
The app must support deleting all local records from settings or iPhone companion.

If iPhone companion sync exists, delete-all should delete from both watch and phone after confirmation.

## 9. Data that must never be added to SessionRecord in MVP
- audio file path
- transcript
- contact/person name
- spouse/relationship label
- heart rate
- respiratory rate
- perspiration
- sleep data
- stress score
- emotion inference
- sentiment analysis
- AI summary
