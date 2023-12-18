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
}
