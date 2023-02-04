//
//  RUIAnimationTests.swift
//  
//
//  Created by Max Cobb on 30/01/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

#if os(iOS)
final class RUIAnimationTests: XCTestCase {

    var gestureRecognizer: RUILongTouchGestureRecognizer!
    var arView: ARView!
    var entity: Entity!

    override func setUpWithError() throws {
        let viewC = UIViewController()
        arView = ARView(frame: .init(origin: .zero, size: CGSize(width: 256, height: 256)))
        viewC.view.addSubview(arView)
        entity = Entity()
        let anchor = AnchorEntity()
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 1, 1], relativeTo: nil)
        anchor.addChild(cam)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRuiSpin() {
        let expectation = XCTestExpectation(description: "Spin animation completed")

        print(entity.orientation.angle)
        entity.ruiSpin(by: [0, 1, 0], period: 0.3, times: 1) {
            expectation.fulfill()
        }
        print(entity.orientation.angle)

        wait(for: [expectation], timeout: 0.4)
        print(entity.orientation.angle)
        XCTAssertEqual(RealityUI.anims.count, 0)
    }

    func testRuiShake() {
        let expectation = XCTestExpectation(description: "Spin animation completed")

        print(entity.orientation.angle)
        entity.ruiShake(by: simd_quatf(angle: .pi / 2, axis: [0, 0, 1]), period: 0.25, times: 1) {
            expectation.fulfill()
        }
        // just over 2x the period, as the first and last half period are always added.
        wait(for: [expectation], timeout: 0.55)
        print(entity.orientation.angle)
        // calling stop when there are no animations running
        entity.ruiStopAnim()
        entity.orientation = .init(angle: .zero, axis: [0, 1, 0])
        XCTAssertEqual(RealityUI.anims.count, 0)
    }

    func testRuiStopAnims() {
        let expectation = XCTestExpectation(description: "Spin animation completed")
        expectation.isInverted = true
        print(entity.orientation.angle)
        entity.ruiSpin(by: [0, 1, 0], period: 0.3, times: 1) {
            expectation.fulfill()
        }
        print(entity.orientation.angle)
        XCTAssertEqual(RealityUI.anims.count, 1)

        wait(for: [expectation], timeout: 0.17)
        entity.ruiStopAnim()
        XCTAssertEqual(entity.orientation.angle, .pi, accuracy: 0.5)
        entity.orientation = .init(angle: .zero, axis: [0, 1, 0])
        XCTAssertEqual(RealityUI.anims.count, 0)
    }

}
#endif
