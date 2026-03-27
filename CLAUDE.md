# DFW GameDay Radio

A personal-use iOS/CarPlay app that streams Dallas sports radio and displays game scores on a configurable delay, syncing Live Activity updates with the radio broadcast. Features sport-specific situation data (baseball diamond, football field position, etc.) and auto-estimated stream latency.

## Quick Reference

- **Xcode project**: `DFWGameDayRadio/DFWGameDayRadio.xcodeproj`
- **Project generator**: `cd DFWGameDayRadio && xcodegen generate` (uses `project.yml`)
- **Build**: `xcodebuild -project DFWGameDayRadio/DFWGameDayRadio.xcodeproj -scheme DFWGameDayRadio -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
- **Min deployment**: iOS 17.0
- **Swift version**: 5.9
- **Dependencies**: None (all Apple frameworks)

## Architecture

Two targets:
1. **DFWGameDayRadio** (iOS app) — radio streaming, multi-provider score polling, delay queue, CarPlay UI, phone UI
2. **DFWGameDayRadioWidget** (widget extension) — Live Activity views for Dynamic Island and Lock Screen

Shared code between targets lives in `DFWGameDayRadio/Shared/` (GameSituation model, ScoreActivityAttributes, situation views).

### Core data flow

```
ScoreProvider (league-native API per sport, polls every 10s)
  → GameCoordinator (routes providers, feeds delay queue every 2s)
    → ScoreDelayQueue (holds scores for estimated latency ± user offset)
      → LiveActivityManager (updates Dynamic Island / Lock Screen with situation data)
      → In-app score display (sport-specific views)
```

`GameCoordinator` is the single entry point — both StationPickerView and CarPlayTemplateManager delegate to it.

### Key services

| Service | Responsibility |
|---------|---------------|
| `AudioStreamManager` | AVPlayer streaming, MPNowPlayingInfoCenter, MPRemoteCommandCenter |
| `GameCoordinator` | Central hub: audio + score tracking + latency estimation + live activities |
| `StreamLatencyEstimator` | Auto-estimates stream delay via HLS probe, buffer monitoring, per-station defaults |
| `ScoreDelayQueue` | FIFO delay buffer using estimated latency ± user fine-tune offset |
| `LiveActivityManager` | ActivityKit lifecycle for Live Activities with situation data |
| `ESPNScoreService` | NFL scores + situation (down/distance/field position) via ESPN API |
| `MLBScoreService` | Rangers scores + situation (count/runners/batter/pitcher) via MLB Stats API |
| `NHLScoreService` | Stars scores + situation (power play/SOG) via NHL API |
| `NBAScoreService` | Mavericks scores + situation (timeouts/bonus) via NBA CDN |

### ScoreProvider protocol

All score services conform to `ScoreProvider` protocol (`activeGames`, `startPolling`, `stopPolling`). GameCoordinator routes: Rangers→MLB, Stars→NHL, Mavericks→NBA, Cowboys→ESPN.

## Conventions

- Use `@Observable` (Observation framework), not `ObservableObject`/`@Published`
- Singletons via `static let shared` for service classes
- SwiftUI for phone UI, CarPlay framework templates for car UI
- No external dependencies — Apple frameworks only
- All score services follow the same polling pattern with 10s intervals

## Teams and Stations

| Team | Station | Stream Platform | Primary URL |
|------|---------|----------------|-------------|
| Cowboys / Rangers | 105.3 The Fan (KRLD-FM) | Audacy/AmperWave | `live.amperwave.net/direct/audacy-krldfmaac-imc` |
| Mavericks | 97.1 The Eagle (KEGL-FM) | iHeartMedia | `stream.revma.ihrhls.com/zc2241` |
| Stars | 96.7 The Ticket (KTCK) | Triton Digital | `streamtheworld.com/.../KTCKAMAAC.aac?burst-time=0` |

HLS fallback URLs available for KRLD-FM and KEGL-FM (used by StreamLatencyEstimator for auto-sync probing).

## Score APIs

All free, no auth required:

| Sport | API | Key Endpoint | Situation Data |
|-------|-----|-------------|----------------|
| NFL | ESPN | `site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard` | Down, distance, yard line, possession |
| MLB | MLB Stats API | `statsapi.mlb.com/api/v1.1/game/{gamePk}/feed/live` | Balls, strikes, outs, runners, batter/pitcher |
| NBA | NBA CDN | `cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json` | Timeouts, bonus |
| NHL | NHL API | `api-web.nhle.com/v1/gamecenter/{gameId}/play-by-play` | Power play, SOG |

ESPN team IDs: Cowboys=6, Rangers=13, Mavericks=7, Stars=25

## Stream Latency Auto-Sync

`StreamLatencyEstimator` uses three strategies (priority order):
1. **HLS probe** — briefly connects muted AVPlayer to HLS fallback URL, reads `currentDate()` for wall-clock latency
2. **Cached measurement** — per-station latency from previous sessions (UserDefaults)
3. **Research-based defaults** — KRLD ~30s, KEGL ~15s, KTCK ~10s

Effective delay = `estimatedStreamLatency - apiLatency + userOffset`

## CarPlay

- Entitlement: `com.apple.developer.carplay-audio` (works in simulator without Apple approval)
- Test with: Xcode > Window > Devices and Simulators (CarPlay Simulator)
- Templates: `CPTabBarTemplate` → stations list (with team logos) + `CPNowPlayingTemplate` (with delay ±5s buttons)
- Score displayed in Now Playing metadata (artist field)
- Max 4 tabs, max 2 navigation levels per tab, some cars limit lists to 12 items
