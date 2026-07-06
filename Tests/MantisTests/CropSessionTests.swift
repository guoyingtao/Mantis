//
//  CropSessionTests.swift
//  MantisTests
//
//  Created for Mantis 3.0.
//

import XCTest
import Combine
#if canImport(Observation)
import Observation
#endif
@testable import Mantis

final class CropSessionTests: XCTestCase {

    var session: CropSession!
    var cancellables: Set<AnyCancellable> = []

    override func setUpWithError() throws {
        session = CropSession()
        cancellables = []
    }

    func testInitialState() {
        XCTAssertFalse(session.canUndo)
        XCTAssertFalse(session.canRedo)
        XCTAssertFalse(session.isResettable)
        XCTAssertNil(session.transformation)
        XCTAssertNil(session.cropViewController)
    }

    func testStateMutationIsObservable() {
        var changeCount = 0
        session.objectWillChange
            .sink { changeCount += 1 }
            .store(in: &cancellables)

        session.canUndo = true
        session.canRedo = true
        session.isResettable = true

        XCTAssertTrue(session.canUndo)
        XCTAssertTrue(session.canRedo)
        XCTAssertTrue(session.isResettable)
        XCTAssertEqual(changeCount, 3)

        // Setting the same value again must not publish a change.
        session.canUndo = true
        XCTAssertEqual(changeCount, 3)
    }

    func testTransformationUpdateIsObservable() {
        var changeCount = 0
        session.objectWillChange
            .sink { changeCount += 1 }
            .store(in: &cancellables)

        let transformation = Transformation(offset: CGPoint(x: 1, y: 2),
                                            rotation: 0.5,
                                            scale: 2,
                                            isManuallyZoomed: true,
                                            initialMaskFrame: .zero,
                                            maskFrame: .zero,
                                            cropWorkbenchViewBounds: .zero,
                                            horizontallyFlipped: false,
                                            verticallyFlipped: false)
        session.transformation = transformation

        XCTAssertEqual(session.transformation, transformation)
        XCTAssertEqual(changeCount, 1)

        session.transformation = transformation
        XCTAssertEqual(changeCount, 1)
    }

    func testObservationTrackingFiresOniOS17() throws {
#if canImport(Observation)
        guard #available(iOS 17.0, macCatalyst 17.0, *) else {
            throw XCTSkip("Observation requires iOS 17")
        }

        var changeFired = false
        withObservationTracking {
            _ = session.canUndo
        } onChange: {
            changeFired = true
        }

        session.canRedo = true
        XCTAssertFalse(changeFired, "Tracking must be per-property, not object-wide")

        session.canUndo = true
        XCTAssertTrue(changeFired)
#else
        throw XCTSkip("Observation framework not available")
#endif
    }

    func testActionsWithoutAttachedCropperAreNoOps() {
        // None of these may crash when the session is not attached.
        session.rotate()
        session.rotate(.counterClockwise)
        session.flip()
        session.flip(.vertical)
        session.crop()
        session.undo()
        session.redo()
        session.reset()
        session.setAspectRatio(.fixed(16 / 9))
        session.setAspectRatio(.free)
    }

    func testAttachResetsState() {
        session.canUndo = true
        session.canRedo = true
        session.isResettable = true

        let cropViewController = CropViewController()
        session.attach(to: cropViewController)

        XCTAssertTrue(session.cropViewController === cropViewController)
        XCTAssertFalse(session.canUndo)
        XCTAssertFalse(session.canRedo)
        XCTAssertFalse(session.isResettable)
    }
}

final class ImageCropperModifierTests: XCTestCase {

    private let image = UIImage()

    func testCropShapeModifier() {
        let cropper = ImageCropper(image: image).cropShape(.circle)

        XCTAssertEqual(cropper.config.cropViewConfig.cropShapeType, .circle())
        // Circle implies a locked 1:1 ratio, mirroring CropViewController's behavior.
        guard case .alwaysUsingOnePresetFixedRatio(let ratio) = cropper.config.presetFixedRatioType else {
            return XCTFail("Expected a fixed 1:1 ratio for circle shape")
        }
        XCTAssertEqual(ratio, 1)
    }

    func testAspectRatioModifier() {
        let fixed = ImageCropper(image: image).aspectRatio(.fixed(16 / 9))
        guard case .alwaysUsingOnePresetFixedRatio(let ratio) = fixed.config.presetFixedRatioType else {
            return XCTFail("Expected a fixed ratio")
        }
        XCTAssertEqual(ratio, 16.0 / 9.0, accuracy: 1e-9)

        let free = fixed.aspectRatio(.free)
        guard case .canUseMultiplePresetFixedRatio = free.config.presetFixedRatioType else {
            return XCTFail("Expected a free ratio")
        }
    }

    func testToolbarAndAppearanceAndConfigureModifiers() {
        let cropper = ImageCropper(image: image)
            .builtInToolbarVisible(false)
            .appearance(.system)
            .configure { $0.enableUndoRedo = true }

        XCTAssertFalse(cropper.config.showAttachedCropToolbar)
        XCTAssertEqual(cropper.config.appearanceMode, .system)
        XCTAssertTrue(cropper.config.enableUndoRedo)
    }
}
