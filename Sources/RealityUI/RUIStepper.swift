//
//  RUIStepper.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import Combine
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// A new RealityUI Stepper to be added to your RealityKit scene.
public class RUIStepper: Entity, HasRUI, HasStepper {
  public var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = {
    clicker, worldPos in
      (clicker as? HasStepper)?.stepperTap(clicker: clicker, worldTapPos: worldPos)
  }

  // Consider changing to 1 function
  public var upTrigger: ((HasStepper) -> Void)?
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
    self.makeModels()
    self.upTrigger = upTrigger
    self.downTrigger = downTrigger
  }

  public convenience init(
    style: StepperComponent.Style,
    upTrigger: ((HasStepper) -> Void)? = nil,
    downTrigger: ((HasStepper) -> Void)? = nil
  ) {
    self.init(stepper: StepperComponent(style: style), upTrigger: upTrigger, downTrigger: downTrigger)
  }

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
  internal var style: Style
  internal enum UIPart: String {
    case right
    case left
    case background
  }
  public enum Style {
    case minusPlus
    case arrowLeftRight
    case arrowDownUp
  }
  /// Create a StepperComponent for an RUIStepper object to add to your scene
  /// - Parameters:
  ///   - backgroundTint: Background color of the stepper.
  ///   - buttonTint: Color of the buttons inside a stepper, default `.systemBlue`.
  ///   - secondaryTint: Color of the second button inside a stepper. If nil, then buttonTint will be used.
  #if os(iOS)
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
  public init(style: StepperComponent.Style) {
    self.init(style: style, secondaryTint: nil)
  }
}
public protocol HasStepper: HasClick {}

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
  internal(set) var stepper: StepperComponent {
    get { self.components[StepperComponent.self] ?? StepperComponent() }
    set { self.components[StepperComponent.self] = newValue }
  }
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
    rightModel.position.x = 0.5
    let leftModel = self.addModel(part: .left)
    leftModel.position.x = -0.5
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
    let sinAng: Float = sin(turnAngle)
    let partLen: Float = (0.7 / 2) / cos(turnAngle)
    let partThickness = partLen * 0.2
    let yDist = 0.2 - (sinAng * partThickness)

    if self.style == .arrowDownUp {
      leftModel.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, -1])
      rightModel.orientation = simd_quatf(angle: .pi / 2, axis: [0, 0, -1])
    }

    let rightSubModel1 = ModelEntity(mesh: .generateBox(
        size: [partThickness, partLen, partThickness],
        cornerRadius: partThickness * 0.25
      ), materials: []
    )
    rightSubModel1.transform = Transform(
      scale: .one, rotation: .init(angle: turnAngle, axis: [0, 0, 1]),
      translation: [0, yDist, 0]
    )

    let rightSubModel2 = ModelEntity()
    rightSubModel2.model = rightSubModel1.model

    rightSubModel2.transform = Transform(
      scale: .one, rotation: .init(angle: -turnAngle, axis: [0, 0, 1]),
      translation: [0, -yDist, 0]
    )

    let leftSubModel1 = rightSubModel2.clone(recursive: true)
    leftSubModel1.position.y = yDist
    let leftSubModel2 = rightSubModel1.clone(recursive: true)
    leftSubModel2.position.y = -yDist

    rightModel.addChild(rightSubModel1)
    rightModel.addChild(rightSubModel2)
    leftModel.addChild(leftSubModel1)
    leftModel.addChild(leftSubModel2)

  }

  func stepperTap(clicker: HasClick, worldTapPos: SIMD3<Float>?) {
      guard let stepperObj = (clicker as? RUIStepper) else {
        return
      }
      guard let tapPos = worldTapPos else {
        return
      }
      let localPos = stepperObj.convert(position: tapPos, from: nil)

      if localPos.x < 0 {
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
      //toggleObj.setOn(!toggleObj.isOn)
  }
}
