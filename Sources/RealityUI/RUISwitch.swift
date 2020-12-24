//
//  RUISwitch.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// A  RealityUI Switch to be added to a RealityKit scene.
public class RUISwitch: Entity, HasSwitch, HasClick {
  public var tapAction: (
    (HasClick, SIMD3<Float>?) -> Void
    )? = { tapthing, _ in
      guard let toggleObj = (tapthing as? RUISwitch) else {
        return
      }
      toggleObj.setOn(!toggleObj.isOn)
  }

  /// Switch's isOn property has changed
  public var switchChanged: ((HasSwitch) -> Void)?

  /// Creates a RealityUI Switch entity with optional `SwitchComponent`, `RUIComponent` and `changedCallback`.
  /// - Parameters:
  ///   - switchness: Details about the switch to be set when initialized.
  ///   - RUI: Details about the RealityUI Entity
  ///   - changedCallback: callback function to receive updates when the switch isOn property changes.
  public init(
    switchness: SwitchComponent? = nil,
    RUI: RUIComponent? = nil,
    changedCallback: ((HasSwitch) -> Void)? = nil
  ) {
    super.init()
    self.RUI = RUI ?? RUIComponent()
    self.switchness = switchness ?? SwitchComponent()
    self.ruiOrientation()
    self.makeModels()
    self.switchChanged = changedCallback
  }

  /// Create a RUISwitch entity with the default styling.
  required public convenience init() {
    self.init(switchness: SwitchComponent())
  }
}

/// An interface used for all entities that have a toggling option
public protocol HasSwitch: HasRUIMaterials {
  /// Switch's isOn property has changed
  var switchChanged: ((HasSwitch) -> Void)? { get set }
}

/// A collection of resources that create the visual appearance a RealityUI Switch, `RUISwitch`.
public struct SwitchComponent: Component {
  /// A Boolean value that determines the off/on state of the switch. Default to `false`, meaning off.
  var isOn: Bool
  /// Padding (in meters) between the thumb and the inner capsule of the switch. Default 0.05.
  let padding: Float
  /// Border (in meters) between the two outer capsules of the switch. No border if set to 0. Default 0.05.
  let border: Float
  /// Color of the inner capsule when the switch is set to `off`. Default `Material.Color.systemGreen`
  let onColor: Material.Color
  /// Color of the inner capsule when the switch is set to `on`. Default `Material.Color.lightGray`
  let offColor: Material.Color
  /// Color of the outer border. Default `Material.Color.black`
  let borderColor: Material.Color
  /// Color of the thumb. Default white.
  let thumbColor: Material.Color
  /// Length of the toggle, not customisable for now.
  internal let length: Float = 55 / 34
  enum UIPart: String {
    case thumb
    case background
    case border
  }

  /// Creates a SwitchComponent using a list of completely optional parameters.
  /// - Parameters:
  ///   - isOn: A Boolean value that determines the off/on state of the switch. Default to `false`, meaning off.
  ///   - onColor: Color of the inner capsule when the switch is set to `on`. Default `Material.Color.systemGreen`
  ///   - offColor: Color of the inner capsule when the switch is set to `off`. Default `Material.Color.lightGray`
  ///   - padding: Padding (in meters) between the thumb and the inner capsule of the switch. Default 0.05.
  ///   - border: Border (in meters) between the two outer capsules of the switch. No border if set to 0. Default 0.05.
  ///   - borderColor: Color of the outer border. Default `Material.Color.black`
  ///   - thumbColor: Color of the thumb. Default white.
  public init(
    isOn: Bool = false,
    onColor: Material.Color = .systemGreen,
    offColor: Material.Color = .lightGray,
    padding: Float = 0.05,
    border: Float = 0.05,
    borderColor: Material.Color = .black,
    thumbColor: Material.Color = .white
  ) {
    assert(padding > 0, "Padding must be positive")
    assert(border >= 0, "Border must be positive or zero")
    self.isOn = isOn
    self.padding = padding
    self.border = border
    self.onColor = onColor
    self.offColor = offColor
    self.borderColor = borderColor
    self.thumbColor = thumbColor
  }

  /// Creates the SwitchComponent with all default styles, only custom colours.
  /// - Parameters:
  ///   - onColor: Color of the inner capsule when the switch is set to `on`.
  ///   - offColor: Color of the inner capsule when the switch is set to `off`.
  public init(onColor: Material.Color, offColor: Material.Color) {
    self.init(isOn: false, onColor: onColor, offColor: offColor)
  }
}

public extension HasSwitch {

