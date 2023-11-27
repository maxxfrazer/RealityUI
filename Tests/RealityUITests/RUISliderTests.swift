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

    var slider: RUISlider!

    override func setUpWithError() throws {
        self.slider = RUISlider()
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

    func testARTouchMovedUpAndDown() {
        let slider = RUISlider(length: 5)
        let startValue = slider.value
        guard let sliderThumb = slider.getModel(part: "thumb"),
              let dragComp = sliderThumb.components.get(RUIDragComponent.self)
        else { fatalError() }
        let rayForward: SIMD3<Float> = [0, 0, 1]
        dragComp.dragStarted(sliderThumb, ray: ([2.5, 0, -1], [0, 0, 1]))
        XCTAssertEqual(startValue, slider.value)

        dragComp.dragUpdated(sliderThumb, ray: (
            origin: [-2.5, 0, -1], direction: rayForward
        ), hasCollided: true)
        XCTAssertEqual(slider.value, 1, accuracy: 0.0001)

        dragComp.dragUpdated(sliderThumb, ray: (
            origin: [2.5, 0, -1], direction: rayForward
        ), hasCollided: true)
        XCTAssertEqual(slider.value, 0, accuracy: 0.0001)

        dragComp.dragUpdated(sliderThumb, ray: (
            origin: [0, 0, -1], direction: rayForward
        ), hasCollided: true)
        dragComp.dragEnded(sliderThumb, ray: (
            origin: [0, 0, -1], direction: rayForward
        ))
        XCTAssertEqual(slider.value, 0.5, accuracy: 0.0001)
    }

    func testSliderStateUpdates() {
        var sliderState: SliderComponent.SlidingState?
        slider.sliderUpdateCallback = { _, sliState in
            sliderState = sliState
        }
        slider.setPercent(to: 0.5)
        guard let sliderThumb = slider.getModel(part: "thumb"),
              let dragComp = sliderThumb.components.get(RUIDragComponent.self)
        else { fatalError() }
        dragComp.dragStarted(sliderThumb, ray: ([0, 1, -1], [0, -1, 1]))
        XCTAssertEqual(sliderState, .started)
        dragComp.dragUpdated(sliderThumb, ray: (origin: [0, 1, -1], direction: [1, 0, 0]), hasCollided: true)
        // default is to continually get updates, so should still be .updated
        XCTAssertEqual(sliderState, .updated)
        dragComp.dragEnded(sliderThumb, ray: (origin: [0, 1, -1], direction: [1, 0, 0]))
        XCTAssertEqual(sliderState, .ended)
    }

    func testSliderStateNonContinuousUpdates() {
        self.slider.isContinuous = false
        var sliderState: SliderComponent.SlidingState?
        slider.sliderUpdateCallback = { _, sliState in
            sliderState = sliState
        }
        guard let sliderThumb = slider.getModel(part: "thumb"),
              let dragComp = sliderThumb.components.get(RUIDragComponent.self)
        else { fatalError() }
        dragComp.dragStarted(sliderThumb, ray: ([0, 1, -1], [0, -1, 1]))
        XCTAssertEqual(sliderState, .started)
        dragComp.dragUpdated(sliderThumb, ray: (origin: [0, 1, -1], direction: [1, 0, 0]), hasCollided: true)
        // not continually getting updates, so should still be .started
        XCTAssertEqual(sliderState, .started)
        dragComp.dragEnded(sliderThumb, ray: (origin: [0, 1, -1], direction: [1, 0, 0]))
        XCTAssertEqual(sliderState, .ended)
    }

    func testSliderUpdateValue() {
        self.slider.setPercent(to: 1)
        XCTAssertEqual(self.slider.value, 1)
        XCTAssertEqual(self.slider.getModel(part: "thumb")?.position.x, -self.slider.sliderLength / 2)
    }

    func testSliderSteps() {
        let slider = RUISlider(slider: SliderComponent(startingValue: 0, steps: 1))

        guard let sliderThumb = slider.getModel(part: "thumb"),
              let dragComp = sliderThumb.components.get(RUIDragComponent.self)
        else { fatalError() }
        XCTAssertEqual(slider.value, 0)
        XCTAssertEqual(sliderThumb.position.x, 5)
        dragComp.dragStarted(sliderThumb, ray: ([5, 0, -1], [0, 0, 1]))
        dragComp.dragUpdated(sliderThumb, ray: (origin: [0.2, 0, -1], direction: [0, 0, 1]), hasCollided: true)
        XCTAssertEqual(slider.value, 0)
        // not continually getting updates, so should still be .started
        dragComp.dragUpdated(sliderThumb, ray: (origin: [-0.4, 0, -1], direction: [0, 0, 1]), hasCollided: true)
        dragComp.dragEnded(sliderThumb, ray: (origin: [-0.4, 0, -1], direction: [0, 0, 1]))

        XCTAssertEqual(slider.value, 1)
    }

    func testARTouchCancelled() {
        let startValue = slider.value
        slider.components.get(RUIDragComponent.self)?.dragStarted(slider, ray: ([0, 0, -1], [0, 0, 1]))
        XCTAssertEqual(startValue, slider.value)
        slider.components.get(RUIDragComponent.self)?.dragCancelled(slider)
        XCTAssertEqual(startValue, slider.value)
    }
    #if os(iOS)
    func testAnimateSliderThumbPos() {
        let arView = ARView(frame: CGRect(origin: .zero, size: CGSize(width: 256, height: 256)))
        let anchor = AnchorEntity(world: .zero)
        let slider = RUISlider(length: 10, start: 0.5)
        anchor.addChild(slider)
        arView.scene.addAnchor(anchor)
        XCTAssertEqual(slider.value, 0.5)
        slider.setPercent(to: 0.9, animated: true)
        var expectation = self.expectation(description: "wait for it")
        expectation.isInverted = true
        waitForExpectations(timeout: 0.5, handler: nil)
        var xpos = slider.getModel(part: "thumb")!.position.x
        XCTAssertEqual(xpos, -4, accuracy: 0.0005)

        slider.setPercent(to: 0.2, animated: true)
        expectation = self.expectation(description: "wait for it")
        expectation.isInverted = true
        waitForExpectations(timeout: 0.3, handler: nil)
        xpos = slider.getModel(part: "thumb")!.position.x
        XCTAssertEqual(xpos, 3, accuracy: 0.0005)
    }
    #endif
}
