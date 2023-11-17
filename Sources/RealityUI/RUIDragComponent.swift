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

/// `RUIDragComponent` is a component for managing drag interactions in an AR or VR context.
/// It provides various constraints for dragging movements with constraints such as boxes, points and clamps.
public class RUIDragComponent: Component {
    public enum MoveConstraint {
        /// Constrains movement within a bounding box.
        case box(BoundingBox)
        /// Constrains movement to a set of points.
        case points([SIMD3<Float>])
        /// Applies a custom clamping function to the movement.
        case clamp((SIMD3<Float>) -> SIMD3<Float>)
//        /// Constrains movement to a plane.
//        case plane(simd_float4x4)
//        /// Constrains movement to a sphere.
//        case sphere(position: simd_float3, radius: Float)
    }
    /// `ARTouchType` represents the type of touch interaction in an AR environment.
    public enum ARTouchType {
        /// Represents a movement interaction with an optional constraint.
        case move(MoveConstraint?)
        /// Represents a rotational interaction around a specified axis.
        case turn(axis: SIMD3<Float>)
    }

    /// The type of touch interaction.
    var type: ARTouchType

    /// An optional delegate to handle drag events.
    weak var delegate: RUIDragDelegate?

    /// Initializes a new `RUIDragComponent` with a specific touch interaction type and an optional delegate.
    ///
    /// - Parameters:
    ///   - type: The type of AR touch interaction.
    ///   - delegate: An optional delegate to handle drag events.
    public init(type: ARTouchType, delegate: RUIDragDelegate? = nil) {
        self.type = type
        self.delegate = delegate
    }

    /// The current touch state of the drag component.
    public internal(set) var touchState: ARTouchState?

    /// `ARTouchState` represents the state of the current in-progress touch in an AR/VR context.
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

    /// Calculates the collision points based on the provided ray.
    ///
    /// - Parameter ray: A tuple containing the origin and direction of the ray.
    /// - Returns: The collision point as `SIMD3<Float>` if a collision occurs, otherwise `nil`.
    internal func getCollisionPoints(with ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) -> SIMD3<Float>? {
        switch self.touchState {
        case .move(_, let distance):
            return ray.origin + normalize(ray.direction) * distance
        default: break
        }
        return nil
    }

    /// Called when a drag interaction starts.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - worldPos: The world position where the drag started.
    ///   - origin: The original position of the entity.
    public func dragStarted(
        _ entity: Entity, worldPos: SIMD3<Float>, origin: SIMD3<Float>
    ) {
        let localPos = entity.convert(position: worldPos, from: nil)
        let dist = distance(origin, worldPos)
        switch self.type {
        case .move:
            self.touchState = .move(poi: localPos, distance: dist)
        default: break
        }
        self.delegate?.ruiDragStarted(entity, ray: (origin: origin, direction: normalize(worldPos - origin)))
    }

