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
        let expectation = self.expectation(description: "touchUpCompleted callback was not called")
        expectation.isInverted = true
        waitForExpectations(timeout: 0.3, handler: nil)
        XCTAssertLessThan(testSwitch.getModel(part: "thumb")!.position.x, 0)
        guard let onMat = testSwitch.getModel(part: "background")?.model!.materials[0] as? UnlitMaterial else {
            return XCTFail("Cannot get background material")
        }
        if #available(iOS 15.0, *) {
            XCTAssertNotEqual(bgMat.color.tint, onMat.color.tint)
        }
        testSwitch.setOn(false)
        XCTAssertGreaterThan(testSwitch.getModel(part: "thumb")!.position.x, 0)
        XCTAssertFalse(testSwitch.isOn)
            guard let offMat = testSwitch.getModel(part: "background")?.model!.materials[0] as? UnlitMaterial else {
                return XCTFail("Cannot get background material")
            }
        if #available(iOS 15.0, *) {
            XCTAssertEqual(bgMat.color.tint, offMat.color.tint)
        }
        print("break")
    }

}
