//
//  HasClick.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// An interface used for entities which have actions upon being clicked
@available(*, deprecated, message: "Please use TapActionComponent instead.")
public protocol HasClick: HasRUI, HasCollision {
    /// Action to be applied on successfully tapping an Entity.
    var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? {get set}
}

/// ``TapActionComponent`` is a component that allows entities to respond
/// to tap actions in the RealityKit environment.
///
/// When an entity is associated with a ``TapActionComponent``, it indicates
/// that the entity should trigger an action when tapped.
/// There is also requirement for the entity to have a `CollisionComponent`.
///
/// The action is a closure that provides both the tapped entity and
/// the world position (if available) of the point where the entity was tapped.
///
/// > The world position might be `nil` if the exact point of collision cannot be determined.
///
/// Example usage:
/// ```swift
/// let entity: Entity = ...
/// entity.components[TapActionComponent.self] = TapActionComponent { tappedEntity, worldPosition in
///     print("Entity \(tappedEntity) was tapped at \(worldPosition ?? .zero)!")
/// }
/// ```
public struct TapActionComponent: Component {
    /// The action to be triggered when the entity is tapped.
    ///
    /// - Parameters:
    ///   - Entity: The entity that was tapped.
    ///   - SIMD3<Float>?: The world position where the entity was tapped, or `nil` if not available.
    public var action: ((Entity, SIMD3<Float>?) -> Void)?

    /// Create a new TapActionComponent object.
    /// - Parameter action: The action to be triggered when the entity is tapped.
    public init(action: ((Entity, SIMD3<Float>?) -> Void)? = nil) {
        self.action = action
    }
}
