//
//  RealityUI.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import Foundation
#if os(iOS)
import UIKit.UIGestureRecognizer
#elseif os(macOS)
import AppKit
#endif

import Combine

/// RealityUI contains some properties for RealityUI to run in your application.
/// ![RealityUI Banner](https://repository-images.githubusercontent.com/265939509/77c8eb00-a362-11ea-995e-482183f9acbd)
@objc public class RealityUI: NSObject {
  internal var componentsRegistered = false

  /// Registers RealityUI's component types. Call this before creating any RealityUI classes to avoid issues.
  /// This method will be automatically called when `ARView.enableRealityUIGestures(_:)` is called,
  public static func registerComponents() {
    RealityUI.shared.logActivated()
  }
  /// Orientation of all RealityUI Entities upon creation. If nil, none will be set.
  public static var startingOrientation: simd_quatf?

  /// Mask to exclude entities from being hit by the long/panning gesture
  public static var longGestureMask: CollisionGroup = .all

  /// Mask to exclude entities from being hit by the tap gesture.
  public static var tapGestureMask: CollisionGroup = .all

  /// Store all the RealityUI Animations for an Entity. It's important for memory management that this is empty when it should be.
  internal static var anims: [Entity: [String: Cancellable]] = [:]
  /// Use this to add GestureRecognisers for different RealityUI elements in your scene.
  /// You do not need multiple GestureRecognisers for multiple elements in the scene.
  /// - Parameters:
  ///   - gestures: A list of gestures to be installed, such as .longTouch and .tap
  ///   - arView: ARView the gestures will be enabled on
  public static func enableGestures(_ gestures: RealityUI.RUIGesture, on arView: ARView) {
    RealityUI.shared.enable(gestures: gestures, on: arView)
  }

  private func logActivated() {
    RealityUI.RUIPrint("Activated, registered components")
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
    self.componentsRegistered = true
  }

  /// Different type of gestures used by RealityUI and set to an ARView object.
  public struct RUIGesture: OptionSet {
    /// Integer raw value used by the OptionSet
    public let rawValue: Int

    /// Initialise a new option set
    /// - Parameter rawValue: Integer raw value used by the OptionSet
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// OptionSet value for tap gestures.
    public static let tap = RUIGesture(rawValue: 1 << 0)

    /// OptionSet value for long touch gestures.
    public static let longTouch = RUIGesture(rawValue: 1 << 1)

    /// Encapsulates all the possible values of this OptionSet
    public static let all: RUIGesture = [.tap, .longTouch]
  }

  /// Gestures that have been enalbed, `.tap`, `.longTouch` etc
  public internal(set) var enabledGestures: [ARView: RUIGesture] = [:]

  /// Gestures that have been installed. Plan to expose this property later.
  private var installedGestures: [ARView: [GestureBase]] = [:]

  /// All the components used by RealityUI
  public static var RUIComponents: [Component.Type] = [
    RUIComponent.self,
    ButtonComponent.self,
    SwitchComponent.self,
    StepperComponent.self,
    SliderComponent.self,
    TurnComponent.self,
    TextComponent.self
  ]

  internal static var shared = RealityUI()

  private override init() {
    super.init()
    self.registerComponents()
  }

  fileprivate func enable(gestures: RealityUI.RUIGesture, on arView: ARView) {
    /// This method is gross, I tried to use `OptionSet` and think I'm doing it wrong
    /// These multiple if statements make me feel uncomfortable.
    if !self.enabledGestures.contains(where: { $0.key == arView}) {
      self.enabledGestures[arView] = []
    }
    let newGestures = gestures.subtracting(self.enabledGestures[arView] ?? [])
    if newGestures.isEmpty { return }
    if newGestures.contains(.tap) {
      self.addTap(to: arView)
    }
    if newGestures.contains(.longTouch) {
      self.addLongTouch(to: arView)
    }
    self.enabledGestures[arView]?.formUnion(newGestures)
  }
  private func addTap(to arView: ARView) {
    #if os(iOS)
    let addUITapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapReco))
    #elseif os(macOS)
    let addUITapGesture = NSClickGestureRecognizer(target: self, action: #selector(self.clickReco))
    #endif
    arView.addGestureRecognizer(addUITapGesture)
    self.installedGestures[arView]?.append(addUITapGesture)
  }
  private func addLongTouch(to arView: ARView) {
    let longTouchGesture = RUILongTouchGestureRecognizer(
      target: self, action: #selector(self.arTouchReco),
      view: arView
    )
    arView.addGestureRecognizer(longTouchGesture)
    self.installedGestures[arView]?.append(longTouchGesture)
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

  @objc internal func arTouchReco(sender: RUILongTouchGestureRecognizer) {}
}

public extension ARView {
  /// Use this method on your ARView to add GestureRecognisers for different RealityKit elements in your scene.
  /// You do not need multiple GestureRecognisers for multiple elements in the scene.
  /// - Parameter gestures: A list of gestures to be installed, such as .longTouch and .tap
  @available(*, deprecated, message: "Instead call RealityUI.enableGestures(:)")
  func enableRealityUIGestures(_ gestures: RealityUI.RUIGesture) {
    RealityUI.shared.enable(gestures: gestures, on: self)
  }
}
