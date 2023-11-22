//
//  RUIDragSliderTests.swift
//
//
//  Created by Max Cobb on 29/01/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

#if os(iOS) || os(macOS)
final class RUIDragSliderTests: XCTestCase {

    var gestureRecognizer: RUIDragGestureRecognizer!
    var arView: ARView!
    var entity: RUISlider!

    override func setUpWithError() throws {
        arView = ARView(frame: .init(origin: .zero, size: CGSize(width: 256, height: 256)))
        gestureRecognizer = RUIDragGestureRecognizer(target: nil, action: nil, view: arView)
        RealityUI.enableGestures(.ruiDrag, on: arView)
        entity = RUISlider(length: 10, start: 0.5)
        let anchor = AnchorEntity()
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 0, -10], relativeTo: nil)
        anchor.addChild(cam)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        arView.removeFromSuperview()
        arView.scene.anchors.forEach { $0.removeFromParent() }
        #if os(iOS)
        arView.gestureRecognizers?.removeAll()
        arView.session.pause()
        #elseif os(macOS)
        arView.gestureRecognizers.removeAll()
        #endif
        arView = nil
    }

    #if os(iOS)
    func testSlideUpDownMiddle() {
        let mytouch = TestTouch(location: CGPoint(x: 128, y: 128))
        gestureRecognizer.touchesBegan([mytouch], with: UIEvent())
        XCTAssertEqual(gestureRecognizer.entity, entity.getModel(part: "thumb"))
        mytouch.updateLocation(to: CGPoint(x: 255, y: 128))
        gestureRecognizer.touchesMoved([mytouch], with: UIEvent())
        gestureRecognizer.dragUpdatedSceneEvent(nil)
        XCTAssertEqual(entity.value, 1, accuracy: 0.05)
        mytouch.updateLocation(to: CGPoint(x: 1, y: 200))
        gestureRecognizer.touchesMoved([mytouch], with: UIEvent())
        gestureRecognizer.dragUpdatedSceneEvent(nil)
        XCTAssertEqual(entity.value, 0, accuracy: 0.05)
        mytouch.updateLocation(to: CGPoint(x: 128, y: 50))
        gestureRecognizer.touchesMoved([mytouch], with: UIEvent())
        gestureRecognizer.dragUpdatedSceneEvent(nil)
        XCTAssertEqual(entity.value, 0.5)
    }

    func testDoubleTouchesBegan() {
        let mytouch = TestTouch(location: CGPoint(x: 128, y: 128))
        gestureRecognizer.touchesBegan([mytouch], with: UIEvent())
        gestureRecognizer.touchesBegan([mytouch], with: UIEvent())
        XCTAssertNil(gestureRecognizer.activeTouch)
    }

    func testTwoFingersTouching() {
        let mytouches: Set<UITouch> = [
            TestTouch(location: CGPoint(x: 128, y: 128)),
            TestTouch(location: CGPoint(x: 200, y: 128))
        ]
        gestureRecognizer.touchesBegan(mytouches, with: UIEvent())
        XCTAssertNil(gestureRecognizer.activeTouch)
    }
    #endif
}
#endif
