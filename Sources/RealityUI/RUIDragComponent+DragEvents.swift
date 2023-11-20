//
//  RUIDragComponent+DragEvents.swift
//  
//
//  Created by Max Cobb on 20/11/2023.
//

import RealityKit

extension RUIDragComponent {
    /// Called when a drag interaction starts.
    ///
    /// - Parameters:
    ///   - entity: The entity involved in the drag interaction.
    ///   - worldPos: The world position where the drag started.
    ///   - origin: The original position of the entity.
    @discardableResult
    public func dragStarted(
        _ entity: Entity, ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)
    ) -> Bool {
        let worldPos = ray.origin + ray.direction
        let localPos = entity.convert(position: worldPos, from: nil)
        let dist = simd_length(ray.direction)
        switch self.type {
        case .move:
            self.touchState = .move(poi: localPos, distance: dist)
        case .turn(let axis):
            let plane = self.turnCollisionPlane(for: axis)
            guard let pointOnPlane = self.findPointOnPlane(ray: ray, plane: plane) else { return false }
            self.touchState = .turn(plane: plane, start: pointOnPlane)
        case .click:
            self.touchState = .click(true)
            self.delegate?.ruiDrag(entity, collisionDidUpdate: true)
        }
        self.delegate?.ruiDrag(entity, dragDidStart: ray)
        return true
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
        guard let touchState else { return }

        switch touchState {
        case .move(let poi, let len):
            handleMoveState(entity, newTouchPos, poi)
            outputRay.direction = simd_normalize(ray.direction) * len
        case .turn(let plane, let lastPoint): handleTurnState(entity, plane, lastPoint, &outputRay)
        case .click(let collided):
            if collided != hasCollided {
                self.touchState = .click(hasCollided)
                self.delegate?.ruiDrag(entity, collisionDidUpdate: hasCollided)
            }
        }
        // The output ray is slightly modified, so the direction also has a specific magnitude.
        self.delegate?.ruiDrag(entity, dragDidUpdate: outputRay)
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
        case .click(let collided):
            if collided {
                self.delegate?.ruiDrag(entity, touchUpInsideDidComplete: ray)
            } else {
                self.delegate?.ruiDrag(entity, touchUpInsideDidFail: ray)
            }
            self.delegate?.ruiDrag(entity, collisionDidUpdate: false)
        default: break
        }
        touchState = nil
        self.delegate?.ruiDrag(entity, dragDidEnd: outputRay)
    }

    /// Called when a drag interaction is cancelled.
    ///
    /// - Parameter entity: The entity involved in the drag interaction.
    public func dragCancelled(_ entity: Entity) {
        touchState = nil
        self.delegate?.ruiDragCancelled(entity)
    }
}
