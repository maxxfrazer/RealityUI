//
//  RUIStepper.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import Combine

/// A new RealityUI Stepper to be added to your RealityKit scene.
public class RUIStepper: Entity, HasRUIMaterials, HasStepper {
  public var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = { clicker, worldPos in
    (clicker as? HasStepper)?.stepperTap(clicker: clicker, worldTapPos: worldPos)
  }

  /// Stepper's positive button has been pressed
  public var upTrigger: ((HasStepper) -> Void)?
  /// Stepper's negative button has been pressed
  public var downTrigger: ((HasStepper) -> Void)?

  /// Creates a RealityUI Stepper entity with optional `StepperComponent`, `RUIComponent`,
  /// as well as `upTrigger` and `downTrigger` callbacks.
  /// - Parameters:
  ///   - stepper: Details about the stepper colours to be set when initialized.
  ///   - RUI: Details about the RealityUI Entity.
  ///   - upTrigger: Callback function to receive updates then the up button has been clicked.
  ///   - downTrigger: Callback function to receive updates then the down button has been clicked.
  required public init(
    stepper: StepperComponent? = nil,
    RUI: RUIComponent? = nil,
    upTrigger: ((HasStepper) -> Void)? = nil,
    downTrigger: ((HasStepper) -> Void)? = nil
  ) {
    super.init()
    self.RUI = RUI ?? RUIComponent()
    self.stepper = stepper ?? StepperComponent()
    self.ruiOrientation()
    self.makeModels()
    self.upTrigger = upTrigger
    self.downTrigger = downTrigger
  }

  /// Create a RUIStepper entity with default properties for a given style.
  /// - Parameters:
  ///   - style: Style for the new stepper.
  ///   - upTrigger: Callback function to receive updates then the positive button has been clicked.
  ///   - downTrigger: Callback function to receive updates then the negative button has been clicked.
  public convenience init(
    style: StepperComponent.Style,
    upTrigger: ((HasStepper) -> Void)? = nil,
    downTrigger: ((HasStepper) -> Void)? = nil
  ) {
    self.init(stepper: StepperComponent(style: style), upTrigger: upTrigger, downTrigger: downTrigger)
  }

  /// Create a RUIStepper entity with the default style of `.plusMinus`.
  /// - Parameters:
  ///   - upTrigger: Callback function to receive updates then the plus button has been clicked.
  ///   - downTrigger: Callback function to receive updates then the minus button has been clicked.
  public convenience init(
    upTrigger: ((HasStepper) -> Void)? = nil, downTrigger: ((HasStepper) -> Void)? = nil
  ) {
    self.init(stepper: nil, upTrigger: upTrigger, downTrigger: downTrigger)
  }

  required public convenience init() {
    self.init(upTrigger: nil, downTrigger: nil)
  }
}

