//
//  RUILongTouchGestureRecognizer.swift
//
//
//  Created by Max Cobb on 5/16/20.
//

import RealityKit
#if os(iOS)
import UIKit
typealias LongGestureBase = UIGestureRecognizer
#elseif os(macOS)
import AppKit
typealias LongGestureBase = NSGestureRecognizer
#endif
import Combine

public protocol HasARTouch: HasRUI, HasCollision {
  func arTouchStarted(_ worldCoordinate: SIMD3<Float>)
  func arTouchUpdated(_ worldCoordinate: SIMD3<Float>)
  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?)
}

internal extension HasARTouch {
  var collisonPlane: float4x4 {
    return self.transformMatrix(relativeTo: nil)
      * float4x4(simd_quatf(angle: .pi / 2, axis: [1, 0, 0]))
  }
}


/// This Gesture is used currently for panning gestures, but is named LongTouch
/// As the plan is for it to be used for other AR Gestures.
@objc internal class RUILongTouchGestureRecognizer : LongGestureBase {
  let arView: ARView


  #if os(iOS)
  fileprivate var activeTouch: UITouch?
  #endif

  var collisionStart: SIMD3<Float>?
  var hitEntity: HasARTouch?
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

  func globalTouchBegan(touchInView: CGPoint) {
    guard let hitPanEntity = self.arView.entity(at: touchInView) as? HasARTouch,
      hitPanEntity.ruiEnabled else {
        return
    }
    self.touchLocation = touchInView
    self.hitEntity = hitPanEntity
    let colPlane = hitPanEntity.collisonPlane
    self.collisionPlane = colPlane
    guard let planeCollisionPoint = self.arView.unproject(touchInView, ontoPlane: colPlane) else {
      return
    }
    hitPanEntity.arTouchStarted(planeCollisionPoint)
    self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updatePan(_:))
  }

  func updatePan(_ event: SceneEvents.Update) {
    guard let touchLocation = self.touchLocation,
      let collisionPlane = self.collisionPlane,
      let hitEntity = self.hitEntity,
      let newPos = self.arView.unproject(touchLocation, ontoPlane: collisionPlane)
      else {
        return
    }
    hitEntity.arTouchUpdated(newPos)
  }
}

#if os(iOS)
extension RUILongTouchGestureRecognizer {
  open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    guard activeTouch == nil,
      let firstTouch = touches.first,
      let touchInView = touches.first?.location(in: self.arView),
      self.arView.frame.contains(touchInView)
      else {
        return
    }
    self.activeTouch = firstTouch
    globalTouchBegan(touchInView: touchInView)
  }
  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    if hitEntity == nil, let activeTouch = self.activeTouch, !touches.contains(activeTouch) {
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
  }

  open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    self.touchesEnded(touches, with: event)
  }
  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let activeTouch = self.activeTouch, touches.contains(activeTouch) else {
      return
    }
    self.hitEntity?.arTouchEnded(nil)
    self.hitEntity = nil
    self.touchLocation = nil
    self.activeTouch = nil
    self.viewSubscriber?.cancel()
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
      globalTouchBegan(touchInView: touchInView)
    }
    override func mouseDragged(with event: NSEvent) {
      if hitEntity == nil, self.touchLocation == nil {
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
      self.hitEntity?.arTouchEnded(nil)
      self.hitEntity = nil
      self.touchLocation = nil
      self.viewSubscriber?.cancel()
    }
}
#endif
