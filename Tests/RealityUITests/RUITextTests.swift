//
//  RUITextTests.swift
//
//
//  Created by Max Cobb on 30/01/2023.
//

import XCTest
@testable import RealityUI
import RealityKit

final class RUITextTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() {
        let text = RUIText(with: "test text")
        XCTAssertNotNil(text)
        XCTAssertEqual(text.text, "test text")
    }

    func testEmptyInit() {
        let text = RUIText()
        XCTAssertNotNil(text)
        XCTAssertNil(text.text)
    }

    func testInitWithComponent() {
        let textComponent = TextComponent(text: "test text")
        let text = RUIText(textComponent: textComponent)
        XCTAssertNotNil(text)
        XCTAssertEqual(text.text, "test text")
    }

    func testChangeText() {
        let textComponent = TextComponent(text: "test text")
        let text = RUIText(textComponent: textComponent)
        XCTAssertNotNil(text)
        XCTAssertEqual(text.text, "test text")
        let visualBounds = text.visualBounds(relativeTo: nil)
        text.text = "new text, new text"
        XCTAssertEqual(text.textComponent.text, "new text, new text")
        XCTAssertGreaterThan(text.visualBounds(relativeTo: nil).extents.x, visualBounds.extents.x)
        text.text = nil
        XCTAssertEqual(text.visualBounds(relativeTo: nil).boundingRadius, 0)
    }

    func testTapText() {
        let textComponent = TextComponent(text: "test text")
        let text = RUIText(textComponent: textComponent)
        XCTAssertFalse(text.components.has(TapActionComponent.self))
        text.tapAction = { ent, loc in
            print("entity: \(ent), loc: \(loc ?? .zero)")
        }
        XCTAssertTrue(text.components.has(TapActionComponent.self))
        XCTAssertTrue(text.components.has(CollisionComponent.self))
    }
}
