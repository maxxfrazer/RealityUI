//
//  RUIAnimations.swift
//  
//
//  Created by Max Cobb on 21/12/2020.
//

import Foundation
import Combine
import RealityKit

public extension Entity {
  /// Spin an Entity on an axis.
  /// - Parameters:
  ///   - axis: Axis on which to rotate around.
  ///   - period: TIme interval for one revolution.
  ///   - times: Number of revolutions. Default is -1, meaning spin forever.
  ///   - completion: Action to take place once the last spin has completed.
  ///                 This will not execute if the animation is interrupted.
  func ruiSpin(
    by axis: SIMD3<Float>, period: TimeInterval,
    times: Int = -1, completion: (() -> Void)? = nil
  ) {
    self.spinPrivate(by: axis, period: period, times: max(-1, times * 3 - 1), completion: completion)
  }
  /// Shake an Entity by a quaternion angle.
  /// - Parameters:
  ///   - quat: Quaternion to add and take away from the entity's starting orientation. Do not use an angle greater than 180º
  ///   - period: Time interval to go from + quat to - quat
  ///   - times: Number of times the entity should go from one side to the other. Adding 0 just goes start -> + quat -> end.
  ///   - completion: Action to take place once the last spin has completed.
  ///                 This will not execute if the animation is interrupted.
  func ruiShake(by quat: simd_quatf, period: TimeInterval, times: Int, completion: (() -> Void)? = nil) {
    let rockBit = matrix_multiply(
      self.transform.matrix,
      Transform(scale: .one, rotation: quat, translation: .zero).matrix
    )
    self.move(to: rockBit, relativeTo: self.parent, duration: period / 2, timingFunction: .easeIn)
    let shakeCancellable = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self, { _ in
      RealityUI.anims[self]?["shake"]?.cancel()
        RealityUI.anims[self]?["shake"] = nil
      self.shakePrivate(
        by: simd_quatf(angle: -quat.angle * 2, axis: quat.axis),
        period: period,
        remaining: times == -1 ? times : max(times * 2 - 1, 0),
        completion: completion
      )
    })
    if RealityUI.anims[self] == nil {
      RealityUI.anims[self] = [:]
    }
    RealityUI.anims[self]?["shake"] = shakeCancellable
  }

  /// Stop all animations on an object, not letting any slip through the net.
  /// A static property of RealityUI stores all animations, as well as a reference to the entity.
  func ruiStopAnim() {
    self.stopAllAnimations()
    RealityUI.anims[self]?.forEach { $0.value.cancel() }
    RealityUI.anims.removeValue(forKey: self)
  }

  private func spinPrivate(
    by axis: SIMD3<Float>, period: TimeInterval,
    times: Int, completion: (() -> Void)? = nil
  ) {
    let startPos = self.transform
    let spun90 = matrix_multiply(
      startPos.matrix,
      Transform(scale: .one, rotation: simd_quatf(angle: 2 * .pi / 3, axis: axis), translation: .zero).matrix
    )
    self.move(
      to: Transform(matrix: spun90),
      relativeTo: self.parent,
      duration: period / 3,
      timingFunction: times == 0 ? .easeOut : .linear)
    let spinCancellable = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self, { _ in
      RealityUI.anims[self]?["spin"]?.cancel()
      RealityUI.anims[self]?.removeValue(forKey: "spin")
      if times != 0 {
        self.spinPrivate(by: axis, period: period, times: max(-1, times - 1), completion: completion)
      } else {
        completion?()
        if RealityUI.anims[self]?.count == 0 { RealityUI.anims.removeValue(forKey: self) }
      }
    })
    if RealityUI.anims[self] == nil {
      RealityUI.anims[self] = [:]
    }
    RealityUI.anims[self]?["spin"] = spinCancellable
  }

  private func shakePrivate(
    by quat: simd_quatf, period: TimeInterval,
    remaining: Int, completion: (() -> Void)? = nil
  ) {
    var applyQuat: simd_quatf!
    if remaining != 0 {
      applyQuat = quat
    } else {
      applyQuat = simd_quatf(angle: quat.angle / 2, axis: quat.axis)
    }
    let rockBit = matrix_multiply(
      self.transform.matrix,
      Transform(scale: .one, rotation: applyQuat, translation: .zero).matrix
    )
    self.move(
      to: rockBit, relativeTo: self.parent,
      duration: remaining == 0 ? period / 2 : period,
      timingFunction: remaining == 0 ? .easeOut : .linear
    )
    var shakeCancellable: Cancellable!
    shakeCancellable = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: self, { _ in
      RealityUI.anims[self]?["shake"]?.cancel()
      RealityUI.anims[self]?.removeValue(forKey: "shake")
      if remaining != 0 {
        let newQuat = simd_quatf(angle: -quat.angle, axis: quat.axis)
        self.shakePrivate(by: newQuat, period: period, remaining: remaining - 1, completion: completion)
      } else {
        completion?()
        if RealityUI.anims[self]?.count == 0 { RealityUI.anims.removeValue(forKey: self) }
      }
    })
    RealityUI.anims[self]?["shake"] = shakeCancellable
  }

}