/// A collection of resources that create the visual appearance a RealityUI Stepper.
public struct StepperComponent: Component {
  /// Background color of the stepper.
  internal var backgroundTint: Material.Color
  /// Color of the buttons inside a stepper, default `.systemBlue`.
  internal var buttonTint: Material.Color
  /// Color of the second button inside a stepper. If nil, then buttonTint will be used.
  internal var secondButtonTint: Material.Color?
  /// Style of the stepper.
  internal var style: Style
  internal enum UIPart: String {
    case right
    case left
    case background
  }
  /// Stepper styles
  public enum Style {
    /// Style of stepper with a + and - symbol
    case minusPlus
    /// Style of stepper with a "〈" and "〉" symbol
    case arrowLeftRight
    /// Style of stepper with up and down pointing symbols
    case arrowDownUp
  }
  #if os(iOS)
  /// Create a StepperComponent for an RUIStepper object to add to your scene
  /// - Parameters:
  ///   - style: Style of the stepper.
  ///   - backgroundTint: Background color of the stepper.
  ///   - buttonTint: Color of the buttons inside a stepper, default `.systemBlue`.
  ///   - secondaryTint: Color of the second button inside a stepper. If nil, then buttonTint will be used.
  public init(
    style: StepperComponent.Style = .minusPlus,
    backgroundTint: Material.Color = .tertiarySystemBackground,
    buttonTint: Material.Color = .systemBlue,
    secondaryTint: Material.Color? = nil
  ) {
    self.style = style
    self.backgroundTint = backgroundTint
    self.buttonTint = buttonTint
    self.secondButtonTint = secondaryTint
  }
  #elseif os(macOS)
  /// Create a StepperComponent for an RUIStepper object to add to your scene
  /// - Parameters:
  ///   - style: Style of the stepper.
  ///   - backgroundTint: Background color of the stepper, default `.windowBackgroundColor`
  ///   - buttonTint: Color of the buttons inside a stepper, default `.systemBlue`.
  ///   - secondaryTint: Color of the second button inside a stepper. If nil, then buttonTint will be used.
  public init(
    style: StepperComponent.Style = .minusPlus,
    backgroundTint: Material.Color = .windowBackgroundColor,
    buttonTint: Material.Color = .systemBlue,
    secondaryTint: Material.Color? = nil
  ) {
    self.style = style
    self.backgroundTint = backgroundTint
    self.buttonTint = buttonTint
    self.secondButtonTint = secondaryTint
  }
  #endif
  /// Create a StepperComponent with default properties of a given style
  /// - Parameter style: Stepper style.
  public init(style: StepperComponent.Style) {
    self.init(style: style, secondaryTint: nil)
  }
}

/// An interface used for entities with mutliple click actions, like RUIStepper.
public protocol HasStepper: HasClick, HasRUIMaterials {}

public extension HasStepper {
  func updateMaterials() {
    switch self.style {
    case .arrowLeftRight, .minusPlus, .arrowDownUp:
      guard let rightModel = self.getModel(part: .right),
        let leftModel = self.getModel(part: .left) else {
        return
      }
      rightModel.model?.materials = self.getMaterials(for: .right)
      for child in rightModel.children {
        (child as? ModelEntity)?.model?.materials = self.getMaterials(for: .right)
      }
      leftModel.model?.materials = self.getMaterials(for: .left)
      for child in leftModel.children {
        (child as? ModelEntity)?.model?.materials = self.getMaterials(for: .left)
      }
//    default:
//      break
    }
    self.getModel(part: .background)?.model?.materials = self.getMaterials(for: .background)
  }
  /// Stepper component, containing all properties relating to the rendering of the stepper.
  internal(set) var stepper: StepperComponent {
    get { self.components[StepperComponent.self] ?? StepperComponent() }
    set { self.components[StepperComponent.self] = newValue }
  }
  /// Style of the stepper.
  internal(set) var style: StepperComponent.Style {
    get { self.stepper.style }
    set { self.stepper.style = newValue }
  }
}

internal extension HasStepper {
  fileprivate func getModel(part: StepperComponent.UIPart) -> ModelEntity? {
    return (self as HasRUI).getModel(part: part.rawValue)
  }
  fileprivate func addModel(part: StepperComponent.UIPart) -> ModelEntity {
    return (self as HasRUI).addModel(part: part.rawValue)
  }
  func getMaterials(
    for part: StepperComponent.UIPart
  ) -> [Material] {
    switch part {
    case .background:
      return [self.getMaterial(with: stepper.backgroundTint)]
    case .left:
      return [self.getMaterial(with: stepper.buttonTint)]
    case .right:
      return [self.getMaterial(with: stepper.secondButtonTint ?? stepper.buttonTint)]
    }
  }

