//
//  File.swift
//  
//
//  Created by Max Cobb on 15/11/2023.
//

import Foundation
import RealityKit
#if os(iOS)
import UIKit.UIEvent
#endif

public class RUIDragComponent: Component {
    public enum MoveConstraint {
        case box(BoundingBox)
        case plane(simd_float4x4)
        case sphere(position: simd_float3, radius: Float)
    }
    public enum ARTouchType {
        case move(MoveConstraint?)
        case turn(axis: simd_float3)
    }
    var type: ARTouchType
    weak var delegate: RUIDragDelegate?

    public init(type: ARTouchType, delegate: RUIDragDelegate? = nil) {
        self.type = type
        self.delegate = delegate
    }

    public internal(set) var touchState: ARTouchState?
    /// `ARTouchState` represents the state of the current in-progress touch in an AR context.
    ///
    /// This enum is used to track the touch state, including the position and distance of the touch in relation to the AR object.
    public enum ARTouchState {

        /// Represents a move touch state in an AR environment.
        ///
        /// The `move` case is used when the object can move around in space.
        /// It provides details about the location of the initial touch and its distance from a point of view (POV).
        ///
        /// - Parameters:
        ///   - poi: A `SIMD3<Float>` value representing the place on the AR object where the touch first collided.
        ///          This gives the 3D coordinates of the initial touch point.
        ///   - distance: A `Float` value indicating the distance from the POV (Point of View) to the first touch point.
        ///               This helps in understanding how far the touch point is from the user's perspective.
        case move(poi: SIMD3<Float>, distance: Float)
    }

    internal func getCollisionPoints(with ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) -> SIMD3<Float>? {
        switch self.touchState {
        case .move(_, let distance):
            return ray.origin + normalize(ray.direction) * distance
        default: break
        }
        return nil
    }

    public func dragStarted(
        _ entity: Entity, worldPos: SIMD3<Float>, cameraTransform: Transform
    ) {
        let localPos = entity.convert(position: worldPos, from: nil)
        switch self.type {
        case .move:
            self.touchState = .move(poi: localPos, distance: distance(cameraTransform.translation, worldPos))
        default: break
        }
        self.delegate?.dragStarted(entity)
    }

    public func dragUpdated(
        _ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>), hasCollided: Bool
    ) {
        let worldPos = self.getCollisionPoints(with: ray)
        var newTouchPos: SIMD3<Float>?
        if let worldPos {
            newTouchPos = entity.convert(position: worldPos, from: nil)
        }

        switch self.touchState {
        case .move(let poi, _):
            guard let newTouchPos else { return }
            let parentSpaceNTP = entity.convert(position: newTouchPos, to: entity.parent)
            let parentSpaceOTP = entity.convert(position: poi, to: entity.parent)
            guard let arTouchComp = entity.components.get(RUIDragComponent.self) else { return }
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
        default: break
        }
        self.delegate?.dragUpdated(entity)
    }
    public func dragEnded(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {
        touchState = nil
        self.delegate?.dragEnded(entity)
    }
    public func dragCancelled(_ entity: Entity) {
        touchState = nil
        self.delegate?.dragCancelled(entity)
    }
}

public protocol RUIDragDelegate: AnyObject {
    func dragStarted(_ entity: Entity)
    func dragUpdated(_ entity: Entity)
    func dragEnded(_ entity: Entity)
    func dragCancelled(_ entity: Entity)
}

extension RUIDragDelegate {
    func dragStarted(_ entity: Entity) {}
    func dragUpdated(_ entity: Entity) {}
    func dragEnded(_ entity: Entity) {}
    func dragCancelled(_ entity: Entity) {}
}

extension RUILongTouchGestureRecognizer {
    func touchesBeganARTouchComp(
        entity: Entity, touchInView: CGPoint, touchInWorld: SIMD3<Float>
    ) {
        guard let arTouchComp = entity.components.get(RUIDragComponent.self)
        else { return }
        self.touchLocation = touchInView
        self.entityComp = entity
        var worldTouch = touchInWorld
//        self.collisionPlane = arTouchComp.collisionPlane
        if let collisionPlane {
            if let planeCollisionPoint = self.arView.unproject(
                touchInView, ontoPlane: collisionPlane
            ) {
                worldTouch = planeCollisionPoint
            } else { return }
        }
        arTouchComp.dragStarted(
            entity, worldPos: worldTouch,
            cameraTransform: self.arView.cameraTransform
        )
        self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateRUILongTouchComponent(_:))
    }

    func updateRUILongTouchComponent(_ event: SceneEvents.Update?) {
        guard let touchLocation = self.touchLocation,
              let hitEntity = self.entityComp,
              let touchComp = self.entityComp?.components.get(RUIDragComponent.self),
              let ray = self.arView.ray(through: touchLocation)
        else { return }

        var hasCollided = false
        if let htResult = self.arView.hitTest(
            touchLocation, query: .nearest, mask: RealityUI.longGestureMask
        ).first {
            hasCollided = htResult.entity == self.entityComp
        }
        #if os(iOS)
        if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
            self.touchesEnded([activeTouch], with: UIEvent())
            return
        }
        #endif
        touchComp.dragUpdated(
            hitEntity, ray: ray, hasCollided: hasCollided
        )
    }

}
