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

public struct ARTouchComponent: Component {
    public enum MoveConstraint {
        case box(BoundingBox)
        case plane(simd_float4x4)
        case sphere(position: simd_float3, radius: Float)
    }
    public enum ARTouchType {
        case move(MoveConstraint?)
        case turn(axis: simd_float3)
    }

    public init(type: ARTouchType) {
        self.type = type
    }

    public enum ARTouchState {
        case move(poi: simd_float3, distance: Float)
    }
    var type: ARTouchType

    public func dragStarted(
        _ entity: Entity, worldPos: SIMD3<Float>, cameraTransform: Transform
    ) -> ARTouchState? {
        let localPos = entity.convert(position: worldPos, from: nil)
        switch self.type {
        case .move:
            return .move(poi: localPos, distance: distance(cameraTransform.translation, worldPos))
        default: break
        }
        return nil
    }
    @discardableResult
    public func dragUpdated(
        _ entity: Entity, worldPos: SIMD3<Float>,
        hasCollided: Bool,
        lastState: ARTouchState?
    ) -> ARTouchState? {
        let newTouchPos = entity.convert(position: worldPos, from: nil)

        switch lastState {
        case .move(let poi, _):
            let parentSpaceNTP = entity.convert(position: newTouchPos, to: entity.parent)
            let parentSpaceOTP = entity.convert(position: poi, to: entity.parent)
            guard let arTouchComp = entity.components.get(ARTouchComponent.self) else { return nil }
            switch arTouchComp.type {
            case .move(let moveConstr):
                switch moveConstr {
                case .box(let bbox):
                    let endPos = entity.position + parentSpaceNTP - parentSpaceOTP
                    entity.position = bbox.clamp(endPos)
                case nil:
                    entity.position += parentSpaceNTP - parentSpaceOTP
                default: break
                }
            default: break
            }

//        case .turn(let simd_float3):
//            <#code#>
        default: break
        }
        return nil

    }
    public func dragEnded(_ entity: Entity, worldPos: SIMD3<Float>?) {}
    public func dragCancelled(_ entity: Entity) {}
}

extension HasARTouch {
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
    var entityCompUpdate: ARTouchComponent.ARTouchState?

    var touchLocation: CGPoint?
    var viewSubscriber: Cancellable?
    var collisionPlane: float4x4?
    var collisionDistance: Float?

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
        if let hitEntity = firstHit.entity as? HasARTouch {
            self.touchesBeganARTouch(hitEntity: hitEntity, touchInView: touchInView, touchInWorld: firstHit.position)
        } else if firstHit.entity.components.has(ARTouchComponent.self) {
            self.touchesBeganARTouchComp(
                entity: firstHit.entity,
                touchInView: touchInView, touchInWorld: firstHit.position
            )
        } else { return false }
        return true
    }

    func touchesBeganARTouchComp(
        entity: Entity, touchInView: CGPoint, touchInWorld: SIMD3<Float>
    ) {
        guard let arTouchComp = entity.components.get(ARTouchComponent.self) else {
            return
        }
        self.touchLocation = touchInView
        self.entityComp = entity
        var worldTouch = touchInWorld
//        self.collisionPlane = arTouchComp.collisionPlane
        if let collisionPlane {
            if let planeCollisionPoint = self.arView.unproject(
                touchInView, ontoPlane: collisionPlane
            ) {
//                if let maxDist = (hitEntity as? HasTurnTouch)?.maxDistance {
//                    let convPoint = hitEntity.convert(position: planeCollisionPoint, from: nil)
//                    if convPoint.magnitude > maxDist {
//                        return
//                    }
//                }
                worldTouch = planeCollisionPoint
            } else {
                return
            }
        }
        entityCompUpdate = arTouchComp.dragStarted(
            entity, worldPos: worldTouch, cameraTransform: self.arView.cameraTransform
        )
        self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateRUILongTouchComponent(_:))
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
            ) {
                if let maxDist = (hitEntity as? HasTurnTouch)?.maxDistance {
                    let convPoint = hitEntity.convert(position: planeCollisionPoint, from: nil)
                    if convPoint.magnitude > maxDist {
                        return
                    }
                }
                worldTouch = planeCollisionPoint
            } else {
                return
            }
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
        } else if let entityCompUpdate, let newRay = self.arView.ray(through: touchLocation) {
            switch entityCompUpdate {
            case .move(_, let distance):
                newPos = newRay.origin + normalize(newRay.direction) * distance
            }
        }
        return (newPos, hasCollided)
    }

    func updateRUILongTouchComponent(_ event: SceneEvents.Update?) {
        guard let touchLocation = self.touchLocation,
              let hitEntity = self.entityComp,
              let touchComp = self.entityComp?.components.get(ARTouchComponent.self)
        else {
            return
        }
        let (newPos, hasCollided) = getCollisionPoints(touchLocation)
        #if os(iOS)
        if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
            self.touchesEnded([activeTouch], with: UIEvent())
            return
        }
        #endif
        touchComp.dragUpdated(
            hitEntity, worldPos: newPos ?? .zero, hasCollided: hasCollided,
            lastState: self.entityCompUpdate
        )
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

#if os(macOS)
extension RUILongTouchGestureRecognizer {
    override func mouseDown(with event: NSEvent) {
        guard self.touchLocation == nil
        else {
            return
        }
        let touchInView = self.arView.convert(event.locationInWindow, from: nil)
        //    self.activeTouch = touches.first
        if !globalTouchBegan(touchInView: touchInView) {
            self.mouseUp(with: event)
            return
        }
        super.mouseDown(with: event)
    }
    override func mouseDragged(with event: NSEvent) {
        if (entity == nil && entityComp == nil) || self.touchLocation == nil {
            return
        }
//        print(event.locationInWindow)

        let touchInView = self.arView.convert(event.locationInWindow, from: nil)

        if touchInView == self.touchLocation {
            return
        }
//        print("touchInView: \(touchInView)")
        self.touchLocation = touchInView
    }
    override func mouseUp(with event: NSEvent) {
        guard self.touchLocation != nil else {
            return
        }
        let (newPos, hasCollided) = getCollisionPoints(touchLocation!)
        self.touchLocation = nil
        entity?.arTouchEnded(at: newPos, hasCollided: hasCollided)
        self.entity = nil
        self.entityComp = nil
        self.viewSubscriber?.cancel()
    }
}
#endif

fileprivate extension SIMD where Self.Scalar: FloatingPoint {
    var magnitude: Self.Scalar {
        var sqSum: Self.Scalar = 0
        for indice in self.indices {
            sqSum += self[indice] * self[indice]
        }
        return sqrt(sqSum)
    }
}
