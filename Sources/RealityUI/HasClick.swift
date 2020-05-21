//
//  HasClick.swift
//
//
//  Created by Max Cobb on 5/16/20.
//

import RealityKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public protocol HasClick: HasRUI, HasCollision {
  var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? {get set}
}
internal extension HasClick {
  func onTap(worldCollision: SIMD3<Float>? = nil) {
    self.tapAction?(self, worldCollision)
  }
}

