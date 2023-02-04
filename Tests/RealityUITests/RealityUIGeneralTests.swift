//
//  RealityUIGeneralTests.swift
//  
//
//  Created by Max Cobb on 31/01/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

final class RealityUIGeneralTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testRealityUILog() throws {
        RealityUI.registerComponents()
        XCTAssertNotNil(RealityUI.shared)
        XCTAssertTrue(RealityUI.shared.componentsRegistered)
    }

    func testAddGestures() throws {
        let arView = ARView()
        RealityUI.enableGestures(.tap, on: arView)
        guard let gesturesForView = RealityUI.shared.enabledGestures[arView] else {
            return XCTFail("No gestures found in RealityUI")
        }
        #if os(iOS)
        guard let viewGestures = arView.gestureRecognizers else {
            return XCTFail("No gestures found in ARView gestureRecognizers")
        }
        #else
        let viewGestures = arView.gestureRecognizers
        #endif
        XCTAssertTrue(gesturesForView.contains(.tap))
        #if os(iOS)
        XCTAssertEqual(viewGestures.count, 2)
        XCTAssertTrue(viewGestures[1] is UITapGestureRecognizer)
        #else
        XCTAssertEqual(viewGestures.count, 1)
        XCTAssertTrue(viewGestures[0] is NSClickGestureRecognizer)
        #endif

    }

}
