//
//  RUIButton.swift
//  
//
//  Created by Max Cobb on 5/22/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

/// A  RealityUI Button to be added to a RealityKit scene.
public class RUIButton: Entity, HasButton, HasModel, HasPhysics {

  public var touchUpCompleted: ((HasButton) -> Void)?

  /// Creates a RealityUI Button entity with optional `ButtonComponent`, `RUIComponent` and `updateCallback`.
  /// - Parameters:
  ///   - button: Details about the button to be set when initialized.
  ///   - RUI: Details about the RealityUI Entity.
  ///   - updateCallback: callback function to receive updates touchUpInside the RealityUI Button.
  required public init(
    button: ButtonComponent? = nil, RUI: RUIComponent? = nil,
    updateCallback: ((HasButton) -> Void)? = nil
  ) {
    self.touchUpCompleted = updateCallback
    super.init()
    self.RUI = RUI ?? RUIComponent()
    self.button = button ?? ButtonComponent()
    self.makeModels()
  }

  required public convenience init() {
    self.init(button: nil)
  }
}

public struct ButtonComponent: Component {
  let size: SIMD3<Float>
  var buttonColor: Material.Color
  var baseColor: Material.Color
  let padding: Float
  let extrude: Float
  let compress: Float
  let cornerRadius: Float?
  internal var isCompressed = false
  let style: ButtonComponent.Style

  enum UIPart: String {
    case button
    case base
  }
  public enum Style {
    case rectangular
  }

  public static let defaultSize: SIMD3<Float> = [1, 1, 0.2]

  /// Creates a ButtonComponent specifying the layout and appearance of a RUIButton
  /// - Parameters:
  ///   - size: Size of the RUIButton base
  ///   - buttonColor: Color of the button
  ///   - baseColor: Color of the button base
  ///   - padding: Padding (in meters) between the base and the button. Default 0.1.
  ///   - extrude: Multiplyer amount that the button sticks out from the base when unpressed.
  ///              The extrude amount will be a multiplier of the button z size
  ///   - compress: Multiplyer amount that the button sticks out from the base when pressed.
  ///               The compress amount will be a multiplier of the button z size
  ///   - cornerRadius: A corner radius applied to both the button and the button base.
  ///   - style: Style of RUIButton
  public init(
    size: SIMD3<Float> = ButtonComponent.defaultSize,
    buttonColor: Material.Color = .systemBlue,
    baseColor: Material.Color = .systemGray,
    padding: Float = 0.1,
    extrude: Float = 0.5,
    compress: Float = 0.2,
    cornerRadius: Float? = nil,
    style: Style = .rectangular
  ) {
    self.size = size
    self.buttonColor = buttonColor
    self.baseColor = baseColor
    assert(min(size.x, size.y) / 2 > padding, "Padding is too large for this button")
    self.padding = padding
    self.extrude = extrude
    self.compress = compress
    self.cornerRadius = cornerRadius
    self.style = style
  }
  public init(style: Style) {
    self.init(size: ButtonComponent.defaultSize, style: style)
  }
  public init(width: Float = 1, height: Float = 1, depth: Float = 0.2, padding: Float = 0.1, cornerRadius: Float? = nil) {
    self.init(size: [width, height, depth], padding: padding, cornerRadius: cornerRadius)
  }
}

public protocol HasButton: HasTouchUpInside {
  var touchUpCompleted: ((HasButton) -> Void)? { get set }
}

public extension HasButton {
  internal(set) var button: ButtonComponent {
    get { self.components[ButtonComponent.self] ?? ButtonComponent() }
    set { self.components[ButtonComponent.self] = newValue }
  }

  /// Padding (in meters) between the base and the button. Default 0.1.
  var padding: Float { self.button.padding }
  /// Size of the RUIButton base
  var size: SIMD3<Float> { self.button.size }
  /// A corner radius applied to both the button and the button base.
  var cornerRadius: Float? { self.button.cornerRadius }
  /// Multiplyer amount that the button sticks out from the base when unpressed.
  /// The extrude amount will be a multiplier of the button z size, which is 0.9 * the base
  var extrude: Float { self.button.extrude }
  /// Multiplyer amount that the button sticks out from the base when pressed.
  /// The compress amount will be a multiplier of the button z size, which is 0.9 * the base
  var compress: Float { self.button.compress }
  /// Color of the button
  var buttonColor: Material.Color {
    get { self.button.buttonColor }
    set {
      self.button.buttonColor = newValue
      self.updateMaterials()
    }
  }
  /// Color of the button base
  var baseColor: Material.Color {
    get { self.button.baseColor }
    set {
      self.button.baseColor = newValue
      self.updateMaterials()
    }
  }

