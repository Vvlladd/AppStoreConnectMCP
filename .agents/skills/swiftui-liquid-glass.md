---
name: swiftui-liquid-glass
description: Implement, review, or improve SwiftUI features using the iOS 26+ Liquid Glass API. Use when asked to adopt Liquid Glass in new SwiftUI UI, refactor an existing feature to Liquid Glass, or review Liquid Glass usage for correctness, performance, and design alignment.
---

# SwiftUI Liquid Glass

## Overview
Use this skill to build or review SwiftUI features that fully align with the iOS 26+ Liquid Glass API. Prioritize native APIs (`glassEffect`, `GlassEffectContainer`, glass button styles) and Apple design guidance. Keep usage consistent, interactive where needed, and performance aware.

## What is Liquid Glass?

Liquid Glass is Apple's most significant design evolution since iOS 7, introduced at WWDC 2025 for iOS 26. It's a translucent, dynamic material that reflects and refracts surrounding content while transforming to bring focus to user tasks.

**Key Features:**
- Real-time light bending (lensing)
- Specular highlights responding to device motion
- Adaptive shadows
- Interactive behaviors
- Unified design language across all Apple platforms (iOS, iPadOS, macOS, watchOS, tvOS, visionOS)

## Workflow Decision Tree
Choose the path that matches the request:

### 1) Review an existing feature
- Inspect where Liquid Glass should be used and where it should not.
- Verify correct modifier order, shape usage, and container placement.
- Check for iOS 26+ availability handling and sensible fallbacks.

### 2) Improve a feature using Liquid Glass
- Identify target components for glass treatment (surfaces, chips, buttons, cards).
- Refactor to use `GlassEffectContainer` where multiple glass elements appear.
- Introduce interactive glass only for tappable or focusable elements.

### 3) Implement a new feature using Liquid Glass
- Design the glass surfaces and interactions first (shape, prominence, grouping).
- Add glass modifiers after layout/appearance modifiers.
- Add morphing transitions only when the view hierarchy changes with animation.

## Core Guidelines
- Prefer native Liquid Glass APIs over custom blurs.
- Use `GlassEffectContainer` when multiple glass elements coexist.
- Apply `.glassEffect(...)` after layout and visual modifiers.
- Use `.interactive()` for elements that respond to touch/pointer.
- Keep shapes consistent across related elements for a cohesive look.
- Gate with `#available(iOS 26, *)` and provide a non-glass fallback.
- **For iOS 26+ minimum deployment projects**: Skip `#available(iOS 26, *)` checks entirely.

## Tint Selection & Color Contrast
When using `.tint()` with glass effects, color selection is critical for visibility and aesthetic:

- **Test contrast**: Ensure sufficient contrast between tint color and background
  - Example: Pink/magenta (#EC4899) works better than green/emerald (#10B981) against blue backgrounds
  - Example: Orange works well against most cool-toned backgrounds
- **Optimal opacity**: Use 0.12-0.15 for tint opacity
  - 0.12 for subtle effects (badges, non-interactive elements)
  - 0.15 for interactive elements (pickers, buttons) requiring stronger visibility
- **Semantic colors**: Use colors from your Theme/design system for consistency
  - Match tint colors to related icons or content when possible
  - Example: Orange tint for "end time" picker matching orange house icon
- **Visual distinction**: Use different tints to distinguish between related elements
  - Example: Pink for start time, orange for end time creates clear visual separation

## Review Checklist
- **Availability**: `#available(iOS 26, *)` present with fallback UI (skip for iOS 26+ minimum deployment).
- **Composition**: Multiple glass views wrapped in `GlassEffectContainer`.
- **Modifier order**: `glassEffect` applied after layout/appearance modifiers.
- **Interactivity**: `interactive()` only where user interaction exists.
- **Transitions**: `glassEffectID` used with `@Namespace` for morphing.
- **Consistency**: Shapes, tinting, and spacing align across the feature.
- **Color contrast**: Tint colors provide sufficient contrast against backgrounds (0.12-0.15 opacity).

## Implementation Checklist
- Define target elements and desired glass prominence.
- Wrap grouped glass elements in `GlassEffectContainer` and tune spacing.
- Use `.glassEffect(.regular.tint(...).interactive(), in: .rect(cornerRadius: ...))` as needed.
- Choose tint colors with good contrast against backgrounds (0.12-0.15 opacity).
- Use `.buttonStyle(.glass)` / `.buttonStyle(.glassProminent)` for actions.
- Add morphing transitions with `glassEffectID` when hierarchy changes.
- Provide fallback materials and visuals for earlier iOS versions (skip for iOS 26+ minimum deployment).

## Quick Snippets
Use these patterns directly and tailor shapes/tints/spacing.

**Basic glass effect with availability check:**
```swift
if #available(iOS 26, *) {
    Text("Hello")
        .padding()
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
} else {
    Text("Hello")
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
}
```

**Tinted glass with proper opacity (iOS 26+ only project):**
```swift
Picker("Start Time", selection: $selectedTime) {
    ForEach(times, id: \.self) { time in
        Text(time).tag(time)
    }
}
.pickerStyle(.wheel)
.padding()
.glassEffect(
    .regular.tint(Color.pink.opacity(0.15)).interactive(),
    in: .rect(cornerRadius: 12)
)
```

**Multiple glass elements in container:**
```swift
GlassEffectContainer(spacing: 24) {
    HStack(spacing: 24) {
        Image(systemName: "scribble.variable")
            .frame(width: 72, height: 72)
            .font(.system(size: 32))
            .glassEffect()
        Image(systemName: "eraser.fill")
            .frame(width: 72, height: 72)
            .font(.system(size: 32))
            .glassEffect()
    }
}
```

**Glass button styles:**
```swift
Button("Confirm") { }
    .buttonStyle(.glassProminent)
```

## Official Apple Resources
- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views) - Official Apple documentation
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass) - Apple tutorial
- [Build a SwiftUI app with the new design - WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/) - WWDC 2025 session

## Community Resources
- [Designing custom UI with Liquid Glass on iOS 26](https://www.donnywals.com/designing-custom-ui-with-liquid-glass-on-ios-26/) - Donny Wals guide
- [Build a Liquid Glass Design System in SwiftUI](https://levelup.gitconnected.com/build-a-liquid-glass-design-system-in-swiftui-ios-26-bfa62bcba5be) - Design system guide
- [iOS 26 Explained: Apple's Biggest Update for Developers](https://www.index.dev/blog/ios-26-developer-guide)
