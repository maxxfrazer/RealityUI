//
//  RUIDragButtonTests.swift
//  
//
//  Created by Max Cobb on 25/01/2023.
//

import XCTest
import RealityKit
#if canImport(UIKit)
import UIKit.UITouch
#endif
@testable import RealityUI

#if os(iOS) || os(macOS)
final class RUIDragButtonTests: XCTestCase {

    var gestureRecognizer: RUIDragGestureRecognizer!
    var arView: ARView!
    var entity: RUIButton!

    override func setUpWithError() throws {
        arView = ARView(frame: .init(origin: .zero, size: CGSize(width: 256, height: 256)))
        gestureRecognizer = RUIDragGestureRecognizer(target: nil, action: nil, view: arView)
        RealityUI.enableGestures(.ruiDrag, on: arView)
        entity = RUIButton()
        let anchor = AnchorEntity()
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 1, 1], relativeTo: nil)
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
    func testGlobalTouchBegan() {
        let mytouch = TestTouch(location: CGPoint(x: 128, y: 128))
        gestureRecognizer.touchesBegan([mytouch], with: UIEvent())
        XCTAssertEqual(gestureRecognizer.entity, entity)
        XCTAssertTrue(entity.isCompressed)
        gestureRecognizer.touchesEnded([mytouch], with: UIEvent())
        XCTAssertFalse(entity.isCompressed)
    }

    func testTouchMissed() {
        let mytouch = TestTouch(location: .zero)
        gestureRecognizer.touchesBegan([mytouch], with: UIEvent())
        XCTAssertNil(gestureRecognizer.entity)
        XCTAssertFalse(entity.isCompressed)
        gestureRecognizer.touchesEnded([mytouch], with: UIEvent())
    }

    func testTouchMovedOutAndBack() {
        let mytouch = TestTouch(location: CGPoint(x: 128, y: 128))
        gestureRecognizer.touchesBegan([mytouch], with: UIEvent())
        XCTAssertEqual(gestureRecognizer.entity, entity)
        XCTAssertTrue(entity.isCompressed)
        XCTAssertNotNil(gestureRecognizer.viewSubscriber, "Subscriber has not been created")

        mytouch.updateLocation(to: .zero)
        gestureRecognizer.touchesMoved([mytouch], with: UIEvent())
        gestureRecognizer.dragUpdatedSceneEvent(nil)
        XCTAssertFalse(entity.isCompressed)

        mytouch.updateLocation(to: CGPoint(x: 128, y: 128))
        gestureRecognizer.touchesMoved([mytouch], with: UIEvent())
        gestureRecognizer.dragUpdatedSceneEvent(nil)
        XCTAssertTrue(entity.isCompressed)

        gestureRecognizer.touchesEnded([mytouch], with: UIEvent())
    }
    #elseif os(macOS)
    func testGlobalTouchBegan() {
        var event: NSEvent! = NSEvent.mouseEvent(
            with: .leftMouseDown, location: CGPoint(x: 128, y: 128),
            modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
        gestureRecognizer.mouseDown(with: event)
        XCTAssertEqual(gestureRecognizer.entity, entity)
        XCTAssertTrue(entity.isCompressed)

        let expectation = self.expectation(description: "touchUpInside callback was called")
        entity.touchUpInside = { _ in
            expectation.fulfill()
        }

        event = NSEvent.mouseEvent(
            with: .leftMouseUp, location: CGPoint(x: 128, y: 128),
            modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
        gestureRecognizer.mouseUp(with: event)
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    #endif
}
#endif

#if os(iOS)
internal class TestTouch: UITouch {
    var currentLocation: CGPoint

    init(location: CGPoint) {
        self.currentLocation = location
    }

    override func location(in view: UIView?) -> CGPoint {
        return self.currentLocation
    }

    func updateLocation(to location: CGPoint) {
        self.currentLocation = location
    }
}
#endif
