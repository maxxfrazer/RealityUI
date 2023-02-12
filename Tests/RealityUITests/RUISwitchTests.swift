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

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSwitchChangedCallback() {
        let testSwitch = RUISwitch()
        var switchChangedCalled = false
        testSwitch.switchChanged = { newVal in
            // newval should be true
            switchChangedCalled = newVal.isOn
        }
        testSwitch.setOn(true)
        XCTAssertTrue(switchChangedCalled)
    }

    func testSwitchRespondsToLighting() {
        let testSwitch = RUISwitch()
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
        let testSwitch = RUISwitch()

        testSwitch.arTouchStarted(SIMD3<Float>(0.3, 0, 0), hasCollided: true)
        testSwitch.arTouchEnded(nil, true)
        XCTAssertTrue(testSwitch.isOn)
        testSwitch.arTouchStarted(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        testSwitch.arTouchEnded(nil, true)
        XCTAssertFalse(testSwitch.isOn)
        testSwitch.arTouchStarted(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        testSwitch.arTouchEnded(nil, false)
        XCTAssertFalse(testSwitch.isOn)
        testSwitch.arTouchStarted(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        testSwitch.arTouchEnded(nil, true)
        XCTAssertTrue(testSwitch.isOn)
    }

    func testDragThumbAcross() {
        let testSwitch = RUISwitch()
        guard let thumbModel = testSwitch.getModel(part: "thumb") else {
            XCTFail("Could not get thumb model")
            return
        }
        testSwitch.arTouchStarted(SIMD3<Float>(0.3, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        testSwitch.arTouchUpdated(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x < 0)
        testSwitch.arTouchEnded(nil, true)
        XCTAssertTrue(testSwitch.isOn)
    }

    func testDragThumbAcrossAndBack() {
        let testSwitch = RUISwitch()
        guard let thumbModel = testSwitch.getModel(part: "thumb") else {
            return XCTFail("Could not get thumb model")
        }
        testSwitch.arTouchStarted(SIMD3<Float>(0.3, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        testSwitch.arTouchUpdated(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x < 0)
        testSwitch.arTouchUpdated(SIMD3<Float>(0.1, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        testSwitch.arTouchEnded(nil, true)
        XCTAssertFalse(testSwitch.isOn)
    }

    func testTouchBackgroundMoveOffBackOn() {
        let testSwitch = RUISwitch()
        guard let thumbModel = testSwitch.getModel(part: "thumb") else {
            return XCTFail("Could not get thumb model")
        }
        testSwitch.arTouchStarted(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        testSwitch.arTouchUpdated(SIMD3<Float>(-1.6, 0, 0), hasCollided: false)
        XCTAssertTrue(thumbModel.position.x > 0)
        XCTAssertFalse(testSwitch.thumbCompressed)
        testSwitch.arTouchUpdated(SIMD3<Float>(0.3, 0, 0), hasCollided: true)
        XCTAssertTrue(thumbModel.position.x > 0)
        XCTAssertTrue(testSwitch.thumbCompressed)
        testSwitch.arTouchEnded(nil, true)
        XCTAssertTrue(testSwitch.isOn)
    }

}
