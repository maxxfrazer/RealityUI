//
//  RUIDragComponent.swift
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
    /// `MoveConstraint` defines the constraints that can be applied to the movement of entities in a 3D environment.
    ///
    /// This enumeration is used in conjunction with ``RUIDragComponent`` to specify how entities respond to drag interactions in AR or VR contexts.
    /// It offers various constraint options, each tailored to different interaction requirements, allowing for more controlled and precise entity movement.
    /// Depending on the chosen constraint, entities can be restricted to move within a bounding box,
    /// limited to predefined points, or constrained by a custom clamping function.
    ///
    /// Examples of where `MoveConstraint` can be beneficial include scenarios like guiding an entity along a specific path,
    /// confining movement within a certain area, or applying complex, custom movement rules.
    public enum MoveConstraint {
        /// Constrains movement within a bounding box.
        ///
        /// Use this constraint when you want to limit the movement of an entity within a predefined three-dimensional area.
        /// The `BoundingBox` parameter specifies the dimensions and position of the box within which the entity can move.
        ///
        /// Example usage:
        /// ```swift
        /// let constraint = MoveConstraint.box(
        ///     BoundingBox(min: [-1, -1, -1], max: [1, 1, 1])
        /// )
        /// ```
        case box(BoundingBox)
        /// Constrains movement to a set of points.
        ///
        /// This constraint limits the movement of an entity to specific locations in space, defined by an array of `SIMD3<Float>` points.
        /// It's useful for scenarios where movement should be restricted to discrete positions, like on a grid or along a path.
        ///
        /// Example usage:
        /// ```swift
        /// let constraint = MoveConstraint.points([
        ///     [0, 0, 0],
        ///     [5, 0, 0],
        ///     [10, 0, 0]
        /// ])
        /// ```
        case points([SIMD3<Float>])
        /// Applies a custom clamping function to the movement.
        ///
        /// This constraint allows for the most flexibility by enabling the use of a custom function to determine movement constraints.
        /// The function takes a `SIMD3<Float>` as input, representing the proposed new position,
        /// and returns a `SIMD3<Float>` that represents the allowed position.
        ///
        /// Example usage:
        /// ```swift
        /// let constraint = MoveConstraint.clamp { proposedPosition in
        ///     // Define custom logic to modify and return the proposed position
        ///     return modifiedPosition
        /// }
        /// ```
        case clamp((SIMD3<Float>) -> SIMD3<Float>)
//        /// Constrains movement to a plane.
//        case plane(simd_float4x4)
//        /// Constrains movement to a sphere.
//        case sphere(position: simd_float3, radius: Float)
    }
    /// ``DragComponentType`` represents the type of drag interaction in a 3D environment.
    ///
    /// This enumeration defines the different ways that drag interactions can be interpreted and handled within a 3D space.
    /// Each case of this enum specifies a unique type of drag interaction, allowing for customizable behavior
    /// depending on the user's input and the application's requirements.
    public enum DragComponentType {
        /// Represents a movement interaction with an optional constraint.
        case move(MoveConstraint?)
        /// Represents a rotational interaction around a specified axis.
        case turn(axis: SIMD3<Float>)
        /// Represents a click-type interaction, similar to `touchUpInside`.
        case click
    }

    /// The type of drag interaction.
    public internal(set) var type: DragComponentType

    /// An optional delegate to handle drag events.
    public weak var delegate: RUIDragDelegate?

    /// Initializes a new `RUIDragComponent` with a specific drag interaction type and an optional delegate.
    ///
    /// - Parameters:
    ///   - type: The type of 3D drag interaction.
    ///   - delegate: An optional delegate to handle drag events.
    public init(type: DragComponentType, delegate: RUIDragDelegate? = nil) {
        self.type = type
        self.delegate = delegate
    }

    /// The current touch state of the drag component.
    public internal(set) var touchState: DragState?

    /// `DragState` represents the state of the current in-progress touch in an AR/VR context.
    ///
    /// This enum is used to track the touch state, including the position and distance of the touch in relation to the AR object.
    public enum DragState {

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
        case turn(plane: float4x4, start: SIMD3<Float>)
        case click(isSelected: Bool)
    }

    /// Calculates the collision points based on the provided ray.
    ///
    /// - Parameter ray: A tuple containing the origin and direction of the ray.
    /// - Returns: The collision point as `SIMD3<Float>` if a collision occurs, otherwise `nil`.
    internal func getCollisionPoints(with ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) -> SIMD3<Float>? {
        switch self.touchState {
        case .move(_, let distance): ray.origin + normalize(ray.direction) * distance
        case .turn(let plane, _): self.findPointOnPlane(ray: ray, plane: plane)
        case .click: ray.origin + ray.direction
        case .none: nil
        }
    }

    internal var rotateVector: SIMD3<Float>? {
        switch self.type {
        case .turn(let axis): normalize(axis)
        default: nil
        }
    }

    internal var moveContraint: MoveConstraint? {
        switch self.type {
        case .move(let moveConstraint): moveConstraint
        default: nil
        }
    }

    /// Plane that we run the raycast against.
    internal func turnCollisionPlane(for axis: SIMD3<Float>) -> float4x4 {
        // Find two perpendicular vectors
        let arbitraryVector = axis.y == 0 && axis.z == 0
            ? SIMD3<Float>(x: 0, y: 1, z: 0)
            : SIMD3<Float>(x: 0, y: 0, z: 1)
        let normAxis = normalize(axis)
        let perpVector1 = normalize(cross(normAxis, arbitraryVector))
        let perpVector2 = normalize(cross(normAxis, perpVector1))

        return float4x4(columns: (
            SIMD4<Float>(perpVector1, 0),
            SIMD4<Float>(perpVector2, 0),
            SIMD4<Float>(normAxis, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
    }

    internal func findPointOnPlane(
        ray: (origin: SIMD3<Float>, direction: SIMD3<Float>), plane: float4x4
    ) -> SIMD3<Float>? {
        // Extract plane normal and a point on the plane from the matrix
        let planeNormal = SIMD3<Float>(plane.columns.2.x, plane.columns.2.y, plane.columns.2.z)
        let pointOnPlane = SIMD3<Float>(plane.columns.3.x, plane.columns.3.y, plane.columns.3.z)

        let normRayD = normalize(ray.direction)
        // calculate intersection
        let denominator = dot(normRayD, planeNormal)
        if abs(denominator) > 1e-6 { // Ensure not parallel
            let t = dot(pointOnPlane - ray.origin, planeNormal) / denominator
            // return the point of intersection
            return ray.origin + t * normRayD
        } else { // The ray is parallel to the plane, no intersection
            return nil
        }
    }

    internal func handleMoveState(_ entity: Entity, _ newTouchPos: SIMD3<Float>?, _ poi: SIMD3<Float>) {
        guard let newTouchPos else { return }
        let parentSpaceNTP = entity.convert(position: newTouchPos, to: entity.parent)
        let parentSpaceOTP = entity.convert(position: poi, to: entity.parent)
        guard let arTouchComp = entity.components.get(RUIDragComponent.self) else { return }
        let endPos = entity.position + parentSpaceNTP - parentSpaceOTP
        entity.position = switch arTouchComp.moveContraint {
        case .box(let bbox): bbox.clamp(endPos)
        case .points(let points): RUIDragComponent.closestPoint(from: endPos, points: points)
        case .clamp(let clampFoo): clampFoo(endPos)
        case .none: endPos
        }
    }

    internal func handleTurnState(
        _ entity: Entity, _ plane: float4x4, _ lastPoint: SIMD3<Float>,
        _ ray: inout (origin: SIMD3<Float>, direction: SIMD3<Float>)
    ) {
        guard let rotateVector,
              let newPoint = self.findPointOnPlane(ray: ray, plane: plane)
        else { return }

        // calculate the unsigned angle
        let dotProduct = dot(normalize(lastPoint), normalize(newPoint))
        let angle = acos(min(max(dotProduct, -1.0), 1.0)) // Clamp the value to avoid NaN

        // determine the sign, apply to the angle
        let crossProd = cross(lastPoint, newPoint)
        let signedAngle = dot(crossProd, rotateVector) < 0 ? angle : -angle

        // check if there is a significant angle change
        if angle > 1e-7 {
            // calculate the rotation quaternion, and apply
            entity.orientation *= simd_quatf(angle: signedAngle, axis: rotateVector)
            // update the turn state, so we only check the difference with the new angle
            self.touchState = .turn(plane: plane, start: newPoint)
        }
        ray.direction = normalize(ray.direction) * simd_distance(ray.origin, newPoint)
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
#if os(iOS) || os(macOS)
internal extension RUIDragGestureRecognizer {
    func dragBegan(
        entity: Entity, touchInView: CGPoint, touchInWorld: SIMD3<Float>
    ) -> Bool {
        guard let arTouchComp = entity.components.get(RUIDragComponent.self)
        else { return false }
        self.touchLocation = touchInView
        self.entity = entity

        let origin = self.arView.cameraTransform.translation
        let direction = touchInWorld - origin
        if !arTouchComp.dragStarted(
            entity, ray: (origin, direction)
        ) { return false }
        self.viewSubscriber = self.arView.scene.subscribe(
            to: SceneEvents.Update.self,
            dragUpdatedSceneEvent(_:)
        )
        return true
    }

    func dragUpdatedSceneEvent(_ event: SceneEvents.Update?) {
        guard let touchLocation = self.touchLocation,
              let hitEntity = self.entity,
              let touchComp = self.entity?.components.get(RUIDragComponent.self),
              let ray = self.arView.ray(through: touchLocation)
        else { return }

        var hasCollided = false
        if let htResult = self.arView.hitTest(
            touchLocation, query: .nearest, mask: RealityUI.longGestureMask
        ).first {
            hasCollided = htResult.entity == self.entity
        }
        #if os(iOS)
        if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
            return self.touchesEnded([activeTouch], with: UIEvent())
        }
        #endif
        touchComp.dragUpdated(
            hitEntity, ray: ray, hasCollided: hasCollided
        )
    }
}
#endif

fileprivate extension BoundingBox {
    func clamp(_ position: SIMD3<Float>) -> SIMD3<Float> {
        [Swift.min(max.x, Swift.max(min.x, position.x)),
         Swift.min(max.y, Swift.max(min.y, position.y)),
         Swift.min(max.z, Swift.max(min.z, position.z))]
    }
}
