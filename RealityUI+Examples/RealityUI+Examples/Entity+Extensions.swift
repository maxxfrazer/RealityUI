//
//  Entity+Extensions.swift
//  RealityUI+Examples
//
//  Created by Max Cobb on 5/24/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import Foundation
import Combine
import RealityUI

internal extension Entity {
  func spin(in axis: SIMD3<Float>, duration: TimeInterval, repeats: Bool = true) {
      self.ruiSpin(by: axis, period: duration, times: -1)
  }
}
