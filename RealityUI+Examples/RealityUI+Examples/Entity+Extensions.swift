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

internal extension Entity {
  func spin(in axis: SIMD3<Float>, duration: TimeInterval, repeats: Bool = true) {
    let spun180 = matrix_multiply(
      self.transform.matrix,
      Transform(scale: .one, rotation: .init(angle: .pi / 2, axis: axis), translation: .zero).matrix
    )
    self.move(
      to: Transform(matrix: spun180),
      relativeTo: self.parent,
      duration: duration / 4,
      timingFunction: .linear)
    var spinCancellable: Cancellable!
    spinCancellable = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self, { _ in
      spinCancellable.cancel()
      if repeats {
        self.spin(in: axis, duration: duration, repeats: repeats)
      }
    })
  }
}
