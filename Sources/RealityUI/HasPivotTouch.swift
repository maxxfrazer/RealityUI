//
//  HasPivotTouch.swift
//
//
//  Created by Max Cobb on 5/31/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// An interface used for entities which are to be rotated via one finger drag gestures
public protocol HasPivotTouch: HasPanTouch {}

public extension HasPivotTouch {
  /// Plane that we run the raycast against.
  var collisionPlane: float4x4? {
    return self.transformMatrix(relativeTo: nil)
      * float4x4(pivotRotation)
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

    self.orientation *= simd_quatf(angle: angle - lastAngle, axis: self.pivotAxis)
    self.lastGlobalPosition = worldCoordinate
  }
  func arTouchCancelled() {
    self.arTouchEnded(nil)
  }
  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?) {
    self.lastGlobalPosition = .zero
  }
}

/// A collection of properties for the entities that conform to `HasPivotTouch`.
public struct PivotComponent: Component {
  internal var lastTouchAngle: Float?
  internal var lastGlobalPosition: SIMD3<Float> = .zero
  /// Axis upon which the object will rotate.
  public var pivotAxis: SIMD3<Float>
  /// Maximum distance from the Entity centre where touches will still be picked up
  /// Default: `nil` means infinite distance.
  public var maxPivotDistance: Float?
  /// Create a new `PivotComponent`
  /// - Parameters:
  ///   - pivotAxis: Axis upon which the object will rotate.
  ///   - maxPivotDistance: Maximum distance from the Entity centre where touches will still be picked up.
  public init(pivotAxis: SIMD3<Float> = [0, 1, 0], maxPivotDistance: Float? = nil) {
    self.pivotAxis = pivotAxis
    self.maxPivotDistance = maxPivotDistance
  }
}

public extension HasPivotTouch {
  internal var pivotRotation: simd_quatf {
    simd_quaternion(self.pivotAxis, [0, 1, 0])
  }
  /// The pivot component for the entity.
  var pivotTouch: PivotComponent {
    get { self.components[PivotComponent.self] ?? PivotComponent() }
    set { self.components[PivotComponent.self] = newValue }
  }
  /// The pivot axis for the entity.
  var pivotAxis: SIMD3<Float> {
    get { self.pivotTouch.pivotAxis }
    set { self.pivotTouch.pivotAxis = newValue }
  }

  /// Maximum distance away from the center of the object where the pivot touch is active
  var maxPivotDistance: Float? {
    get { self.pivotTouch.maxPivotDistance }
    set { self.pivotTouch.maxPivotDistance = newValue }
  }
  internal var lastGlobalPosition: SIMD3<Float> {
    get { self.pivotTouch.lastGlobalPosition }
    set { self.pivotTouch.lastGlobalPosition = newValue }
  }
}
