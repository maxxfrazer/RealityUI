//
//  RealityUI.swift
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
import Combine

@objc public class RealityUI: NSObject {
  private var componentsRegistered = false
  /// Registers RealityUI's component types. Call this before creating any RealityUI classes to avoid issues.
  /// This method will be automatically called when `ARView.enableRealityUIGestures(_:)` is called,
  public static func registerComponents() {
    RealityUI.shared.logActivated()
  }
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
  
  public enum Gesture {
    case tap
    case pan
    case all
  }

  public struct RUIGesture: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    public static let tap = RUIGesture(rawValue: 1 << 0)
    public static let pan = RUIGesture(rawValue: 1 << 1)

    public static let all: RUIGesture = [.tap, .pan]
  }
  public internal(set) var enabledGestures: RUIGesture = []
  public static var RUIComponents: [Component.Type] = [
    RUIComponent.self,
    SwitchComponent.self,
    SliderComponent.self
  ]
  internal static var shared = RealityUI()
  private override init() {
    super.init()
    self.registerComponents()
  }

  internal func enable(gestures: RealityUI.RUIGesture, on arView: ARView) {
    /// - TODO: This method is gross, I tried to use `OptionSet` and think I'm doing it wrong
    /// These multiple if statements make me feel shame.
    let newGestures = gestures.subtracting(self.enabledGestures)
    if newGestures.isEmpty { return }
    if newGestures.contains(.tap) {
      self.addTap(to: arView)
    }
    if newGestures.contains(.pan) {
      self.addLongTouch(to: arView)
    }
    self.enabledGestures.formUnion(newGestures)
  }
  private func addTap(to arView: ARView) {
    #if os(iOS)
    let addUITapGesture = UITapGestureRecognizer(target: self, action:  #selector(self.tapReco))
    arView.addGestureRecognizer(addUITapGesture)
    #elseif os(macOS)
    let addUITapGesture = NSClickGestureRecognizer(target: self, action: #selector(self.clickReco))
    arView.addGestureRecognizer(addUITapGesture)

    #endif
  }
  private func addLongTouch(to arView: ARView) {
    #if os(macOS)
    RealityUI.RUIPrint("RealityUI: long touch gesture not yet working on macOS")
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
    if let ht = arView.hitTest(tapInView).first, let tappedEntity = ht.entity as? HasClick, tappedEntity.ruiEnabled {
      let htPos = ht.position
      tappedEntity.onTap(worldCollision: htPos)
    }
  }
  #elseif os(iOS)
    @objc internal func tapReco(sender: UITapGestureRecognizer? = nil) {
    guard let arView = sender?.view as? ARView, let tapInView = sender?.location(in: arView) else {
      return
    }
    if let ht = arView.hitTest(tapInView).first, let tappedEntity = ht.entity as? HasClick, tappedEntity.ruiEnabled {
      let htPos = ht.position
      tappedEntity.onTap(worldCollision: htPos)
    }
  }
  #endif
}

public struct RUIComponent: Component {
  public internal(set) var ruiEnabled: Bool
  public internal(set) var respondsToLighting: Bool
  public init(enabled: Bool = true, respondsToLighting: Bool = false) {
    self.ruiEnabled = enabled
    self.respondsToLighting = respondsToLighting
  }
}

public protocol HasRUI: Entity {
  /// All RealityUI Entities should have a method for updating all the materials
  /// This is in case of disabling entities or changing their responsiveness to light
  func updateMaterials() -> Void
}
public extension HasRUI {
  /// A Boolean value that determines whether touch events are ignored on this RealityUI Entity
  var ruiEnabled: Bool {
    get { self.RUI.ruiEnabled }
    set {
      if self.RUI.ruiEnabled == newValue { return }
      self.RUI.ruiEnabled = newValue
      self.materialsShouldChange()
    }
  }

  /// A Boolean value that determines whether this Entity's materials respond to lighting
  var respondsToLighting: Bool {
    get { self.RUI.respondsToLighting }
    set {
      if self.RUI.respondsToLighting == newValue { return }
      self.RUI.respondsToLighting = newValue
      self.materialsShouldChange()
    }
  }

  func replaceRUI(with RUI: RUIComponent) {
    self.RUI = RUI
    self.materialsShouldChange()
  }

  internal(set) var RUI: RUIComponent {
    get {
      if let ruiComp = self.components[RUIComponent.self] as? RUIComponent {
        return ruiComp
      } else {
        self.components[RUIComponent.self] = RUIComponent()
        return self.components[RUIComponent.self]!
      }
    }
    set {
      self.components[RUIComponent.self] = newValue
    }
  }

  private func materialsShouldChange() {
    self.updateMaterials()
  }
}
internal extension HasRUI {
  func getMaterial(with color: Material.Color) -> Material {
    let adjustedColor = color.withAlphaComponent(self.ruiEnabled ? 1 : 0.5)
    if self.RUI.respondsToLighting {
      return SimpleMaterial(color: adjustedColor, isMetallic: false)
    }
    return UnlitMaterial(color: adjustedColor)
  }

  func getModel(part: String) -> ModelEntity? {
    self.findEntity(named: part) as? ModelEntity
  }
  func addModel(part: String) -> ModelEntity {
    if let mp = self.getModel(part: part) {
      return mp
    }
    let mp = ModelEntity()
    mp.name = part
    self.addChild(mp)
    return mp
  }
}

public extension ARView {
  /// Use this method on your ARView to add GestureRecognisers for different RealityKit elements in your scene.
  /// You do not need multiple GestureRecognisers for multiple elements in the scene.
  /// - Parameter gestures: A list of gestures to be installed, such as .pan and .tap
  func enableRealityUIGestures(_ gestures: RealityUI.RUIGesture) {
    RealityUI.shared.enable(gestures: gestures, on: self)
  }
}
