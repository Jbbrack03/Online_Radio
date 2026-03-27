---
paths:
  - "**/ESPNScoreService.swift"
  - "**/ESPNResponse.swift"
  - "**/ScoreDelayQueue.swift"
---

# ESPN API Integration

- The ESPN scoreboard API is unofficial but has been stable since ~2016 with no auth required
- All Codable properties that might be missing should be optional
- Poll interval: 10 seconds during active games
- Always filter events by ESPN team ID, not team name (names can vary)
- The delay queue is the core feature — scores enter the queue timestamped and release after `delaySeconds` elapses
- Score deduplication: only enqueue if the score actually changed from the last enqueued or currently displayed value
