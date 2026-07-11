import XCTest
@testable import Mantis

/// Guards the toolbar icon builder after the iOS-15 cleanup removed the
/// pre-iOS-13 hand-drawn fallbacks. Every button icon must still resolve —
/// the SF Symbol names must be valid, and the two remaining hand-drawn icons
/// (vertical flip, alter-cropper-90°) must still render.
final class ToolBarButtonImageBuilderTests: XCTestCase {
    func testAllButtonIconsResolve() {
        XCTAssertNotNil(ToolBarButtonImageBuilder.rotateCCWImage(), "rotate.left")
        XCTAssertNotNil(ToolBarButtonImageBuilder.rotateCWImage(), "rotate.right")
        XCTAssertNotNil(ToolBarButtonImageBuilder.flipHorizontally(), "flip.horizontal")
        XCTAssertNotNil(ToolBarButtonImageBuilder.clampImage(), "aspectratio")
        XCTAssertNotNil(ToolBarButtonImageBuilder.resetImage(), "arrow.2.circlepath")
        XCTAssertNotNil(ToolBarButtonImageBuilder.horizontallyFlipImage(), "flip.horizontal")
        XCTAssertNotNil(ToolBarButtonImageBuilder.autoAdjustImage(), "camera.metering.none")

        // Hand-drawn icons with no SF Symbol equivalent (kept after cleanup).
        XCTAssertNotNil(ToolBarButtonImageBuilder.flipVertically(), "drawFlipVertically")
        XCTAssertNotNil(ToolBarButtonImageBuilder.alterCropper90DegreeImage(), "drawAlterCropper90DegreeImage")

        // Derived from horizontallyFlipImage() at runtime.
        XCTAssertNotNil(ToolBarButtonImageBuilder.verticallyFlipImage(), "verticallyFlipImage")
    }
}
