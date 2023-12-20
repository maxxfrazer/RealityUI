//
//  RUITextureTests.swift
//
//
//  Created by Max Cobb on 29/01/2023.
//

import XCTest
import RealityKit
@testable import RealityUI

@available(iOS 15.0, macOS 12, *)
final class RUITextureTests: XCTestCase {

    override func setUpWithError() throws {}

    override func tearDownWithError() throws {}

    func testBasicTexture() async throws {
        let tex = try await RUITexture.generateTexture(systemName: "pencil", pointSize: 20)
        let xcMainThread = XCTestExpectation(description: "main async called")
        DispatchQueue.main.async {
            XCTAssertEqual(tex.width, 48, accuracy: 1)
            XCTAssertEqual(tex.height, 48, accuracy: 1)
            xcMainThread.fulfill()
        }
        await fulfillment(of: [xcMainThread])
    }

    func testInvalidTexture() async throws {
        do {
            _ = try await RUITexture.generateTexture(systemName: "｜nv@中id")
        } catch let err as RUITexture.TextureError {
            XCTAssertEqual(err, .invalidSystemName)
        }
    }
}
