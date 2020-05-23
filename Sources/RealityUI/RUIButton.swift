//
//  RUIButton.swift
//  
//
//  Created by Max Cobb on 5/22/20.
//

import RealityKit
import Combine

public struct ButtonComponent: Component {
  let size: SIMD3<Float>
  var buttonColor: Material.Color
  var baseColor: Material.Color
  let padding: Float
  let extrude: Float
  let compress: Float
  let cornerRadius: Float?
  internal var isCompressed = false
  enum UIPart: String {
    case button
    case base
  }
  init(
    size: SIMD3<Float> = [1, 1, 0.2],
    buttonColor: Material.Color = .systemBlue,
    baseColor: Material.Color = .systemGray,
    padding: Float = 0.1,
    releaseAmount: Float = 0.6,
    compressAmount: Float = 0.2,
    cornerRadius: Float? = nil
  ) {
    self.size = size
    self.buttonColor = buttonColor
    self.baseColor = baseColor
    assert(min(size.x, size.y) / 2 > padding, "Padding is too large for this button")
    self.padding = padding
    assert((0...1).contains(releaseAmount), "Extrusion amount must be between 0 and 0.9")
    self.extrude = releaseAmount
    self.compress = compressAmount
    self.cornerRadius = cornerRadius
  }
  init(width: Float = 1, height: Float = 1, depth: Float = 0.2, padding: Float = 0.1, cornerRadius: Float? = nil) {
    self.init(size: [width, height, depth], padding: padding, cornerRadius: cornerRadius)
  }
}

public protocol HasButton: HasTouchUpInside {
  var touchUpCompleted: ((HasButton) -> Void)? { get set }
}

extension HasButton {
  var button: ButtonComponent {
    get { self.components[ButtonComponent.self] ?? ButtonComponent() }
    set { self.components[ButtonComponent.self] = newValue }
  }

  var padding: Float { self.button.padding }
  var size: SIMD3<Float> { self.button.size }
  var cornerRadius: Float? { self.button.cornerRadius }
  var extrude: Float { self.button.extrude }
  var compress: Float { self.button.compress }

  internal var innerBoxSize: SIMD3<Float> {[
    self.size.x - self.padding,
    self.size.y - self.padding,
    self.size.z * 0.9
  ]}
  internal var buttonOutPos: SIMD3<Float> {
    return [0, 0, (self.button.size.z + self.innerBoxSize.z) / 2 * self.extrude]
  }
  internal var buttonInPos: SIMD3<Float> {
    return [0, 0, (self.button.size.z + self.innerBoxSize.z) / 2 * self.compress]
  }

  internal var isCompressed: Bool {
    get { self.button.isCompressed }
    set { self.button.isCompressed = newValue}
  }
  internal func getMaterials(
    for part: ButtonComponent.UIPart
  ) -> [Material] {
    switch part {
    case .button:
      return [self.getMaterial(with: self.button.buttonColor)]
    case .base:
      return [self.getMaterial(with: self.button.baseColor)]
    }
  }
  public func updateMaterials() {
    self.getModel(part: .base)?.model?.materials = self.getMaterials(for: .base)
    self.getModel(part: .button)?.model?.materials = self.getMaterials(for: .button)
  }
  internal func makeModels() {
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
  public func buttonTap(worldTapPos: SIMD3<Float>?) {
    guard let innerModel = self.getModel(part: .button) else {
      return
    }
    innerModel.stopAllAnimations()
    var cancellable: Cancellable?
    cancellable = self.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, { _ in
      cancellable?.cancel()
      innerModel.move(to: Transform(scale: .one, rotation: .init(), translation: self.buttonOutPos), relativeTo: self, duration: 0.15)
    })
    innerModel.move(to: Transform(scale: .one, rotation: .init(), translation: self.buttonInPos), relativeTo: self, duration: 0.15)
  }
}

extension HasButton {
  public func arTouchStarted(hasCollided: Bool, _ worldCoordinate: SIMD3<Float>) {
    self.compressButton()
  }

  public func arTouchUpdated(hasCollided: Bool, _ worldCoordinate: SIMD3<Float>?) {
    if hasCollided != self.isCompressed {
      hasCollided ? self.compressButton() : self.releaseButton()
    }
  }

  public func arTouchEnded(_ worldCoordinate: SIMD3<Float>?) {
    if self.isCompressed {
      self.releaseButton()
      self.touchUpCompleted?(self)
    }
  }


}

/// A  RealityUI Slider to be added to a RealityKit scene.
public class RUIButton: Entity, HasButton, HasModel {

  public var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = {
    clicker, worldPos in
      (clicker as? HasButton)?.buttonTap(worldTapPos: worldPos)
  }
  public var touchUpCompleted: ((HasButton) -> Void)?

  var button: ButtonComponent {
    get { self.components[ButtonComponent.self] ?? ButtonComponent() }
    set { self.components[ButtonComponent.self] = newValue}
  }
  /// Creates a RealityUI Slider entity with optional `SliderComponent`, `RUIComponent` and `updateCallback`.
  /// - Parameters:
  ///   - slider: Details about the slider to be set when initialized
  ///   - RUI: Details about the RealityUI Entity
  ///   - updateCallback: callback function to receive updates on slider value changes.
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


