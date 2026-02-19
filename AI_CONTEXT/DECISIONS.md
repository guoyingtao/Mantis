# Architectural Decisions

## AD-001: Protocol-Oriented Component Design

**Decision**: All major components are defined by internal protocols (`CropViewProtocol`, `CropViewModelProtocol`, `CropScrollViewProtocol`, etc.) and referenced by protocol type rather than concrete type.

**Rationale**: Enables test doubles via protocol conformance. Every component has a corresponding `Fake*` mock in the test suite. The factory in `Mantis.swift` assembles concrete types, so consumers never need to know implementation details.

**Consequences**: Adding a new method to a component requires updating both the protocol and all conforming types (including test mocks).

## AD-002: Factory Pattern for Object Graph Assembly

**Decision**: The public API consists solely of free functions in the `Mantis` namespace (`cropViewController(image:config:...)`) that build the entire dependency tree internally.

**Rationale**: Keeps the internal component graph hidden from consumers. A single call produces a fully configured `CropViewController`. This avoids exposing `CropView`, `CropViewModel`, `CropWorkbenchView`, etc. as public types.

**Consequences**: Custom subclasses of internal components are not supported. Customization is limited to `Config`, protocol-typed toolbar/rotation controls, and `CropViewController` subclassing (the class is `open`).

## AD-003: Closure-Based Reactive Updates (No Combine)

**Decision**: `CropViewModel` communicates state changes via closures (`statusChanged`, `cropBoxFrameChanged`) rather than Combine publishers, KVO, or delegate callbacks.

**Rationale**: Maintains iOS 12 compatibility (Combine requires iOS 13). Keeps the reactive layer lightweight without framework dependencies.

**Consequences**: Each closure must be wired up during initialization. No automatic subscriber lifecycle management.

## AD-004: Angle as Reference Type (NSObject Subclass)

**Decision**: `Angle` is a `final class` inheriting from `NSObject`, not a struct.

**Rationale**: Required for Objective-C interoperability with UIKit APIs that expect `NSObject`-based types. Supports `Comparable` conformance and arithmetic operators.

**Consequences**: Reference semantics — mutations to an `Angle` instance are visible to all holders. Copy-on-assign does not apply.

## AD-005: Singleton Undo/Redo Stack

**Decision**: `TransformStack.shared` is the only singleton in the project, managing ordered `TransformRecord` objects bridged to `UndoManager`.

**Rationale**: `UndoManager` is inherently session-scoped. A singleton coordinates the stack pointer (`top`) across undo/redo operations without threading stack references through the entire component hierarchy.

**Consequences**: Only one crop session can use undo/redo at a time. The stack must be cleared when a new session begins.

## AD-006: Programmatic Icon Rendering

**Decision**: All toolbar button icons are drawn programmatically via Core Graphics in `ToolBarButtonImageBuilder+DrawImage.swift`.

**Rationale**: Eliminates image asset dependencies, simplifies distribution, and allows dynamic color theming. Icons render at any resolution without asset catalogs.

**Consequences**: Adding or modifying icons requires Core Graphics drawing code rather than dropping in image files.

## AD-007: CropViewStatus State Machine

**Decision**: `CropView` rendering is driven by a `CropViewStatus` enum with 7 states (`.initial`, `.rotating`, `.degree90Rotating`, `.touchImage`, `.touchRotationBoard`, `.touchCropboxHandle`, `.betweenOperation`).

**Rationale**: Centralizes UI state transitions. The `render(by:)` method switches on status to show/hide grid, toggle dimming/blur, and manage rotation control visibility. Prevents inconsistent UI states.

**Consequences**: New interaction modes require adding enum cases and updating `render(by:)`.

## AD-008: Perspective Correction via CATransform3D + CIPerspectiveCorrection

**Decision** (feat/skew-correction branch): Skew is applied as a `CATransform3D` `sublayerTransform` on `CropWorkbenchView.layer` for live preview, and `CIPerspectiveCorrection` Core Image filter for final crop output.

**Rationale**: `CATransform3D` provides hardware-accelerated 3D perspective rendering for the live preview. `CIPerspectiveCorrection` provides pixel-accurate quadrilateral extraction at crop time. The two-path approach separates interactive performance from output quality.

**Consequences**: Crop box corners must be inverse-projected through the 3D transform to find source image coordinates. Binary search is used to compute compensating zoom scale (30 iterations in `PerspectiveTransformHelper`, 16 in `CropView` content inset calculation). Rate limiting (`maxChangeRatio = 0.03`) prevents visual jumps during rapid skew adjustments.

## AD-009: Shape Masking at Export Time

**Decision**: Non-rectangular crop shapes (ellipse, heart, diamond, polygon, custom path) are applied as alpha masks during image export, not during interactive cropping.

**Rationale**: The interactive crop box is always rectangular for simplicity of touch handling and resize math. The mask overlay (`CropDimmingView`/`CropVisualEffectView`) provides visual feedback of the final shape, but the actual pixel masking happens in `UIImageExtensions.swift` after the rectangular crop.

**Consequences**: The crop pipeline always produces a rectangular intermediate image, then applies the shape mask. This two-step process is simpler but means the intermediate image is larger than necessary for non-rectangular shapes.

## AD-010: Dual Mask View System (Dimming + Blur)

**Decision**: Two overlay views exist simultaneously — `CropDimmingView` (solid color) and `CropVisualEffectView` (blur effect) — managed by `CropMaskViewManager` which animates between them.

**Rationale**: During active manipulation (touch, rotation), the dimming view is shown for performance. At rest (`.betweenOperation`), the blur effect provides a polished Apple Photos-like appearance. Switching is animated for smooth transitions.

**Consequences**: Both views must be kept in sync regarding crop shape and frame. The manager must handle the animation timing between states.

## AD-011: SPM vs CocoaPods Build Differentiation

**Decision**: The compile-time flag `MANTIS_SPM` is defined in `Package.swift` to distinguish SPM builds from CocoaPods/manual Xcode project integration.

**Rationale**: Resource bundle location differs between SPM (`.module`) and CocoaPods (`Bundle(for:)`). The flag gates the correct bundle resolution path in `LocalizedHelper`.

**Consequences**: Both distribution paths must be tested. The `locateResourceBundle(by:)` public function exists specifically for CocoaPods hosts that need to override bundle resolution.

## AD-012: CropInfo as Tuple Type Alias

**Decision**: `CropInfo` is defined as a `public typealias` of a 13-field tuple rather than a struct.

**Rationale**: TODO — This appears to be a historical decision. A struct would provide named members and `Equatable`/`Codable` conformance more naturally.

**Consequences**: Tuple fields are positionally significant. Adding fields changes the type signature. Cannot conform to protocols like `Codable` directly.
