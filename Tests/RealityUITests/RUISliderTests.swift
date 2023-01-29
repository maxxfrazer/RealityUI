//
//  RUISliderTests.swift
//  
//
//  Created by Max Cobb on 29/01/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

final class RUISliderTests: XCTestCase {

    override func setUpWithError() throws {
        let slider = RUISlider()
        XCTAssertNotNil(slider)
        XCTAssertEqual(slider.slider.length, 10)
        XCTAssertEqual(slider.slider.value, 0)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitWithLengthStepsAndStart() {
        let slider = RUISlider(length: 20, start: 0.5, steps: 2)
        XCTAssertEqual(slider.slider.length, 20)
        XCTAssertEqual(slider.slider.value, 0.5)
        XCTAssertEqual(slider.slider.steps, 2)
    }

    func testARTouchMovedHalfway() {
        let slider = RUISlider()
        let worldCoordinate = SIMD3<Float>.zero
        var value = slider.value
        slider.arTouchStarted(worldCoordinate)
        XCTAssertEqual(value, slider.value)
        slider.arTouchUpdated([-5, 0, 0])
        XCTAssertEqual(slider.value, 0.5, accuracy: 0.0001)
        slider.arTouchUpdated([-5, 0, 0])
        XCTAssertEqual(slider.value, 0.5, accuracy: 0.0001)
        slider.arTouchEnded()
        XCTAssertEqual(slider.value, 0.5, accuracy: 0.0001)
    }

    func testARTouchCancelled() {
        let slider = RUISlider()
        let worldCoordinate = SIMD3<Float>.zero
        var value = slider.value
        slider.arTouchStarted(worldCoordinate)
        XCTAssertEqual(value, slider.value)
        slider.arTouchCancelled()
        XCTAssertEqual(value, slider.value)
    }

    func testAnimateSliderThumbPos() {
        let arView = ARView(frame: CoreFoundation.CGRect(origin: .zero, size: CGSize(width: 256, height: 256)))
        let anchor = AnchorEntity(world: .zero)
        let slider = RUISlider(length: 10, start: 0.5)
        anchor.addChild(slider)
        arView.scene.addAnchor(anchor)
        XCTAssertEqual(slider.value, 0.5)
        slider.setPercent(to: 0.9, animated: true)
        var expectation = self.expectation(description: "wait for it")
        expectation.isInverted = true
        waitForExpectations(timeout: 0.3, handler: nil)
        var xpos = slider.getModel(part: "thumb")!.position.x
        XCTAssertEqual(xpos, -4, accuracy: 0.0005)

        slider.setPercent(to: 0.2, animated: true)
        expectation = self.expectation(description: "wait for it")
        expectation.isInverted = true
        waitForExpectations(timeout: 0.3, handler: nil)
        xpos = slider.getModel(part: "thumb")!.position.x
        XCTAssertEqual(xpos, 3, accuracy: 0.0005)
    }

}