  /// The switch properties that defines the visual appearance and state.
  internal(set) var switchness: SwitchComponent {
    get {
      self.components[SwitchComponent.self] ?? SwitchComponent()}
    set {
      self.components[SwitchComponent.self] = newValue
    }
  }

  /// Set the switch's current value
  /// - Parameters:
  ///   - isOn: The switch's new state
  ///   - animated: Should the switch animate to the new state, if an animation is available.
  func setOn(_ isOn: Bool, animated: Bool = true) {
    if self.isOn == isOn {
      return
    }
    self.isOn = isOn

    self.getModel(part: .background)?.model?.materials = self.getMaterials(for: .background)
    let thumbTransform = Transform(
      scale: .one, rotation: .init(), translation: togglePos
    )
    let thumbEntity = self.getModel(part: .thumb)
    thumbEntity?.stopAllAnimations()
    if animated {
      thumbEntity?.move(to: thumbTransform, relativeTo: self, duration: 0.3)
    } else {
      thumbEntity?.transform = thumbTransform
    }
    self.switchChanged?(self)
  }

  /// Padding (in meters) between the thumb and the inner capsule of the switch.
  /// This cannot yet be altered once the switch has been created
  var padding: Float { self.switchness.padding }

  /// Border (in meters) between the two outer capsules of the switch.
  /// This cannot yet be altered once the switch has been created
  var border: Float { self.switchness.border }

  /// A Boolean value that determines the off/on state of the switch.
  /// To update the value, use `.setOn(:Bool,animated:Bool)`
  private(set) var isOn: Bool {
    get { self.switchness.isOn }
    set { self.switchness.isOn = newValue }
  }
  /// Color of the outer border. Default `Material.Color.black`
  var borderColor: Material.Color { self.switchness.borderColor }
  /// Color of the inner capsule when the switch is set to off. Default `Material.Color.systemGreen`
  var onColor: Material.Color { self.switchness.onColor }
  /// Color of the inner capsule when the switch is set to on. Default `Material.Color.lightGray`
  var offColor: Material.Color { self.switchness.offColor }
  private var togglePos: SIMD3<Float> {
    [(isOn ? -1 : 1) * (self.switchness.length - 1)/2, 0, 0]
  }
  private var thumbColor: Material.Color {
    self.switchness.thumbColor
  }

  private func getModel(part: SwitchComponent.UIPart) -> ModelEntity? {
    return (self as HasRUI).getModel(part: part.rawValue)
  }
  private func addModel(part: SwitchComponent.UIPart) -> ModelEntity {
    return (self as HasRUI).addModel(part: part.rawValue)
  }

  fileprivate func makeModels() {
    let togLen = self.switchness.length
    if self.border > 0 {
      let borderBg = self.addModel(part: .border)
      borderBg.model = ModelComponent(mesh: .generateBox(
        size: [togLen + border, 1 + border, 1 + border], cornerRadius: (1 + border) / 2), materials: []
      )
      borderBg.scale = .init(repeating: -1)
    } else if let border = self.getModel(part: .border) {
      border.removeFromParent()
    }
    let bigBg = self.addModel(part: .background)
    bigBg.model = ModelComponent(
      mesh: .generateBox(size: [togLen, 1, 1], cornerRadius: 0.5), materials: []
    )
    bigBg.scale = .init(repeating: -1)

    let thumb = self.addModel(part: .thumb)
    thumb.model = ModelComponent(mesh: .generateSphere(radius: (1 - padding) / 2), materials: [])
    thumb.position = togglePos
    (self as? HasCollision)?.collision = CollisionComponent(
      shapes: [ShapeResource.generateCapsule(height: 2, radius: 0.5)
        .offsetBy(rotation: simd_quatf(angle: .pi/2, axis: [0, 0, 1]))
      ]
    )
    self.updateMaterials()
  }

  /// Updates all materials in an entity, this is called internally whenever things change such as
  /// the entity responding to light or whether it is enabled.
  func updateMaterials() {
    self.getModel(part: .border)?.model?.materials = getMaterials(for: .border)
    self.getModel(part: .background)?.model?.materials = getMaterials(for: .background)
    self.getModel(part: .thumb)?.model?.materials = getMaterials(for: .thumb)
  }

  internal func getMaterials(
    for part: SwitchComponent.UIPart
  ) -> [Material] {
    switch part {
    case .background:
      return [self.getMaterial(with: self.isOn ? switchness.onColor : switchness.offColor)]
    case .border:
      return [self.getMaterial(with: switchness.borderColor)]
    case .thumb:
      return [self.getMaterial(with: switchness.thumbColor)]
    }
  }
}
