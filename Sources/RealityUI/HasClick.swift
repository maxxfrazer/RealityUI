//
//  HasClick.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// An interface used for entities which have actions upon being clicked
public protocol HasClick: HasRUI, HasCollision {
  /// Action to be applied on successfully tapping an Entity.
  var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? {get set}
}
internal extension HasClick {
  func onTap(worldCollision: SIMD3<Float>? = nil) {
    self.tapAction?(self, worldCollision)
  }
}
