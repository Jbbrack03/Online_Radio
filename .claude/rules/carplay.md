---
paths:
  - "**/CarPlay/**"
---

# CarPlay Development

- CarPlay audio apps use template-based UI only: `CPTabBarTemplate`, `CPListTemplate`, `CPNowPlayingTemplate`
- No custom SwiftUI views in CarPlay — the framework provides all UI
- Template depth limit: 5 levels
- `CPNowPlayingTemplate.shared` is a singleton — don't instantiate it
- Audio metadata flows through `MPNowPlayingInfoCenter`, not CarPlay templates directly
- Test in Xcode CarPlay Simulator (no Apple entitlement needed for simulator)
- The `com.apple.developer.carplay-audio` entitlement is only enforced for App Store distribution