    /// Called when a drag interaction is updated.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - ray: A tuple containing the origin and direction of the ray used in the drag interaction.
    ///   - hasCollided: A boolean indicating whether there has been a collision.
    public func dragUpdated(
        _ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>), hasCollided: Bool
    ) {
        let worldPos = self.getCollisionPoints(with: ray)
        var newTouchPos: SIMD3<Float>?
        if let worldPos {
            newTouchPos = entity.convert(position: worldPos, from: nil)
        }
        var outputRay = ray

        switch self.touchState {
        case .move(let poi, let len):
            handleMoveState(entity, newTouchPos, poi)
            outputRay.direction = simd_normalize(ray.direction) * len
        default: break
        }
        self.delegate?.ruiDragUpdated(entity, ray: outputRay)
    }

    /// Called when a drag interaction ends.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - ray: A tuple containing the origin and direction of the ray used in the drag interaction.
    public func dragEnded(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {
        var outputRay = ray
        switch self.touchState {
        case .move(_, let len):
            outputRay.direction = simd_normalize(ray.direction) * len
        default: break
        }
        touchState = nil
        self.delegate?.ruiDragEnded(entity, ray: outputRay)
    }

    /// Called when a drag interaction is cancelled.
    ///
    /// - Parameter entity: The entity involved in the drag interaction.
    public func dragCancelled(_ entity: Entity) {
        touchState = nil
        self.delegate?.ruiDragCancelled(entity)
    }

    internal func handleMoveState(_ entity: Entity, _ newTouchPos: SIMD3<Float>?, _ poi: SIMD3<Float>) {
        guard let newTouchPos else { return }
        let parentSpaceNTP = entity.convert(position: newTouchPos, to: entity.parent)
        let parentSpaceOTP = entity.convert(position: poi, to: entity.parent)
        guard let arTouchComp = entity.components.get(RUIDragComponent.self) else { return }
        let endPos = entity.position + parentSpaceNTP - parentSpaceOTP
        entity.position = switch arTouchComp.type {
        case .move(let moveConstr):
            switch moveConstr {
            case .box(let bbox): bbox.clamp(endPos)
            case .points(let points): RUIDragComponent.closestPoint(from: endPos, points: points)
            case .clamp(let clampFoo): clampFoo(endPos)
            case .none: endPos
            }
        case .turn: fatalError("Not implemented")
        }

    }

    internal static func closestPoint(from start: SIMD3<Float>, points: [SIMD3<Float>]) -> SIMD3<Float> {
        if points.isEmpty { return start }
        var bestPoint = points[0]
        var minDist = Float.infinity
        for point in points {
            let newDist = simd_distance_squared(start, point)
            if newDist < minDist {
                minDist = newDist
                bestPoint = point
            }
        }
        return bestPoint
    }
}

/// `RUIDragDelegate` is a protocol for handling drag events within an AR/VR context.
///
/// `RUIDragDelegate` provides methods to manage the lifecycle of a drag interaction with entities.
public protocol RUIDragDelegate: AnyObject {
    /// Called when a drag interaction begins on an AR entity.
    ///
    /// Implement this method to handle the initial interaction when the user starts dragging an entity.
    /// This method is triggered at the start of the drag gesture.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` that the user starts dragging.
    ///   - ray: A ray showing the origin and direction of the ray used to move the entity. The direction is not normalised.
    func ruiDragStarted(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
    /// Called when there is an update to a drag interaction on an AR entity.
    ///
    /// Implement this method to handle updates that occur during a drag interaction.
    /// This is typically called in response to movement or changes in the drag gesture.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` whose position or state is being updated due to the drag interaction.
    ///   - ray: A ray showing the origin and direction of the ray used to move the entity. The direction is not normalised.
    func ruiDragUpdated(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
    /// Called when a drag interaction on an AR entity ends.
    ///
    /// Implement this method to handle the conclusion of a drag interaction.
    /// This method is triggered when the user releases the entity or completes the drag gesture.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` that was being dragged and is now released.
    ///   - ray: A ray showing the origin and direction of the ray used to move the entity. The direction is not normalised.
    func ruiDragEnded(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
    /// Called when a drag interaction on an AR entity is cancelled.
    ///
    /// Implement this method to handle scenarios where a drag interaction is interrupted or cancelled.
    /// This could be due to various reasons, such as an interruption in the user's gesture or application state changes.
    ///
    /// - Parameter entity: The `Entity` that was being dragged before the interaction was cancelled.
    func ruiDragCancelled(_ entity: Entity)
}

public extension RUIDragDelegate {
    func ruiDragStarted(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDragUpdated(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDragEnded(_ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDragCancelled(_ entity: Entity) {}
}

internal extension RUILongTouchGestureRecognizer {
    func dragBegan(
        entity: Entity, touchInView: CGPoint, touchInWorld: SIMD3<Float>
    ) {
        guard let arTouchComp = entity.components.get(RUIDragComponent.self)
        else { return }
        self.touchLocation = touchInView
        self.entityComp = entity
        var worldTouch = touchInWorld
        if let collisionPlane {
            if let planeCollisionPoint = self.arView.unproject(
                touchInView, ontoPlane: collisionPlane
            ) {
                worldTouch = planeCollisionPoint
            } else { return }
        }
        arTouchComp.dragStarted(
            entity, worldPos: worldTouch,
            origin: self.arView.cameraTransform.translation
        )
        self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, dragUpdatedSceneEvent(_:))
    }

    func dragUpdatedSceneEvent(_ event: SceneEvents.Update) {
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
