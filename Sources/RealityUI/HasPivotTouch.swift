//
//  HasPivotTouch.swift
//
//
//  Created by Max Cobb on 5/31/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// This is an experimental feature, full functionality has not yet been decided.
/// Hence no documentation yet.
public protocol HasPivotTouch: HasPanTouch {}

public extension HasPivotTouch {
  var collisionPlane: float4x4? {
    return self.transformMatrix(relativeTo: nil)
      * float4x4(pivotRotation)
  }

  func arTouchStarted(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool) {
    self.lastGlobalPosition = worldCoordinate
  }
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

public struct PivotComponent: Component {
  internal var lastTouchAngle: Float?
  internal var lastGlobalPosition: SIMD3<Float> = .zero
  public var pivotAxis: SIMD3<Float>
  public var maxPivotDistance: Float?
    public init(pivotAxis: SIMD3<Float> = [0, 1, 0], maxPivotDistance: Float? = nil) {
    self.pivotAxis = pivotAxis
    self.maxPivotDistance = maxPivotDistance
  }
}

public extension HasPivotTouch {
  var pivotRotation: simd_quatf {
    simd_quaternion(self.pivotAxis, [0, 1, 0])
  }
  var pivotTouch: PivotComponent {
    get { self.components[PivotComponent.self] ?? PivotComponent() }
    set { self.components[PivotComponent.self] = newValue }
  }
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
