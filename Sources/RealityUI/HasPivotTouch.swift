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

public struct PivotComponent: Component {
  internal var lastTouchAngle: Float?
  internal var lastGlobalPosition: SIMD3<Float> = .zero
  public var pivotAxis: SIMD3<Float>
  public init(pivot: SIMD3<Float> = [0, 1, 0]) {
    self.pivotAxis = pivot
  }
}

internal extension HasPivotTouch {
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
  var lastGlobalPosition: SIMD3<Float> {
    get { self.pivotTouch.lastGlobalPosition }
    set { self.pivotTouch.lastGlobalPosition = newValue }
  }
}
