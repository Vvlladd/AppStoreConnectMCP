---
name: swift-concurrency-expert
description: Swift Concurrency review and remediation for Swift 6.2+. Use when asked to review Swift Concurrency usage, improve concurrency compliance, or fix Swift concurrency compiler errors in a feature or file.
---

# Swift Concurrency Expert

## Overview

Review and fix Swift Concurrency issues in Swift 6.2+ codebases by applying actor isolation, Sendable safety, and modern concurrency patterns with minimal behavior changes.

## Workflow

### 1. Triage the issue

- Capture the exact compiler diagnostics and the offending symbol(s).
- Identify the current actor context (`@MainActor`, `actor`, `nonisolated`) and whether a default actor isolation mode is enabled.
- Confirm whether the code is UI-bound or intended to run off the main actor.

### 2. Apply the smallest safe fix

Prefer edits that preserve existing behavior while satisfying data-race safety.

Common fixes:
- **UI-bound types**: annotate the type or relevant members with `@MainActor`.
- **Protocol conformance on main actor types**: make the conformance isolated (e.g., `extension Foo: @MainActor SomeProtocol`).
- **Global/static state**: protect with `@MainActor` or move into an actor.
- **Background work**: move expensive work into a `@concurrent` async function on a `nonisolated` type or use an `actor` to guard mutable state.
- **Sendable errors**: prefer immutable/value types; add `Sendable` conformance only when correct; avoid `@unchecked Sendable` unless you can prove thread safety.

## Swift 6.2 Approachable Concurrency

Swift 6.2 introduces "Approachable Concurrency" that simplifies concurrent programming for common use cases. Key features include:

- **Global actor isolation by default**: New projects created with Xcode 26 have code running on the main actor by default
- **Simplified Sendable**: Global-actor-isolated types (like `@MainActor` structs/classes) automatically satisfy Sendable requirements
- **Easier property access**: Can access Sendable properties more easily across actor boundaries
- **Automatic @Sendable**: Certain functions and closures are automatically treated as `@Sendable`

## Reference Resources

### Official Apple Documentation
- [Sendable Protocol](https://developer.apple.com/documentation/Swift/Sendable) - Thread-safe types for concurrent contexts
- [Swift Evolution SE-0306: Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md) - Actor isolation design and implementation

### Swift 6.2 Resources
- [Approachable Concurrency in Swift 6.2: A Clear Guide](https://www.avanderlee.com/concurrency/approachable-concurrency-in-swift-6-2-a-clear-guide/)
- [Swift 6.2 Approachable Concurrency](https://www.infoq.com/news/2025/08/swift62-approachable-concurrency/) - Overview of new features
- [Should you opt-in to Swift 6.2's Main Actor isolation?](https://www.donnywals.com/should-you-opt-in-to-swift-6-2s-main-actor-isolation/)

### Community Guides
- [Understanding Concurrency in Swift 6](https://medium.com/@egzonpllana/understanding-concurrency-in-swift-6-with-sendable-protocol-mainactor-and-async-await-5ccfdc0ca2b6)
- [Practical Swift Concurrency](https://medium.com/@petrachkovsergey/practical-swift-concurrency-actors-isolation-sendability-a51343c2e4db)
- [Complete concurrency enabled by default](https://www.hackingwithswift.com/swift/6.0/concurrency) - Hacking with Swift guide
