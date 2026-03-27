---
paths:
  - "**/*.swift"
---

# Swift Style

- Use `@Observable` macro (iOS 17+ Observation framework), not `ObservableObject`/`@Published`/`@StateObject`
- Use `@State private var` to hold `@Observable` objects in SwiftUI views
- Prefer `async`/`await` over Combine for asynchronous work
- Use `Task {}` for launching async work from synchronous contexts
- Singletons: `static let shared` with `private init()`
- No third-party dependencies — use Apple frameworks only
- Deployment target: iOS 17.0 minimum
