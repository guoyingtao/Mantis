# Project Context

## Overview

Mantis is an iOS image cropping library written in Swift. It provides a full-featured crop UI (rotation, aspect ratio locking, perspective skew correction, shape masking, undo/redo) as both a UIKit `CropViewController` and a SwiftUI `ImageCropper` wrapper.

## Quick Facts

| Key | Value |
|-----|-------|
| Language | Swift |
| Min iOS | 12.0 |
| Min macCatalyst | 13.0 |
| Swift Tools | 5.5 |
| External Dependencies | None |
| Distribution | SPM, CocoaPods (compile flag `MANTIS_SPM` differentiates) |
| Test Framework | XCTest |
| Localization | 15 languages via `.strings` resource files |

## Entry Points

### Public Factory Functions (`Mantis.swift`)

All consumers create crop UI through free functions in the `Mantis` namespace:

```swift
// Standard creation
Mantis.cropViewController(image:config:cropToolbar:rotationControlView:) -> CropViewController

// Generic variant for custom CropViewController subclasses
Mantis.cropViewController<T: CropViewController>(...) -> T

// Setup an existing CropViewController instance
Mantis.setupCropViewController(_:config:cropToolbar:rotationControlView:)

// Headless crop (no UI)
Mantis.crop(image:by:) -> UIImage?
```

### SwiftUI Entry Point (`ImageCropper.swift`)

`ImageCropperView` — a `UIViewControllerRepresentable` wrapping `CropViewController`. Uses `@Binding` for image output, transformation, crop info, and a `CropAction?` command pattern for triggering operations from SwiftUI.

## Configuration Hierarchy

```
Mantis.Config (top-level)
├── cropViewConfig: CropViewConfig        — canvas behavior (shape, zoom, padding, skew)
│   └── cropAuxiliaryIndicatorConfig      — grid lines & handle appearance
├── cropToolbarConfig: CropToolbarConfig  — toolbar layout, buttons, ratio UI
├── ratioOptions: RatioOptions
├── presetFixedRatioType: PresetFixedRatioType
├── cropMode: CropMode (.sync | .async)
├── enableUndoRedo: Bool
└── showAttachedCropToolbar: Bool
```

## Major Features

- Free-form and fixed-ratio cropping
- Rotation via circular dial or slide ruler
- 90-degree rotation (clockwise / counterclockwise)
- Horizontal and vertical flip
- Perspective correction / skew (horizontal & vertical) via 3D transforms
- Shape masking: rect, ellipse, circle, roundedRect, heart, diamond, polygon, custom path
- Undo / redo with `UndoManager` integration
- Auto-adjust (horizon detection via Vision framework)
- Preset transformations (restore previous crop state)
- Async crop mode with custom activity indicator
- Full accessibility support on crop handles
- Programmatic toolbar icon rendering (no image assets)

## Build & Test

- Build: Open `Mantis.xcworkspace` or use SPM (`swift build`)
- Tests: Run the `MantisTests` target in Xcode (XCTest-based, protocol mock injection)

## Current Branch

`feat/skew-correction` — adds perspective correction (horizontal/vertical skew) feature using `CATransform3D` and `CIPerspectiveCorrection`.