  func updateMaterials() {
    self.getModel(part: .base)?.model?.materials = self.getMaterials(for: .base)
    self.getModel(part: .button)?.model?.materials = self.getMaterials(for: .button)
  }

  private func updateCollision() {
    guard let buttonInner = self.getModel(part: .button) else {
      return
    }
    let collShape = ShapeResource.generateBox(size: self.innerBoxSize).offsetBy(translation: buttonInner.position)
    self.collision = CollisionComponent(shapes: [collShape])
  }
  private func getModel(part: ButtonComponent.UIPart) -> ModelEntity? {
    return (self as HasRUI).getModel(part: part.rawValue)
  }
  private func addModel(part: ButtonComponent.UIPart) -> ModelEntity {
    return (self as HasRUI).addModel(part: part.rawValue)
  }
}

public extension HasButton {
  func arTouchStarted(hasCollided: Bool, _ worldCoordinate: SIMD3<Float>) {
    self.compressButton()
  }

  func arTouchUpdated(hasCollided: Bool, _ worldCoordinate: SIMD3<Float>?) {
    if hasCollided != self.isCompressed {
      hasCollided ? self.compressButton() : self.releaseButton()
    }
  }

  func arTouchEnded(_ worldCoordinate: SIMD3<Float>?) {
    if self.isCompressed {
      self.releaseButton()
      self.touchUpCompleted?(self)
    }
  }
}

internal extension HasButton {
  var innerBoxSize: SIMD3<Float> {[
    self.size.x - self.padding,
    self.size.y - self.padding,
    self.size.z
  ]}
  var buttonOutPos: SIMD3<Float> {
    return [
      0, 0,
      (self.button.size.z + self.innerBoxSize.z * (2 * extrude - 1)) / 2
    ]
  }
  var buttonInPos: SIMD3<Float> {
    return [
      0, 0,
      (self.button.size.z + self.innerBoxSize.z * (2 * compress - 1)) / 2
    ]
  }

  var isCompressed: Bool {
    get { self.button.isCompressed }
    set { self.button.isCompressed = newValue}
  }
  func getMaterials(
    for part: ButtonComponent.UIPart
  ) -> [Material] {
    switch part {
    case .button:
      return [self.getMaterial(with: self.button.buttonColor)]
    case .base:
      return [self.getMaterial(with: self.button.baseColor)]
    }
  }

  func makeModels() {
    let buttonOuter = self.addModel(part: .base)
    buttonOuter.model = ModelComponent(
      mesh: .generateBox(
        size: self.size,
        cornerRadius: cornerRadius ?? self.size.min() * 0.4
      ), materials: []
    )
    let buttonInner = self.addModel(part: .button)
    let innerBoxSize = self.innerBoxSize
    buttonInner.model = ModelComponent(
      mesh: MeshResource.generateBox(
        size: innerBoxSize,
        cornerRadius: cornerRadius ?? innerBoxSize.min() * 0.4
      ), materials: []
    )
    buttonInner.position = self.buttonOutPos
    self.updateMaterials()
    self.updateCollision()
  }
  func compressButton() {
    guard let innerModel = self.getModel(part: .button) else {
      return
    }
    self.isCompressed = true
    innerModel.stopAllAnimations()
    innerModel.move(
      to: Transform(scale: .one, rotation: .init(), translation: self.buttonInPos),
      relativeTo: self, duration: 0.15
    )
  }
  func releaseButton() {
    guard let innerModel = self.getModel(part: .button) else {
      return
    }
    self.isCompressed = false
    innerModel.stopAllAnimations()
    innerModel.move(
      to: Transform(scale: .one, rotation: .init(), translation: self.buttonOutPos),
      relativeTo: self, duration: 0.15
    )
  }
}
