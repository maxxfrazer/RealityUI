//
//  RUIGeometryTests.swift
//
//
//  Created by Max Cobb on 18/12/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

final class RUIGeometryTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFindPointOnPlane_Intersecting() {
        let ray = (origin: SIMD3<Float>(0, 0, 0), direction: SIMD3<Float>(0, 0, 1))
        let plane = float4x4([1, 0, 0, 0],
                             [0, 1, 0, 0],
                             [0, 0, 1, 0],
                             [0, 0, 5, 1])
        let intersectionPoint = RUIDragComponent.findPointOnPlane(ray: ray, plane: plane)
        XCTAssertEqual(intersectionPoint, SIMD3<Float>(0, 0, 5))
    }

    func testFindPointOnPlane_Parallel() {
        let ray = (origin: SIMD3<Float>(0, 0, 0), direction: SIMD3<Float>(1, 0, 0))
        let plane = float4x4([1, 0, 0, 0],
                             [0, 1, 0, 0],
                             [0, 0, 1, 0],
                             [0, 0, 5, 1])
        let intersectionPoint = RUIDragComponent.findPointOnPlane(ray: ray, plane: plane)
        XCTAssertNil(intersectionPoint)
    }

    func testFindPointOnPlane_Normalization() {
        let ray = (origin: SIMD3<Float>(0, 0, 0), direction: SIMD3<Float>(0, 0, 3))
        let plane = float4x4([1, 0, 0, 0],
                             [0, 1, 0, 0],
                             [0, 0, 1, 0],
                             [0, 0, 5, 1])
        let intersectionPoint = RUIDragComponent.findPointOnPlane(ray: ray, plane: plane)
        XCTAssertEqual(intersectionPoint, SIMD3<Float>(0, 0, 5))
    }

    func testHandleMoveState_ValidTouch() {
        let entity = Entity()
        entity.components.set(RUIDragComponent(type: .move(nil)))
        let result = RUIDragComponent.handleMoveState(entity, .one, .zero)
        XCTAssertEqual(result, .one)
        let result2 = RUIDragComponent.handleMoveState(entity, .one, [0, 1, 0])
        XCTAssertEqual(result2, [1, 0, 1])
    }

    func testHandleMoveState_NoTouch() {
        let entity = Entity() // Assuming Entity is an existing type
        let result = RUIDragComponent.handleMoveState(entity, nil, .zero)
        XCTAssertNil(result)
    }

    func testHandleMoveState_NoComponent() {
        let entity = Entity() // Assuming Entity is an existing type
        let result = RUIDragComponent.handleMoveState(entity, .one, .zero)
        XCTAssertNil(result)
    }

    func testHandleMoveState_MoveConstraints() {
        let entity = Entity() // Assuming Entity is an existing type
        let newTouchPos = SIMD3<Float>(1, 1, 1)
        let poi = SIMD3<Float>(0, 0, 0)

        // Test with box constraint
        let bbox = BoundingBox(min: [-1, 0, 0], max: [1, 0, 0])
        entity.components.set(RUIDragComponent(type: .move(.box(bbox)))) // Assuming bbox is defined
        var result = RUIDragComponent.handleMoveState(entity, .one, .zero)
        XCTAssertEqual(result, [1, 0, 0])

        // Test with points constraint
        let points: [SIMD3<Float>] = [[0, 1, 0], .zero, [0, -1, 0]]
        entity.components.set(RUIDragComponent(type: .move(.points(points)))) // Assuming points is defined
        result = RUIDragComponent.handleMoveState(entity, .one, .zero)
        XCTAssertEqual(result, [0, 1, 0])

        // Test with clamp function
        let clampFoo: (SIMD3<Float>) -> SIMD3<Float> = { input in
            [input.x, 0, input.z]
        }
        entity.components.set(RUIDragComponent(type: .move(.clamp(clampFoo)))) // Assuming clampFoo is defined
        result = RUIDragComponent.handleMoveState(entity, .one, .zero)
        XCTAssertEqual(result, [1, 0, 1])

        // Test with no constraint
        entity.components.set(RUIDragComponent(type: .move(nil)))
        result = RUIDragComponent.handleMoveState(entity, newTouchPos, poi)
        XCTAssertEqual(result, newTouchPos - poi + entity.position)
    }

    func testGetCollisionPoints_MoveZeroDistance() {
        let collisionPoint = RUIDragComponent.getCollisionPoints(
            with: (origin: .zero, direction: .one), dragState: .move(poi: .zero, distance: .zero)
        )
        XCTAssertNotNil(collisionPoint)
        XCTAssertEqual(collisionPoint, .one)
    }

    func testRotateVector() {
        let turnComp = RUIDragComponent(type: .turn(axis: normalize([0, 2, 0])))
        XCTAssertNotNil(turnComp.rotateVector)
        XCTAssertEqual(turnComp.rotateVector!.x, 0, accuracy: 0.01)
        XCTAssertEqual(turnComp.rotateVector!.y, 1, accuracy: 0.01)
        XCTAssertEqual(turnComp.rotateVector!.z, 0, accuracy: 0.01)
    }

    func testRotateVector_Nil() {
        let turnComp = RUIDragComponent(type: .click)
        XCTAssertNil(turnComp.rotateVector)
    }

    func testMoveConstraint_Points() {
        let turnComp = RUIDragComponent(type: .move(.points([.zero])))
        switch turnComp.moveConstraint {
        case .points(let points):
            XCTAssertEqual(points.count, 1)
            XCTAssertEqual(points[0], .zero)
        default: XCTFail("incorrect constraing returned: \(turnComp.moveConstraint.debugDescription)")
        }
    }

    func testMoveConstraint_Nil() {
        let turnComp = RUIDragComponent(type: .move(nil))
        XCTAssertNil(turnComp.moveConstraint)
    }

    func testMoveConstraint_ClickSoNil() {
        let turnComp = RUIDragComponent(type: .click)
        XCTAssertNil(turnComp.moveConstraint)
    }

    func testGetCollisionPoints_Nil() {
        let collisionPointsNil = RUIDragComponent.getCollisionPoints(
            with: (origin: .zero, direction: .one), dragState: .none
        )
        XCTAssertNil(collisionPointsNil)
    }

}
