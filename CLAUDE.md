# DFW GameDay Radio

A personal-use iOS/CarPlay app that streams Dallas sports radio and displays game scores on a configurable delay, syncing Live Activity updates with the radio broadcast.

## Quick Reference

- **Xcode project**: `DFWGameDayRadio/DFWGameDayRadio.xcodeproj`
- **Project generator**: `cd DFWGameDayRadio && xcodegen generate` (uses `project.yml`)
- **Build**: `xcodebuild -project DFWGameDayRadio/DFWGameDayRadio.xcodeproj -scheme DFWGameDayRadio -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- **Min deployment**: iOS 17.0
- **Swift version**: 5.9
- **Dependencies**: None (all Apple frameworks)

## Architecture

Two targets:
1. **DFWGameDayRadio** (iOS app) — radio streaming, ESPN polling, delay queue, CarPlay UI, phone UI
2. **DFWGameDayRadioWidget** (widget extension) — Live Activity views for Dynamic Island and Lock Screen

Shared code between targets lives in `DFWGameDayRadio/Shared/`.

### Core data flow

```
ESPNScoreService (polls every 10s)
  → ScoreDelayQueue (holds scores for N seconds)
    → LiveActivityManager (updates Dynamic Island / Lock Screen)
    → In-app score display
```

`GameCoordinator` wires these services together when the user selects a station.

### Key services

| Service | Responsibility |
|---------|---------------|
| `AudioStreamManager` | AVPlayer streaming, MPNowPlayingInfoCenter, MPRemoteCommandCenter |
| `ESPNScoreService` | Polls ESPN scoreboard API, filters for Dallas teams |
| `ScoreDelayQueue` | FIFO delay buffer — the core feature that syncs scores to radio |
| `LiveActivityManager` | ActivityKit lifecycle for Live Activities |
| `GameCoordinator` | Orchestrates all services when a station is selected |

## Conventions

- Use `@Observable` (Observation framework), not `ObservableObject`/`@Published`
- Singletons via `static let shared` for service classes
- SwiftUI for phone UI, CarPlay framework templates for car UI
- No external dependencies — Apple frameworks only
- Stream URLs use StreamTheWorld `livestream-redirect` endpoints as stable fallbacks

## Teams and Stations

| Team | Station | Stream Key |
|------|---------|-----------|
| Cowboys / Rangers | 105.3 The Fan (KRLD-FM) | `KRLDFMAAC` |
| Mavericks | 97.1 The Eagle (KEGL-FM) | `KEGLFMAAC` |
| Stars | 96.7 The Ticket (KTCK) | `KTCKAMAAC` |

## ESPN API

No auth required. Endpoints:
- NFL: `site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard`
- MLB: `site.api.espn.com/apis/site/v2/sports/baseball/mlb/scoreboard`
- NBA: `site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard`
- NHL: `site.api.espn.com/apis/site/v2/sports/hockey/nhl/scoreboard`

ESPN team IDs: Cowboys=6, Rangers=13, Mavericks=7, Stars=25

## CarPlay

- Entitlement: `com.apple.developer.carplay-audio` (works in simulator without Apple approval)
- Test with: Xcode > Window > Devices and Simulators (CarPlay Simulator)
- Templates: `CPTabBarTemplate` → stations list + `CPNowPlayingTemplate`
