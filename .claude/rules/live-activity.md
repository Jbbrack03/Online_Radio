---
paths:
  - "**/DFWGameDayRadioWidget/**"
  - "**/Shared/**"
  - "**/LiveActivityManager.swift"
---

# Live Activity Development

- `ScoreActivityAttributes` is shared between the main app and widget extension (lives in `Shared/`)
- Changes to `ScoreActivityAttributes` affect both targets — always rebuild both
- Live Activity views define four contexts: Lock Screen banner, expanded Dynamic Island, compact leading/trailing, minimal
- Use `.contentTransition(.numericText())` on score labels for animated score changes
- `ActivityKit` updates must happen on the main actor or via `await activity.update()`
- Live Activities require `NSSupportsLiveActivities = YES` in both target Info.plists
