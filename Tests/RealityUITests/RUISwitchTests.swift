//
//  RUISwitchTests.swift
//  
//
//  Created by Max Cobb on 29/01/2023.
//

import XCTest
@testable import RealityUI
import RealityKit

final class RUISwitchTests: XCTestCase {

    var testSwitch: RUISwitch!

    override func setUpWithError() throws {
        testSwitch = RUISwitch()
    }

    override func tearDownWithError() throws {}

    func testSwitchChangedCallback() {
        var switchChangedCalled = false
        testSwitch.switchCallback = { newVal in
            // newval should be true
            switchChangedCalled = newVal.isOn
        }
        testSwitch.setOn(true)
        XCTAssertTrue(switchChangedCalled)
    }

    func testSwitchRespondsToLighting() {
        let unlitMat: Material! = testSwitch.getModel(part: "thumb")?.model?.materials.first
        XCTAssertTrue(unlitMat is UnlitMaterial)
        testSwitch.respondsToLighting = true
        let lightingMat: Material! = testSwitch.getModel(part: "thumb")?.model?.materials.first
        XCTAssertTrue(lightingMat is SimpleMaterial)
    }

    #if os(iOS)
    func testSwitchOnOffColors() {
        let testSwitch = RUISwitch(switchness: SwitchComponent(onColor: .white, offColor: .black))
        let arView = ARView(frame: CoreFoundation.CGRect(origin: .zero, size: CGSize(width: 256, height: 256)))
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(testSwitch)
        arView.scene.addAnchor(anchor)
        XCTAssertEqual(testSwitch.switchness.onColor, Material.Color.white)
        XCTAssertEqual(testSwitch.switchness.offColor, Material.Color.black)
        XCTAssertFalse(testSwitch.isOn)
        XCTAssertGreaterThan(testSwitch.getModel(part: "thumb")!.position.x, 0)
        XCTAssertTrue(testSwitch.getModel(part: "thumb")!.position.x > 0)

        guard let bgMat = testSwitch.getModel(part: "background")?.model!.materials[0] as? UnlitMaterial else {
            return XCTFail("Cannot get background material")
        }
        testSwitch.setOn(true)
        XCTAssertTrue(testSwitch.isOn)
        var expectation = self.expectation(description: "touchUpCompleted callback was not called")
        expectation.isInverted = true
        waitForExpectations(timeout: 0.3, handler: nil)
        XCTAssertLessThan(testSwitch.getModel(part: "thumb")!.position.x, 0)
        guard let onMat = testSwitch.getModel(part: "background")?.model!.materials[0] as? UnlitMaterial else {
            return XCTFail("Cannot get background material")
        }
        if #available(macOS 12.0, iOS 15.0, *) {
            XCTAssertNotEqual(bgMat.color.tint, onMat.color.tint)
        }
        testSwitch.setOn(false)
        expectation = self.expectation(description: "wait for anim")
        expectation.isInverted = true

        waitForExpectations(timeout: 0.3, handler: nil)
        XCTAssertGreaterThan(testSwitch.getModel(part: "thumb")!.position.x, 0)
        XCTAssertFalse(testSwitch.isOn)
            guard let offMat = testSwitch.getModel(part: "background")?.model!.materials[0] as? UnlitMaterial else {
                return XCTFail("Cannot get background material")
            }
        if #available(iOS 15.0, macOS 12.0, *) {
            XCTAssertEqual(bgMat.color.tint, offMat.color.tint)
        }
    }
    #endif

    func testTappingSwitch() {
        guard let thumbModel = testSwitch.getModel(part: "thumb"),
              let switchComponent = thumbModel.components.get(RUIDragComponent.self)
        else { return }
        XCTAssertFalse(testSwitch.isOn) // start off
        switchComponent.dragStarted(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]))
        switchComponent.dragUpdated(thumbModel, ray: ([0.1, 0, 1], [0, 0, -1]), hasCollided: true)
        switchComponent.dragUpdated(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]), hasCollided: true)
        switchComponent.dragEnded(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]))
        XCTAssertFalse(testSwitch.isOn) // no change in value
        switchComponent.dragStarted(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]))
        switchComponent.dragUpdated(thumbModel, ray: ([-0.3, 0, 1], [0, 0, -1]), hasCollided: true)
        switchComponent.dragUpdated(thumbModel, ray: ([-0.2, 0, 1], [0, 0, -1]), hasCollided: true)
        switchComponent.dragEnded(thumbModel, ray: ([-0.2, 0, 1], [0, 0, -1]))
        XCTAssertTrue(testSwitch.isOn) // changed
    }

    func testDragThumbAcross() {
        guard let thumbModel = testSwitch.getModel(part: "thumb"),
              let switchComponent = thumbModel.components.get(RUIDragComponent.self)
        else { return XCTFail("Could not get thumb model") }
        switchComponent.dragStarted(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]))
        XCTAssertTrue(thumbModel.position.x > 0)
        switchComponent.dragUpdated(thumbModel, ray: ([-0.3, 0, 1], [0, 0, -1]), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x < 0)
        switchComponent.dragEnded(thumbModel, ray: ([-0.3, 0, 1], [0, 0, -1]))
        XCTAssertTrue(testSwitch.isOn)
    }

    func testDragThumbAcrossAndBack() {
        guard let thumbModel = testSwitch.getModel(part: "thumb"),
              let switchComponent = thumbModel.components.get(RUIDragComponent.self)
        else { return XCTFail("Could not get thumb model") }
        switchComponent.dragStarted(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]))
        XCTAssertTrue(thumbModel.position.x > 0)
        switchComponent.dragUpdated(thumbModel, ray: ([-0.3, 0, 1], [0, 0, -1]), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x < 0)
        switchComponent.dragUpdated(thumbModel, ray: ([0.1, 0, 1], [0, 0, -1]), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        switchComponent.dragEnded(thumbModel, ray: ([0.1, 0, 1], [0, 0, -1]))
        XCTAssertFalse(testSwitch.isOn)
    }

    func testTouchBackgroundMoveOffBackOn() {
        guard let thumbModel = testSwitch.getModel(part: "thumb"),
              let switchComponent = thumbModel.components.get(RUIDragComponent.self)
        else { return XCTFail("Could not get thumb model") }

        switchComponent.dragStarted(thumbModel, ray: ([0.3, 0, 1], [0, 0, -1]))
        XCTAssertTrue(thumbModel.position.x > 0)
        switchComponent.dragUpdated(thumbModel, ray: ([1.6, 0, 1], [0, 0, -1]), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        switchComponent.dragUpdated(thumbModel, ray: ([-0.3, 0, 1], [0, 0, -1]), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x < 0)
        switchComponent.dragEnded(thumbModel, ray: ([-0.3, 0, 1], [0, 0, -1]))
        XCTAssertTrue(testSwitch.isOn)
    }
}
