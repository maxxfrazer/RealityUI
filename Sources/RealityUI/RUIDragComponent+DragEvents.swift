//
//  RUIDragComponent+DragEvents.swift
//  
//
//  Created by Max Cobb on 20/11/2023.
//

import RealityKit

// Extension for SIMD3<Double>
extension SIMD3 where Scalar == Double {
    func toFloat3() -> SIMD3<Float> {
        return SIMD3<Float>(Float(self.x), Float(self.y), Float(self.z))
    }
}

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
        var dist = simd_length(ray.direction)
        switch self.type {
        case .move:
            #if os(visionOS)
            dist = 0 // we don't care about origin with visionos
            #endif
            self.touchState = .move(poi: localPos, distance: dist)
        case .turn(let axis):
            let plane = self.turnCollisionPlane(for: axis)
            guard let pointOnPlane = self.findPointOnPlane(ray: ray, plane: plane) else { return false }
            self.touchState = .turn(plane: plane, start: pointOnPlane)
        case .click:
            self.touchState = .click(isSelected: true)
            self.delegate?.ruiDrag(entity, selectedDidUpdate: true)
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
            if len != 0 {
                outputRay.direction = simd_normalize(ray.direction) * len
            }
        case .turn(let plane, let lastPoint): handleTurnState(entity, plane, lastPoint, &outputRay)
        case .click(let selected):
            if selected != hasCollided {
                self.touchState = .click(isSelected: hasCollided)
                self.delegate?.ruiDrag(entity, selectedDidUpdate: hasCollided)
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
        case .move(_, let len) where len != 0:
            outputRay.direction = simd_normalize(ray.direction) * len
        case .click(let selected):
            if selected {
                self.delegate?.ruiDrag(entity, touchUpInsideDidComplete: ray)
            } else {
                self.delegate?.ruiDrag(entity, touchUpInsideDidFail: ray)
            }
            self.delegate?.ruiDrag(entity, selectedDidUpdate: false)
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
