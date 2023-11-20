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

/// An interface used for RealityUI entities which respond to gestures beyond just a tap.
/// ie: panning gestures
public protocol HasARTouch: HasRUI, HasCollision {
    /// Called when a new touch has begun on an Entity
    /// - Parameters:
    ///   - worldCoordinate: Collision of the object or collision plane
    ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
    func arTouchStarted(at worldCoordinate: SIMD3<Float>, hasCollided: Bool)

    /// Called when a touch is still on screen or a mouse is still down.
    /// - Parameters:
    ///   - worldCoordinate: Where is the touch currently hits in world space
    ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
    func arTouchUpdated(at worldCoordinate: SIMD3<Float>, hasCollided: Bool)

    /// Touch has ended without issues.
    /// - Parameter worldCoordinate: Coordinate in world space where the released collision came from
    func arTouchEnded(at worldCoordinate: SIMD3<Float>?, hasCollided: Bool?)

    /// Called when touch has been interrupted.
    func arTouchCancelled()

    /// Plane to continue touches with, used for RUISlider + Others
    /// Return nil to just use the Entity `CollisionComponent`
    var collisionPlane: float4x4? { get }
}

/// An interface used for all entities that have long touches where movement
/// is the main interest (vs HasTouchUpInside)
public protocol HasPanTouch: HasARTouch {
    /// A parameter that can be used by being set when the touch starts.
    /// It can then be used to know how far a user has toggled since the start of the touch.
    /// Do not set this value outside of the class using it.
    var panGestureOffset: SIMD3<Float> {get set}
}

public extension HasPanTouch {
    func panTouchStarted(at worldCoordinate: SIMD3<Float>, hasCollided: Bool) {
        self.panGestureOffset = self.convert(position: worldCoordinate, from: nil)
    }
    func panTouchEnded(at worldCoordinate: SIMD3<Float>?, hasCollided: Bool?) {
        self.panGestureOffset = .zero
    }
}

/// An interface used for all entities that have long touches where movement
/// is is not the main interest (vs HasPanTouch)
public protocol HasTouchUpInside: HasARTouch {}

/// This Gesture is currently used for any gesture other than simple taps.
@objc internal class RUILongTouchGestureRecognizer: GestureBase {
    let arView: ARView

    #if os(iOS)
    internal var activeTouch: UITouch?
    #endif

    var collisionStart: SIMD3<Float>?
    // Possible types: HasPanTouch, HasTouchUpInside
    var entity: HasARTouch?
    var entityComp: Entity?

    var touchLocation: CGPoint?
    var viewSubscriber: Cancellable?
    var collisionPlane: float4x4?

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
        ).first else {
            return false
        }
        if firstHit.entity.components.has(RUIDragComponent.self) {
            return self.dragBegan(
                entity: firstHit.entity,
                touchInView: touchInView, touchInWorld: firstHit.position
            )
        } else if let hitEntity = firstHit.entity as? HasARTouch {
            self.touchesBeganARTouch(hitEntity: hitEntity, touchInView: touchInView, touchInWorld: firstHit.position)
        } else { return false }
        return true
    }

    func touchesBeganARTouch(
        hitEntity: HasARTouch, touchInView: CGPoint, touchInWorld: SIMD3<Float>
    ) {
        if !hitEntity.ruiEnabled {
            return
        }
        self.touchLocation = touchInView
        self.entity = hitEntity
        var worldTouch = touchInWorld
        self.collisionPlane = hitEntity.collisionPlane
        if let collisionPlane {
            if let planeCollisionPoint = self.arView.unproject(
                touchInView, ontoPlane: collisionPlane
            ) { worldTouch = planeCollisionPoint
            } else { return }
        }
        hitEntity.arTouchStarted(at: worldTouch, hasCollided: true)
        self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateRUILongTouch(_:))
    }

    internal func getCollisionPoints(_ touchLocation: CGPoint) -> (SIMD3<Float>?, Bool) {
        var newPos: SIMD3<Float>?
        var hasCollided = false
        if let htResult = self.arView.hitTest(
            touchLocation, query: .nearest, mask: RealityUI.longGestureMask
        ).first {
            hasCollided = htResult.entity == self.entity
            newPos = htResult.position
        }
        if let collisionPlane = self.collisionPlane {
            newPos = self.arView.unproject(touchLocation, ontoPlane: collisionPlane)
        }
        return (newPos, hasCollided)
    }

    func updateRUILongTouch(_ event: SceneEvents.Update?) {
        guard let touchLocation = self.touchLocation,
              let hitEntity = self.entity
        else { return }
        let (newPos, hasCollided) = getCollisionPoints(touchLocation)
        #if os(iOS)
        if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
            self.touchesEnded([activeTouch], with: UIEvent())
            return
        }
        #endif
        hitEntity.arTouchUpdated(at: newPos ?? .zero, hasCollided: hasCollided)
    }
}
