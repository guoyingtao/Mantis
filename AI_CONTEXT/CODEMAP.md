# Code Map

## Directory Structure

```
Sources/Mantis/
├── Mantis.swift                          # Factory functions — PUBLIC API entry point
├── Config.swift                          # Top-level Config struct
├── CropViewConfig.swift                  # Canvas/view configuration
├── CropToolbarConfig.swift               # Toolbar configuration
├── CropAuxiliaryIndicatorConfig.swift    # Grid/handle appearance config
├── Enum.swift                            # Shared enums (CropShapeType, CropMode, etc.)
├── CropData.swift                        # Core data types (Transformation, CropInfo, CropState, CropRegion)
├── Angle.swift                           # Angle class (degrees/radians, NSObject subclass)
├── Definition.swift                      # Internal type aliases
├── Global.swift                          # Global utilities
├── RatioOptions.swift                    # Aspect ratio option set
├── ToolbarButtonOptions.swift            # Toolbar button option set
│
├── Protocols/
│   ├── CropViewControllerDelegate.swift  # PUBLIC — host app receives crop results
│   ├── CropToolbarProtocol.swift         # PUBLIC — custom toolbar interface
│   ├── CropViewProtocol.swift            # Internal — full CropView interface
│   ├── CropViewModelProtocol.swift       # Internal — ViewModel interface
│   ├── CropScrollViewProtocol.swift      # Internal — CropWorkbenchView interface
│   ├── CropMaskViewManagerProtocol.swift # Internal — mask overlay manager
│   ├── CropAuxiliaryIndicatorViewProtocol.swift # Internal — crop handles/grid
│   ├── ImageContainerProtocol.swift      # Internal — image wrapper
│   ├── RotationDialProtocol.swift        # Internal — circular dial
│   ├── RotationDialViewModelProtocol.swift # Internal — dial VM
│   └── TransformDelegate.swift           # Internal — undo/redo bridge
│
├── CropView/
│   ├── CropView.swift                    # CORE — main crop canvas (UIView)
│   ├── CropView+Touches.swift            # Touch handling for crop gestures
│   ├── CropView+UIScrollViewDelegate.swift # Scroll view delegate methods
│   ├── CropViewModel.swift               # Crop state management (MVVM ViewModel)
│   ├── CropViewStatus.swift              # State enum driving render()
│   ├── CropWorkbenchView.swift           # UIScrollView hosting the image
│   ├── ImageContainer.swift              # UIView wrapping UIImageView
│   ├── CropAuxiliaryIndicatorView.swift  # Crop box handles & grid overlay
│   ├── CropAuxiliaryIndicatorView+Accessibility.swift
│   ├── CropMaskViewManager.swift         # Manages dimming/blur overlays
│   ├── CropBoxFreeAspectFrameUpdater.swift  # Free-form crop box resizing math
│   └── CropBoxLockedAspectFrameUpdater.swift # Locked-ratio crop box resizing math
│
├── CropViewController/
│   ├── CropViewController.swift          # PUBLIC — open UIViewController subclass
│   ├── CropToolbar.swift                 # Default toolbar implementation
│   ├── ToolBarButtonImageBuilder.swift   # Programmatic icon drawing
│   ├── ToolBarButtonImageBuilder+DrawImage.swift
│   ├── FixedRatioManager.swift           # Ratio list computation
│   ├── RatioPresenter.swift              # Ratio popover (UIAlertController)
│   ├── RatioSelector.swift               # Always-visible ratio list
│   └── RatioItemView.swift               # Individual ratio button
│
├── Helpers/
│   ├── PerspectiveTransformHelper.swift  # 3D skew math (CATransform3D, projection, binary search)
│   ├── TransformRecord.swift             # UndoManager record wrapper
│   ├── TransformStack.swift              # Singleton undo/redo stack
│   ├── ImageAutoAdjustHelper.swift       # Vision-based horizon detection
│   ├── GeometryHelper.swift              # Inscribe rect, crop edge detection
│   ├── Orientation.swift                 # Device orientation helpers
│   └── LocalizedHelper.swift             # NSLocalizedString wrapper
│
├── MaskBackground/
│   ├── CropMaskProtocal.swift            # Protocol for mask views (note: typo in filename)
│   ├── CropDimmingView.swift             # Solid dark overlay with shape cutout
│   └── CropVisualEffectView.swift        # Blur overlay with shape cutout
│
├── RotationDial/
│   ├── RotationTypeSelector.swift        # Straighten/H-Skew/V-Skew segmented control
│   ├── RotationDial/
│   │   ├── RotationDial.swift            # Circular rotation knob
│   │   ├── RotationDial+Touches.swift
│   │   ├── RotationDialPlate.swift       # Visual plate with tick marks
│   │   ├── RotationDialViewModel.swift
│   │   ├── RotationDialConfig.swift
│   │   └── RotationCalculator.swift      # Touch-to-angle conversion
│   └── SlideDial/
│       ├── SlideDial.swift               # Linear slide ruler control
│       ├── SlideRuler.swift              # Visual ruler with panning
│       ├── SlideDialViewModel.swift      # Tracks angles per adjustment type
│       ├── SlideDialConfig.swift         # .simple | .withTypeSelector modes
│       ├── SlideDialTypeButton.swift     # Type button (straighten/h-skew/v-skew)
│       └── SlideRulerPositionHelper.swift
│
├── SwiftUIView/
│   └── ImageCropper.swift                # UIViewControllerRepresentable bridge
│
├── Extensions/
│   ├── UIImageExtensions.swift           # Crop pipeline, perspective crop, shape masking
│   ├── CGImageExtensions.swift           # CGContext-based image transformation
│   ├── CoreGraphicsExtensions.swift      # CGRect/CGPoint/CGVector math, NaN guards
│   ├── CGAffineTransformExtensions.swift # CropInfo-based transform composition
│   └── UIViewExtensions.swift            # Subview search, bringToFront
│
└── Resources/
    └── MantisLocalizable.strings/        # 15 language localizations
```

