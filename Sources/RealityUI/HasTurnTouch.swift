//
//  HasTurnTouch.swift
//
//
//  Created by Max Cobb on 5/31/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// An interface used for entities which are to be rotated via one finger drag gestures
public protocol HasTurnTouch: HasPanTouch {}

public extension HasTurnTouch {
  /// Plane that we run the raycast against.
  var collisionPlane: float4x4? {
    return self.transformMatrix(relativeTo: nil)
      * float4x4(self.pivotRotation)
  }

  /// Called when a new touch has begun on an Entity
  /// - Parameters:
  ///   - worldCoordinate: Collision of the object or collision plane
  ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
  func arTouchStarted(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool) {
    self.lastGlobalPosition = worldCoordinate
  }

  /// Called when a touch is still on screen or a mouse is still down.
  /// - Parameters:
  ///   - worldCoordinate: Where is the touch currently hits in world space
  ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
  func arTouchUpdated(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool) {
    var localPos = self.convert(position: worldCoordinate, from: nil)
    localPos = self.pivotRotation.act(localPos)
    var lastLocalPos = self.convert(position: self.lastGlobalPosition, from: nil)
    lastLocalPos = self.pivotRotation.act(lastLocalPos)
    let lastAngle = atan2f(lastLocalPos.x, lastLocalPos.z)
    let angle = atan2f(localPos.x, localPos.z)

    self.orientation *= simd_quatf(angle: angle - lastAngle, axis: self.turnAxis)
    self.lastGlobalPosition = worldCoordinate
  }
  func arTouchCancelled() {
    self.arTouchEnded(nil)
  }
  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?) {
    self.lastGlobalPosition = .zero
  }
}

/// A collection of properties for the entities that conform to `HasTurnTouch`.
public struct TurnComponent: Component {
  internal var lastTouchAngle: Float?
  internal var lastGlobalPosition: SIMD3<Float> = .zero
  /// Axis upon which the object will rotate.
  public var axis: SIMD3<Float>
  /// Maximum distance from the Entity centre where touches will still be picked up
  /// Default: `nil` means infinite distance.
  public var maxDistance: Float?
  /// Create a new `TurnComponent`
  /// - Parameters:
  ///   - axis: Axis upon which the object will rotate.
  ///   - maxDistance: Maximum distance from the Entity centre where touches will still be picked up.
  public init(axis: SIMD3<Float> = [0, 1, 0], maxDistance: Float? = nil) {
    self.axis = axis
    self.maxDistance = maxDistance
  }
}

public extension HasTurnTouch {
  internal var pivotRotation: simd_quatf {
    simd_quaternion(self.turnAxis, [0, 1, 0])
  }
  /// The turn component for the entity.
  var turnTouch: TurnComponent {
    get { self.components[TurnComponent.self] ?? TurnComponent() }
    set { self.components[TurnComponent.self] = newValue }
  }

  /// The axis to turn around for the entity.
  var turnAxis: SIMD3<Float> {
    get { self.turnTouch.axis }
    set { self.turnTouch.axis = newValue }
  }

  /// Maximum distance away from the center of the object where the turn touch is active
  var maxDistance: Float? {
    get { self.turnTouch.maxDistance }
    set { self.turnTouch.maxDistance = newValue }
  }
  internal var lastGlobalPosition: SIMD3<Float> {
    get { self.turnTouch.lastGlobalPosition }
    set { self.turnTouch.lastGlobalPosition = newValue }
  }
}

// MARK: DEPRECATED

/// An interface used for entities which are to be rotated via one finger drag gestures
@available(*, deprecated, renamed: "HasTurnTouch")
public typealias HasPivotTouch = HasTurnTouch

/// A collection of properties for the entities that conform to `HasPivotTouch`.
@available(*, deprecated, renamed: "TurnComponent")
public typealias PivotComponent = TurnComponent
public extension HasTurnTouch {
  /// The axis to turn around for the entity.
  @available(*, deprecated, renamed: "turnAxis")
  var pivotAxis: SIMD3<Float> {
    get { self.turnAxis }
    set { self.turnAxis = newValue }
  }
  /// Maximum distance away from the center of the object where the turn touch is active
  @available(*, deprecated, renamed: "maxDistance")
  var maxPivotDistance: Float? {
    get { self.maxDistance }
    set { self.maxDistance = newValue }
  }
}

public extension TurnComponent {
  /// Axis upon which the object will rotate.
  @available(*, deprecated, renamed: "axis")
  var pivotAxis: SIMD3<Float> {
    get { self.axis }
    set { self.axis = newValue }
  }
  /// Maximum distance from the Entity centre where touches will still be picked up
  /// Default: `nil` means infinite distance.
  @available(*, deprecated, renamed: "maxDistance")
  var maxPivotDistance: Float? {
    get { self.maxDistance }
    set { self.maxDistance = newValue }
  }
}
