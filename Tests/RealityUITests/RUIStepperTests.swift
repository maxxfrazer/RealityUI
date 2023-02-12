//
//  RUIStepperTests.swift
//  
//
//  Created by Max Cobb on 29/01/2023.
//

import XCTest
@testable import RealityUI

final class RUIStepperTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStyleInitialization() {
        let stepper = RUIStepper(style: StepperComponent.Style.arrowLeftRight)
        XCTAssertEqual(stepper.stepper.style, StepperComponent.Style.arrowLeftRight)
    }

    func testUpDownTriggers() {
        let stepper = RUIStepper()
        var upTriggered = false
        var downTriggered = false
        stepper.upTrigger = { _ in
            upTriggered = true
        }
        stepper.downTrigger = { _ in
            downTriggered = true
        }

        stepper.arTouchStarted(SIMD3<Float>(0.3, 0, 0), hasCollided: true)
        stepper.arTouchEnded(nil, nil)
        XCTAssertTrue(upTriggered)
        XCTAssertFalse(downTriggered)
        stepper.arTouchStarted(SIMD3<Float>(-0.3, 0, 0), hasCollided: true)
        stepper.arTouchEnded(nil, nil)
        XCTAssertTrue(upTriggered)
    }

}