  func springAnimate(entity: Entity) {
    var cancellable: Cancellable?
    let pos = entity.position
    cancellable = entity.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, { _ in
      cancellable?.cancel()
      entity.move(
        to: Transform(scale: .one, rotation: entity.orientation, translation: pos),
        relativeTo: self, duration: 0.1, timingFunction: .linear
      )
    })
    entity.move(
      to: Transform(scale: .init(repeating: 0.9), rotation: entity.orientation, translation: pos),
      relativeTo: self, duration: 0.1, timingFunction: .linear
    )
  }

  fileprivate func makeModels() {
    let rightModel = self.addModel(part: .right)
    rightModel.position.x = -0.5
    let leftModel = self.addModel(part: .left)
    leftModel.position.x = 0.5
    switch self.style {
    case .minusPlus:
      rightModel.model =  ModelComponent(
        mesh: MeshResource.generateBox(size: [0.15, 0.7, 0.15], cornerRadius: 0.05),
        materials: []
      )
      let subPlusModel = ModelEntity(
        mesh: .generateBox(
          size: [0.7, 0.15, 0.15],
          cornerRadius: 0.05),
        materials: []
      )
      rightModel.addChild(subPlusModel)
      leftModel.model =  ModelComponent(
        mesh: MeshResource.generateBox(size: [0.7, 0.15, 0.15], cornerRadius: 0.05),
        materials: []
      )
    case .arrowLeftRight, .arrowDownUp:
      self.addArrowModels(leftModel, rightModel)
    }

    let background = self.addModel(part: .background)
    background.model = ModelComponent(mesh: .generateBox(size: [2, 1, 0.25], cornerRadius: 0.125), materials: [])
    background.scale = .init(repeating: -1)

    self.updateMaterials()
    self.collision = CollisionComponent(shapes: [.generateBox(size: [2, 1, 0.25])])
  }

  private func addArrowModels(_ leftModel: ModelEntity, _ rightModel: ModelEntity) {
    // Setup parameters
    let turnAngle: Float = .pi / 6
    let partLen: Float = (0.7 / 2)
    let partThickness = partLen * 0.2
    let hCorner = hypot(partLen / 2, partThickness / 2)
    let ang2 = atan2(partThickness / 2, partLen / 2)
    let yDist = hCorner * cos(turnAngle + ang2)

    if self.style == .arrowDownUp {
      leftModel.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, -1])
      rightModel.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, -1])
    }

    let leftSubModel1 = ModelEntity(
      mesh: .generateBox(
        size: [partThickness, partLen, partThickness],
        cornerRadius: partThickness * 0.25
      ), materials: []
    )
    leftSubModel1.transform = Transform(
      scale: .one, rotation: .init(angle: turnAngle, axis: [0, 0, 1]),
      translation: [0, yDist, 0]
    )

    let leftSubModel2 = ModelEntity()
    leftSubModel2.model = leftSubModel1.model

    leftSubModel2.transform = Transform(
      scale: .one, rotation: .init(angle: -turnAngle, axis: [0, 0, 1]),
      translation: [0, -yDist, 0]
    )

    let rightSubModel1 = leftSubModel2.clone(recursive: true)
    rightSubModel1.position.y = yDist
    let rightSubModel2 = leftSubModel1.clone(recursive: true)
    rightSubModel2.position.y = -yDist

    leftModel.addChild(leftSubModel1)
    leftModel.addChild(leftSubModel2)
    rightModel.addChild(rightSubModel1)
    rightModel.addChild(rightSubModel2)
  }

  func stepperTap(clicker: HasClick, worldTapPos: SIMD3<Float>?) {
    guard let stepperObj = (clicker as? RUIStepper) else {
      return
    }
    guard let tapPos = worldTapPos else {
      return
    }
    let localPos = stepperObj.convert(position: tapPos, from: nil)

    if localPos.x > 0 {
      if let downModel = stepperObj.getModel(part: .left) {
        stepperObj.springAnimate(entity: downModel)
      }
      stepperObj.downTrigger?(stepperObj)
    } else {
      if let upModel = stepperObj.getModel(part: .right) {
        stepperObj.springAnimate(entity: upModel)
      }
      stepperObj.upTrigger?(stepperObj)
    }
  }
}
