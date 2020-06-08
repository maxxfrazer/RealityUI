//
//  RealityUI.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
import Combine

@objc public class RealityUI: NSObject {
  private var componentsRegistered = false
  /// Registers RealityUI's component types. Call this before creating any RealityUI classes to avoid issues.
  /// This method will be automatically called when `ARView.enableRealityUIGestures(_:)` is called,
  public static func registerComponents() {
    RealityUI.shared.logActivated()
  }
  public static var longGestureMask: CollisionGroup = .all
  public static var tapGestureMask: CollisionGroup = .all
  private func logActivated() {
    RealityUI.RUIPrint("RealityUI: Activated, registered components")
  }
  internal static func RUIPrint(_ message: String) {
    print("RealityUI: \(message)")
  }
  private func registerComponents() {
    if self.componentsRegistered {
      return
    }
    for comp in RealityUI.RUIComponents {
      comp.registerComponent()
    }
  }

  public struct RUIGesture: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    public static let tap = RUIGesture(rawValue: 1 << 0)

    /// For now, longTouch is used for RealityUI gestures that are more complex than a simple tap
    public static let longTouch = RUIGesture(rawValue: 1 << 1)

    public static let all: RUIGesture = [.tap, .longTouch]
  }
  public internal(set) var enabledGestures: RUIGesture = []

  /// All the components used by RealityUI
  public static var RUIComponents: [Component.Type] = [
    RUIComponent.self,
    ButtonComponent.self,
    SwitchComponent.self,
    StepperComponent.self,
    SliderComponent.self,
    PivotComponent.self
  ]

  internal static var shared = RealityUI()

  private override init() {
    super.init()
    self.registerComponents()
  }

  internal func enable(gestures: RealityUI.RUIGesture, on arView: ARView) {
    /// This method is gross, I tried to use `OptionSet` and think I'm doing it wrong
    /// These multiple if statements make me feel uncomfortable.
    let newGestures = gestures.subtracting(self.enabledGestures)
    if newGestures.isEmpty { return }
    if newGestures.contains(.tap) {
      self.addTap(to: arView)
    }
    if newGestures.contains(.longTouch) {
      self.addLongTouch(to: arView)
    }
    self.enabledGestures.formUnion(newGestures)
  }
  private func addTap(to arView: ARView) {
    #if os(iOS)
    let addUITapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapReco))
    arView.addGestureRecognizer(addUITapGesture)
    #elseif os(macOS)
    let addUITapGesture = NSClickGestureRecognizer(target: self, action: #selector(self.clickReco))
    arView.addGestureRecognizer(addUITapGesture)

    #endif
  }
  private func addLongTouch(to arView: ARView) {
    #if os(macOS)
    RealityUI.RUIPrint("RealityUI: long touch gesture not fully working on macOS")
    #endif
    let longTouchGesture = RUILongTouchGestureRecognizer(target: nil, action: nil, view: arView)
    arView.addGestureRecognizer(longTouchGesture)
  }

  #if os(macOS)
  @objc internal func clickReco(sender: NSGestureRecognizer) {
    guard let arView = sender.view as? ARView else {
      return
    }
    let tapInView = sender.location(in: arView)
    if let ccHit = arView.hitTest(tapInView, mask: RealityUI.tapGestureMask).first,
      let tappedEntity = ccHit.entity as? HasClick, tappedEntity.ruiEnabled {
      tappedEntity.onTap(worldCollision: ccHit.position)
    }
  }
  #elseif os(iOS)
    @objc internal func tapReco(sender: UITapGestureRecognizer? = nil) {
      guard let arView = sender?.view as? ARView, let tapInView = sender?.location(in: arView) else {
        return
      }
      if let ccHit = arView.hitTest(tapInView, mask: RealityUI.tapGestureMask).first,
        let tappedEntity = ccHit.entity as? HasClick, tappedEntity.ruiEnabled {
      tappedEntity.onTap(worldCollision: ccHit.position)
    }
  }
  #endif
}

public extension ARView {
  /// Use this method on your ARView to add GestureRecognisers for different RealityKit elements in your scene.
  /// You do not need multiple GestureRecognisers for multiple elements in the scene.
  /// - Parameter gestures: A list of gestures to be installed, such as .pan and .tap
  func enableRealityUIGestures(_ gestures: RealityUI.RUIGesture) {
    RealityUI.shared.enable(gestures: gestures, on: self)
  }
}
