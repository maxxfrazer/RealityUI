//
//  RUIDragDelegate.swift
//  
//
//  Created by Max Cobb on 20/11/2023.
//

import RealityKit

/// `RUIDragDelegate` is a protocol for handling drag events within an AR/VR context.
///
/// `RUIDragDelegate` provides methods to manage the lifecycle of a drag interaction with entities.
public protocol RUIDragDelegate: AnyObject {
    /// Called when a drag interaction begins on an entity.
    ///
    /// Implement this method to handle the initial interaction when the user starts dragging an entity.
    /// This method is triggered at the start of the drag gesture.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` that the user starts dragging.
    ///   - ray: A ray showing the origin and direction of the ray used to move the entity. The direction is not normalised.
    func ruiDrag(_ entity: Entity, dragDidStart ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
    /// Called when there is an update to a drag interaction on an entity.
    ///
    /// Implement this method to handle updates that occur during a drag interaction.
    /// This is typically called in response to movement or changes in the drag gesture.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` whose position or state is being updated due to the drag interaction.
    ///   - ray: A ray showing the origin and direction of the ray used to move the entity. The direction is not normalised.
    func ruiDrag(_ entity: Entity, dragDidUpdate ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
    /// Called when a drag interaction on an AR entity ends.
    ///
    /// Implement this method to handle the conclusion of a drag interaction.
    /// This method is triggered when the user releases the entity or completes the drag gesture.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` that was being dragged and is now released.
    ///   - ray: A ray showing the origin and direction of the ray used to move the entity. The direction is not normalised.
    func ruiDrag(_ entity: Entity, dragDidEnd ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
    /// Called when a drag interaction on an entity is cancelled.
    ///
    /// Implement this method to handle scenarios where a drag interaction is interrupted or cancelled.
    /// This could be due to various reasons, such as an interruption in the user's gesture or application state changes.
    ///
    /// - Parameter entity: The `Entity` that was being dragged before the interaction was cancelled.
    func ruiDragCancelled(_ entity: Entity)

    /// Called when the collision state of a dragged entity changes.
    ///
    /// Implement this method to respond to changes in the collision state of the entity during a drag interaction.
    /// This can be used to trigger responses or behaviors based on collision events.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` involved in the collision state change.
    ///   - hasCollided: A Boolean value indicating the new collision state of the entity.
    func ruiDrag(_ entity: Entity, collisionDidUpdate hasCollided: Bool)

    /// Called when a touch-up event is completed on entities with a ``RUIDragComponent`` of type ``RUIDragComponent/DragComponentType/click``.
    ///
    /// Implement this method to handle the completion of a touch-up gesture on draggable entities.
    /// This can be used to finalize interactions or trigger specific actions when the user completes a touch-up gesture on an entity with the specified drag component.
    ///
    /// - Parameters:
    ///   - entity: The `Entity` on which the touch-up gesture is completed.
    ///   - ray: A ray representing the origin and direction of the touch-up interaction. The direction vector is not normalized.
    func ruiDrag(_ entity: Entity, touchUpInsideDidComplete ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))

    func ruiDrag(_ entity: Entity, touchUpInsideDidFail ray: (origin: SIMD3<Float>, direction: SIMD3<Float>))
}

public extension RUIDragDelegate {
    func ruiDrag(_ entity: Entity, dragDidStart ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDrag(_ entity: Entity, dragDidUpdate ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDrag(_ entity: Entity, dragDidEnd ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDragCancelled(_ entity: Entity) {}
    func ruiDrag(_ entity: Entity, collisionDidUpdate hasCollided: Bool) {}
    func ruiDrag(_ entity: Entity, touchUpInsideDidComplete ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
    func ruiDrag(_ entity: Entity, touchUpInsideDidFail ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {}
}
