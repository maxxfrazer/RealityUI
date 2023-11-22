//
//  RUILongTouchGestureRecognizer.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
#if os(iOS)
import UIKit
/// Typealias to easily access UIGestureRecognizer and NSGestureRecognizer on iOS and macOS respectively
public typealias GestureBase = UIGestureRecognizer
#elseif os(macOS)
import AppKit
/// Typealias to easily access UIGestureRecognizer and NSGestureRecognizer on iOS and macOS respectively
public typealias GestureBase = NSGestureRecognizer
#endif
import Combine

extension BoundingBox {
    func clamp(_ position: SIMD3<Float>) -> SIMD3<Float> {
        [
            Swift.max(self.min.x, Swift.min(self.max.x, position.x)),
            Swift.max(self.min.y, Swift.min(self.max.y, position.y)),
            Swift.max(self.min.z, Swift.min(self.max.z, position.z))
        ]
    }
}

/// This Gesture is currently used for any gesture other than simple taps.
@objc internal class RUILongTouchGestureRecognizer: GestureBase {
    let arView: ARView

    #if os(iOS)
    internal var activeTouch: UITouch?
    #endif

    var collisionStart: SIMD3<Float>?
    var entity: Entity?

    var touchLocation: CGPoint?
    var viewSubscriber: Cancellable?

    public init(target: Any?, action: Selector?, view: ARView) {
        self.arView = view
        super.init(target: target, action: action)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func globalTouchBegan(touchInView: CGPoint) -> Bool {
        guard let firstHit = self.arView.hitTest(
            touchInView, query: .nearest, mask: RealityUI.longGestureMask
        ).first, firstHit.entity.components.has(RUIDragComponent.self) else {
            return false
        }
        return self.dragBegan(
            entity: firstHit.entity,
            touchInView: touchInView, touchInWorld: firstHit.position
        )
    }
}
