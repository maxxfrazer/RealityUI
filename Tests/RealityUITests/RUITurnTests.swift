//
//  RUITurnTests.swift
//  
//
//  Created by Max Cobb on 22/11/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

final class RUITurnTests: XCTestCase {

    var turnEntity: Entity!

    override func setUpWithError() throws {
        self.turnEntity = Entity()
        self.turnEntity.components.set(RUIDragComponent(type: .turn(axis: [0, 0, 1])))
    }

    override func tearDownWithError() throws {}

    func testTurn90DegreesAndBack() throws {
        guard let dragComp = self.turnEntity.components.get(RUIDragComponent.self) else {
            return XCTFail("Failed to get drag component")
        }
        let forward: SIMD3<Float> = [0, 0, -1]

        dragComp.dragStarted(self.turnEntity, ray: ([-1, 0, 1], forward))
        dragComp.dragUpdated(self.turnEntity, ray: ([0, 1, 1], forward), hasCollided: true)
        XCTAssertEqual(self.turnEntity.orientation.angle, .pi / 2, accuracy: 1e-5)

        dragComp.dragUpdated(self.turnEntity, ray: ([-1, 1, 1], forward), hasCollided: true)
        XCTAssertEqual(self.turnEntity.orientation.angle, .pi / 4, accuracy: 1e-5)

        dragComp.dragUpdated(self.turnEntity, ray: ([-1, 0, 1], forward), hasCollided: true)
        XCTAssertEqual(self.turnEntity.orientation.angle, 0, accuracy: 1e-5)

        dragComp.dragEnded(self.turnEntity, ray: ([-1, 0, 1], forward))
    }
}
