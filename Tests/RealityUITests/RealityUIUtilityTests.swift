//
//  RealityUIUtilityTests.swift
//  
//
//  Created by Max Cobb on 18/12/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

final class RealityUIUtilityTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSimdConversion() throws {
        let doubleSimd: SIMD3<Double> = .one
        let floatSimd: SIMD3<Float> = doubleSimd.toFloat3()

        XCTAssertEqual(Double(floatSimd.x), doubleSimd.x, "x value of doubleSimd and floatSimd should be equal")
        XCTAssertEqual(Double(floatSimd.x), 1, "x value of floatSimd should be one")
    }

    func testHasRUIObj() {
        class EntityHasRUI: Entity, HasRUI {}

        let newHasRUI = EntityHasRUI()
        let rui = newHasRUI.rui
        XCTAssertTrue(rui.ruiEnabled)
        XCTAssertFalse(rui.respondsToLighting)
        newHasRUI.ruiEnabled = false
        XCTAssertEqual(
            newHasRUI.components.get(RUIComponent.self)?.respondsToLighting,
            newHasRUI.rui.respondsToLighting
        )
        XCTAssertEqual(newHasRUI.respondsToLighting, newHasRUI.rui.respondsToLighting)
        XCTAssertEqual(newHasRUI.components.get(RUIComponent.self)?.ruiEnabled, newHasRUI.rui.ruiEnabled)
        XCTAssertFalse(newHasRUI.rui.ruiEnabled)
    }

    func testTapActions() {
        let arView = ARView(frame: .init(origin: .zero, size: CGSize(width: 200, height: 200)))
        let anch = AnchorEntity(world: .zero)
        arView.scene.addAnchor(anch)
        let ent = Entity()
        ent.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.5)]))
        anch.addChild(ent)

        let exception = XCTestExpectation(description: "tap action called")
        ent.components.set(RUITapComponent(action: { _, _ in exception.fulfill() }))
        RealityUI.shared.tapActionChecker(arView, CGPoint(x: 100, y: 100))
        wait(for: [exception])

        ent.components.set(RUIComponent(isEnabled: false))
        let nonException = XCTestExpectation(description: "tap action not called")
        nonException.isInverted = true
        ent.components.set(RUITapComponent(action: { _, _ in nonException.fulfill() }))
        RealityUI.shared.tapActionChecker(arView, CGPoint(x: 100, y: 100))
        wait(for: [nonException], timeout: 0.05)
    }
}
