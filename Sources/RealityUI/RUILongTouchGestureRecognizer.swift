//
//  RUILongTouchGestureRecognizer.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
#if os(iOS)
import UIKit
/// Typealias to easily access UIGestureRecognizer and NSGestureRecognizer on iOS and macOS respectively
public typealias GestureBase = UIGestureRecognizer
#elseif os(macOS)
import AppKit
/// Typealias to easily access UIGestureRecognizer and NSGestureRecognizer on iOS and macOS respectively
public typealias GestureBase = NSGestureRecognizer
#endif
import Combine

/// An interface used for RealityUI entities which respond to gestures beyond just a tap.
/// ie: panning gestures
public protocol HasARTouch: HasRUI, HasCollision {
  /// Called when a new touch has begun on an Entity
  /// - Parameters:
  ///   - worldCoordinate: Collision of the object or collision plane
  ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
  func arTouchStarted(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool)

  /// Called when a touch is still on screen or a mouse is still down.
  /// - Parameters:
  ///   - worldCoordinate: Where is the touch currently hits in world space
  ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
  func arTouchUpdated(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool)

  /// Touch has ended without issues.
  /// - Parameter worldCoordinate: Coordinate in world space where the released collision came from
  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?)

  /// Called when touch has been interrupted.
  func arTouchCancelled()

  /// Plane to continue touches with, used for RUISlider + Others
  /// Return nil to just use the Entity `CollisionComponent`
  var collisionPlane: float4x4? { get }
}

extension HasARTouch {
}

/// An interface used for all entities that have long touches where movement
/// is the main interest (vs HasTouchUpInside)
public protocol HasPanTouch: HasARTouch {}

public extension HasPanTouch {}

/// An interface used for all entities that have long touches where movement
/// is is not the main interest (vs HasPanTouch)
public protocol HasTouchUpInside: HasARTouch {}

/// This Gesture is currently used for any gesture other than simple taps.
@objc internal class RUILongTouchGestureRecognizer: GestureBase {
  let arView: ARView

  #if os(iOS)
  internal var activeTouch: UITouch?
  #endif

  var collisionStart: SIMD3<Float>?
  // Possible types: HasPanTouch, HasTouchUpInside
  var entity: HasARTouch?

  var touchLocation: CGPoint?
  var viewSubscriber: Cancellable?
  var collisionPlane: float4x4?

  public init(target: Any?, action: Selector?, view: ARView) {
    self.arView = view
    super.init(target: target, action: action)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func globalTouchBegan(touchInView: CGPoint) -> Bool {
    guard let firstHit = self.arView.hitTest(
      touchInView, query: .nearest, mask: RealityUI.longGestureMask
    ).first, let hitEntity = firstHit.entity as? HasARTouch else {
        return false
    }
    self.touchesBeganARTouch(hitEntity: hitEntity, touchInView: touchInView, touchInWorld: firstHit.position)
    return true
  }

  func touchesBeganARTouch(
    hitEntity: HasARTouch, touchInView: CGPoint, touchInWorld: SIMD3<Float>
  ) {
    if !hitEntity.ruiEnabled {
      return
    }
    self.touchLocation = touchInView
    self.entity = hitEntity
    var worldTouch = touchInWorld
    if let collisionPlane = hitEntity.collisionPlane {
      self.collisionPlane = collisionPlane
      if let planeCollisionPoint = self.arView.unproject(
        touchInView, ontoPlane: collisionPlane
      ) {
        if let maxDist = (hitEntity as? HasTurnTouch)?.maxDistance {
          let convPoint = hitEntity.convert(position: planeCollisionPoint, from: nil)
          if convPoint.magnitude > maxDist {
            return
          }
        }
        worldTouch = planeCollisionPoint
      } else {
        return
      }
    }
    hitEntity.arTouchStarted(worldTouch, hasCollided: true)
    self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateRUILongTouch(_:))
  }

  func updateRUILongTouch(_ event: SceneEvents.Update?) {
    guard let touchLocation = self.touchLocation,
      let hitEntity = self.entity
      else {
        return
    }
    var newPos: SIMD3<Float>?
    var hasCollided = false
    if let htResult = self.arView.hitTest(
    touchLocation, query: .nearest, mask: RealityUI.longGestureMask
      ).first {
      hasCollided = htResult.entity == self.entity
      if self.collisionPlane == nil {
        newPos = htResult.position
      }
    }
    if let collisionPlane = self.collisionPlane {
      newPos = self.arView.unproject(touchLocation, ontoPlane: collisionPlane)
    }
    #if os(iOS)
    if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
      self.touchesEnded([activeTouch], with: UIEvent())
      return
    }
    #endif
    hitEntity.arTouchUpdated(newPos ?? .zero, hasCollided: hasCollided)
  }
}