## Component Dependency Graph

```
Mantis.swift (factory)
└── CropViewController (open class, UIViewController)
    ├── CropView (UIView, implements CropViewProtocol)
    │   ├── CropViewModel (implements CropViewModelProtocol)
    │   ├── CropWorkbenchView (UIScrollView)
    │   │   └── ImageContainer (UIView wrapping UIImageView)
    │   ├── CropAuxiliaryIndicatorView (crop box + handles)
    │   ├── CropMaskViewManager
    │   │   ├── CropDimmingView
    │   │   └── CropVisualEffectView
    │   ├── RotationTypeSelector (straighten/h-skew/v-skew segmented control)
    │   └── RotationControlView (one of, via RotationControlViewProtocol)
    │       ├── RotationDial (circular knob)
    │       └── SlideDial (linear ruler)
    │           └── SlideRuler
    ├── CropToolbar (default, or custom via CropToolbarProtocol)
    ├── RatioPresenter / RatioSelector
    ├── ImageAutoAdjustHelper
    └── TransformStack.shared (undo/redo singleton)
        └── TransformRecord[] → UndoManager
```

## Delegate / Communication Chains

```
Host App ← CropViewControllerDelegate ← CropViewController
CropViewController ← CropViewDelegate ← CropView
CropViewController ← CropToolbarDelegate ← CropToolbar
CropView ← closure ← RotationControlViewProtocol.didUpdateRotationValue (RotationDial or SlideDial)
CropView ← RotationTypeSelectorDelegate ← RotationTypeSelector
SlideDial ← SlideRulerDelegate ← SlideRuler
CropViewController ← TransformDelegate → TransformStack → UndoManager
```

## Key Data Types

| Type | Kind | Visibility | Purpose |
|------|------|-----------|---------|
| `Transformation` | struct | public | Serializable crop result (offset, rotation, scale, flips, skew) |
| `CropInfo` | typealias (tuple) | public | Full crop parameters for image processing |
| `CropRegion` | struct | public | Normalized corner points of crop area |
| `CropState` | struct | internal | Undo/redo snapshot of full crop state |
| `CropOutput` | typealias (tuple) | internal | (croppedImage, transformation, cropInfo) |
| `Angle` | class (NSObject) | internal | Reference-type angle with degrees/radians conversion |
| `CropViewStatus` | enum | internal | State machine driving CropView.render() |
| `ImageRotationType` | enum | internal | 0/90/180/270 degree rotation tracking |
| `RotationAdjustmentType` | enum | internal | .straighten / .horizontalSkew / .verticalSkew |

## Hot Paths (most-edited files for common tasks)

- **Adding a crop feature**: `CropView.swift`, `CropViewModel.swift`, `CropViewProtocol.swift`
- **Changing toolbar**: `CropToolbar.swift`, `CropToolbarConfig.swift`, `ToolbarButtonOptions.swift`
- **Modifying crop output**: `UIImageExtensions.swift`, `CGImageExtensions.swift`, `CropData.swift`
- **Rotation/skew behavior**: `PerspectiveTransformHelper.swift`, `SlideDial.swift`, `SlideDialViewModel.swift`
- **Configuration changes**: `Config.swift`, `CropViewConfig.swift`, `Enum.swift`
- **Undo/redo**: `TransformStack.swift`, `TransformRecord.swift`, `CropViewController.swift`
