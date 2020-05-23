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

public protocol HasARTouch: HasRUI, HasCollision {}

public protocol HasPanTouch: HasARTouch {
  func arTouchStarted(_ worldCoordinate: SIMD3<Float>)
  func arTouchUpdated(_ worldCoordinate: SIMD3<Float>)
  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?)
}

internal extension HasPanTouch {
  var collisonPlane: float4x4 {
    return self.transformMatrix(relativeTo: nil)
      * float4x4(simd_quatf(angle: .pi / 2, axis: [1, 0, 0]))
  }
}

public protocol HasTouchUpInside: HasARTouch {
  func arTouchStarted(hasCollided: Bool, _ worldCoordinate: SIMD3<Float>)
  func arTouchUpdated(hasCollided: Bool, _ worldCoordinate: SIMD3<Float>?)
  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?)
}


/// This Gesture is currently used for any gesture other than simple taps.
@objc internal class RUILongTouchGestureRecognizer : LongGestureBase {
  let arView: ARView


  #if os(iOS)
  fileprivate var activeTouch: UITouch?
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
    guard let hitPanEntity = self.arView.entity(at: touchInView) else {
        return false
    }
    if let arTouch = hitPanEntity as? HasPanTouch {
      self.touchesBeganARTouch(hitEntity: arTouch, touchInView: touchInView)
    } else if let upInsideEntity = hitPanEntity as? HasTouchUpInside {
      self.touchesBeganUpInside(hitEntity: upInsideEntity, touchInView: touchInView)
    } else {
      return false
    }
    return true
  }
  func touchesBeganUpInside(hitEntity: HasTouchUpInside, touchInView: CGPoint) {
    let ht = self.arView.hitTest(touchInView, query: .nearest, mask: .all)
    if let fht = ht.first, fht.entity == hitEntity {
      self.touchLocation = touchInView
      self.entity = hitEntity
      hitEntity.arTouchStarted(hasCollided: true, fht.position)
      self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updateTouchInside(_:))
    }
  }
  func touchesBeganARTouch(hitEntity: HasPanTouch, touchInView: CGPoint) {
    if !hitEntity.ruiEnabled {
      return
    }
    self.touchLocation = touchInView
    self.entity = hitEntity
    let colPlane = hitEntity.collisonPlane
    self.collisionPlane = colPlane
    guard let planeCollisionPoint = self.arView.unproject(touchInView, ontoPlane: colPlane) else {
      return
    }
    hitEntity.arTouchStarted(planeCollisionPoint)
    self.viewSubscriber = self.arView.scene.subscribe(to: SceneEvents.Update.self, updatePan(_:))
  }

  func updatePan(_ event: SceneEvents.Update) {
    guard let touchLocation = self.touchLocation,
      let collisionPlane = self.collisionPlane,
      let hitEntity = self.entity,
      let newPos = self.arView.unproject(touchLocation, ontoPlane: collisionPlane)
      else {
        return
    }
    #if os(iOS)
    if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
      self.touchesEnded([activeTouch], with: UIEvent())
      return
    }
    #endif
    (hitEntity as? HasPanTouch)?.arTouchUpdated(newPos)
  }

  func updateTouchInside(_ event: SceneEvents.Update) {
    guard let touchLocation = self.touchLocation,
      let hitEntity = self.entity as? HasTouchUpInside
      else {
        return
    }
    #if os(iOS)
    if let activeTouch = self.activeTouch, activeTouch.phase == .ended {
      self.touchesEnded([activeTouch], with: UIEvent())
      return
    }
    #endif
    let htResult = self.arView.hitTest(touchLocation, query: .nearest, mask: .all).first
    let hitPos = htResult?.entity == hitEntity ? htResult?.position : nil
    hitEntity.arTouchUpdated(
      hasCollided: htResult?.entity == hitEntity, hitPos
    )
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
        if let activeTouch = self.activeTouch {
          self.touchesCancelled([activeTouch], with: event)
        }
        return
    }
    self.activeTouch = firstTouch
    if !globalTouchBegan(touchInView: touchInView) {
      self.touchesCancelled(touches, with: event)
    }
  }
  open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    print("in touches moved")
    guard let activeTouch = self.activeTouch else {
      return
    }
    print("active touch not nil")
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
  }

  open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    print("cancelled!")
    self.touchesEnded(touches, with: event)
  }

  open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let activeTouch = self.activeTouch, touches.contains(activeTouch) else {
      return
    }
    self.activeTouch = nil
    guard self.touchLocation != nil else {
      return
    }
    self.touchLocation = nil
    if let arTouchEntity = entity as? HasPanTouch {
      arTouchEntity.arTouchEnded(nil)
    } else if let upInsideEntity = entity as? HasTouchUpInside {
      upInsideEntity.arTouchEnded(nil)
    } else {
      RealityUI.RUIPrint("Could not find class for entity in touchesEnded")
    }
    self.entity = nil
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
      if let arTouchEntity = entity as? HasPanTouch {
        arTouchEntity.arTouchEnded(nil)
      } else if let upInsideEntity = entity as? HasTouchUpInside {
        upInsideEntity.arTouchEnded(nil)
      } else {
        RealityUI.RUIPrint("Could not find class for entity in mosueUp")
      }
      self.entity = nil
      self.viewSubscriber?.cancel()
    }
}
#endif