#if os(iOS)
internal extension RUILongTouchGestureRecognizer {
  /// Sent to the gesture recognizer when one or more fingers touch down in the associated view.
  /// - Parameters:
  ///   - touches: A set of UITouch instances in the event represented by event that represent the touches in the UITouch.Phase.began phase.
  ///   - event: A `UIEvent` object representing the event to which the touches belong.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    guard activeTouch == nil,
      let firstTouch = touches.first,
      let touchInView = touches.first?.location(in: self.arView),
      self.arView.frame.contains(touchInView)
      else {
        if let activeTouch = self.activeTouch {
          self.touchesCancelled([activeTouch], with: event)
        }
        return
    }
    if touches.count > 1 {
      self.touchesCancelled(touches, with: event)
      return
    }
    self.activeTouch = firstTouch
    if !globalTouchBegan(touchInView: touchInView) {
      self.touchesCancelled(touches, with: event)
      return
    }
    super.touchesBegan(touches, with: event)
    self.state = .began
  }
  /// Sent to the gesture recognizer when one or more fingers move in the associated view.
  /// - Parameters:
  ///   - touches: A set of `UITouch` instances in the event represented by event that represent touches in the `UITouch.Phase.moved` phase.
  ///   - event: A `UIEvent` object representing the event to which the touches belong.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let activeTouch = self.activeTouch else {
      return
    }
    if entity == nil || !touches.contains(activeTouch) {
      return
    }

    guard let touchInView = self.activeTouch?.location(in: self.arView),
      self.arView.frame.contains(touchInView)
      else {
        return
    }
    if touchInView == self.touchLocation {
      return
    }
    self.touchLocation = touchInView
    super.touchesMoved(touches, with: event)
    self.state = .changed
  }

  /// Sent to the gesture recognizer when a system event (such as an incoming phone call) cancels a touch event.
  /// - Parameters:
  ///   - touches: A set of `UITouch` instances in the event represented by event that represent the touches in the `UITouch.Phase.cancelled` phase.
  ///   - event: A `UIEvent` object representing the event to which the touches belong.
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    self.clearTouch(touches, with: event, state: .cancelled)
  }

  /// Sent to the gesture recognizer when one or more fingers lift from the associated view.
  /// - Parameters:
  ///   - touches: A set of `UITouch` instances in the event represented by event that represent the touches in the `UITouch.Phase.ended` phase.
  ///   - event: A `UIEvent` object representing the event to which the touches belong.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    self.clearTouch(touches, with: event, state: .ended)
  }

  private func clearTouch(_ touches: Set<UITouch>, with event: UIEvent, state: UIGestureRecognizer.State) {
    guard let activeTouch = self.activeTouch, touches.contains(activeTouch) else {
      return
    }
    self.activeTouch = nil
    guard self.touchLocation != nil else {
      return
    }
    self.touchLocation = nil
    switch state {
    case .cancelled:
      entity?.arTouchCancelled()
      super.touchesCancelled(touches, with: event)
    case .ended:
      entity?.arTouchEnded(nil)
      super.touchesEnded(touches, with: event)
    default:
      break
    }
    self.entity = nil
    self.viewSubscriber?.cancel()
    self.state = state
  }
}
#endif

#if os(macOS)
extension RUILongTouchGestureRecognizer {
    override func mouseDown(with event: NSEvent) {
      guard self.touchLocation == nil
        else {
          return
      }
      let touchInView = self.arView.convert(event.locationInWindow, from: event.window?.contentView)
  //    self.activeTouch = touches.first
      if !globalTouchBegan(touchInView: touchInView) {
        self.mouseUp(with: event)
        return
      }
      super.mouseDown(with: event)
    }
    override func mouseDragged(with event: NSEvent) {
      if entity == nil || self.touchLocation == nil {
        return
      }

      let touchInView = self.arView.convert(event.locationInWindow, from: event.window?.contentView)

      if touchInView == self.touchLocation {
        return
      }
      self.touchLocation = touchInView
    }
    override func mouseUp(with event: NSEvent) {
      guard self.touchLocation != nil else {
        return
      }
      self.touchLocation = nil
      entity?.arTouchEnded(nil)
      self.entity = nil
      self.viewSubscriber?.cancel()
    }
}
#endif

fileprivate extension SIMD where Self.Scalar: FloatingPoint {
  var magnitude: Self.Scalar {
    var sqSum: Self.Scalar = 0
    for indice in self.indices {
      sqSum += self[indice] * self[indice]
    }
    return sqrt(sqSum)
  }
}
