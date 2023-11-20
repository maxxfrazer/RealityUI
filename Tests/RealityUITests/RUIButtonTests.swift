//
//  RUIButtonTests.swift
//  
//
//  Created by Max Cobb on 25/01/2023.
//

import XCTest
@testable import RealityUI

final class RUIButtonTests: XCTestCase {

    var button: RUIButton!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        button = RUIButton()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDefaultInitialization() {
        XCTAssertNotNil(button)
    }

    func testTouchUpCompletedCallback() {
        let expectation = self.expectation(description: "touchUpInside callback was called")
        button.touchUpInside = { _ in
            expectation.fulfill()
        }
        button.components.get(RUIDragComponent.self)?.dragStarted(button, ray: ([0, 0, 1], [0, 0, -1]))
        button.components.get(RUIDragComponent.self)?.dragEnded(button, ray: ([0, 0, 1], [0, 0, -1]))
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTouchUpCompletedNotCalled() {
        let expectation = self.expectation(description: "touchUpInside callback was not called")
        expectation.isInverted = true
        button.touchUpInside = { _ in
            expectation.fulfill()
        }
        button.components.get(RUIDragComponent.self)?.dragEnded(button, ray: ([0, 0, 1], [0, 0, -1]))
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testTouchUpCompletedNotCalledTouchMoved() {
        let expectation = self.expectation(description: "touchUpInside callback was not called")
        expectation.isInverted = true
        button.touchUpInside = { _ in
            expectation.fulfill()
        }
        guard let dragComp = button.components.get(RUIDragComponent.self) else {
            return XCTFail("Could not find drag component")
        }
        dragComp.dragStarted(button, ray: ([0, 0, 1], [0, 0, -1]))
        dragComp.dragUpdated(button, ray: ([5, 5, 1], [0, 0, -1]), hasCollided: false)
        dragComp.dragEnded(button, ray: ([5, 5, 1], [0, 0, -1]))
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testCompressButton() {
        guard let dragComp = button.components.get(RUIDragComponent.self) else {
            return XCTFail("Could not find drag component")
        }
        dragComp.dragStarted(button, ray: ([0, 0, 1], [0, 0, -1]))
        XCTAssertTrue(button.button.isCompressed)
        dragComp.dragEnded(button, ray: ([0, 0, 1], [0, 0, -1]))
    }

    func testCancelReleaseButton() {
        let expectation = self.expectation(description: "touchUpInside callback was not called")
        expectation.isInverted = true
        button.touchUpInside = { _ in expectation.fulfill() }
        guard let dragComp = button.components.get(RUIDragComponent.self) else {
            return XCTFail("Could not find drag component")
        }
        dragComp.dragStarted(button, ray: ([0, 0, 1], [0, 0, -1]))
        dragComp.dragCancelled(button)
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testChangeColour() {
        button.baseColor = .black
        button.buttonColor = .orange
        XCTAssertEqual(button.baseColor, .black)
        XCTAssertEqual(button.buttonColor, .orange)
    }
}
