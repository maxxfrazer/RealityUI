//
//  RUIStepper.swift
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

/// A new RealityUI Stepper to be added to your RealityKit scene.
public class RUIStepper: Entity, HasRUI, HasStepper {
  public var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = {
    clicker, worldPos in
      (clicker as? HasStepper)?.stepperTap(clicker: clicker, worldTapPos: worldPos)
  }

  // TODO: Consider changing to 1 function
  public var upTrigger: ((HasStepper) -> Void)?
  public var downTrigger: ((HasStepper) -> Void)?

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

  required convenience init() {
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
  internal enum UIPart: String {
    case up
    case down
    case background
  }
  /// Create a StepperComponent for an RUIStepper object to add to your scene
  /// - Parameters:
  ///   - backgroundTint: Background color of the stepper.
  ///   - buttonTint: Color of the buttons inside a stepper, default `.systemBlue`.
  ///   - secondaryTint: Color of the second button inside a stepper. If nil, then buttonTint will be used.
  #if os(iOS)
  init(
    backgroundTint: Material.Color = .tertiarySystemBackground,
    buttonTint: Material.Color = .systemBlue,
    secondaryTint: Material.Color? = nil
  ) {
    self.backgroundTint = backgroundTint
    self.buttonTint = buttonTint
    self.secondButtonTint = secondaryTint
  }
  #elseif os(macOS)
  init(
    backgroundTint: Material.Color = .windowBackgroundColor,
    buttonTint: Material.Color = .systemBlue,
    secondaryTint: Material.Color? = nil
  ) {
    self.backgroundTint = backgroundTint
    self.buttonTint = buttonTint
    self.secondButtonTint = secondaryTint
  }
  #endif

}
public protocol HasStepper: HasClick {}

public extension HasStepper {
  func updateMaterials() {
    let plusModel = self.getModel(part: .up)
    plusModel?.model?.materials = self.getMaterials(for: .up)
    (plusModel?.children.first as? ModelEntity)?.model?.materials = self.getMaterials(for: .up)
    self.getModel(part: .down)?.model?.materials = self.getMaterials(for: .down)
    self.getModel(part: .background)?.model?.materials = self.getMaterials(for: .background)
  }
}

internal extension HasStepper {
  var stepper: StepperComponent {
    get { self.components[StepperComponent.self] ?? StepperComponent() }
    set { self.components[StepperComponent.self] = newValue }
  }
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
    case .down:
      return [self.getMaterial(with: stepper.buttonTint)]
    case .up:
      return [self.getMaterial(with: stepper.secondButtonTint ?? stepper.buttonTint)]
    }
  }

  func springAnimate(entity: Entity) {
    var cancellable: Cancellable?
    let pos = entity.position
    cancellable = entity.scene?.subscribe(to: AnimationEvents.PlaybackCompleted.self, { _ in
      cancellable?.cancel()
      entity.move(
        to: Transform(scale: .one, rotation: .init(), translation: pos),
        relativeTo: self, duration: 0.1, timingFunction: .linear
      )
    })
    entity.move(
      to: Transform(scale: .init(repeating: 0.9), rotation: .init(), translation: pos),
      relativeTo: self, duration: 0.1, timingFunction: .linear
    )
  }

  fileprivate func makeModels() {
    let plusModel = self.addModel(part: .up)
    plusModel.model =  ModelComponent(
      mesh: MeshResource.generateBox(size: [0.15, 0.7, 0.15], cornerRadius: 0.05),
      materials: []
    )
    let subPlusModel = ModelEntity(
      mesh: .generateBox(
        size: [0.7, 0.15, 0.15],
        cornerRadius: 0.05),
      materials: []
    )
    plusModel.addChild(subPlusModel)
    plusModel.position.x = 0.5

    let minusModel = self.addModel(part: .down)
    minusModel.model =  ModelComponent(mesh: MeshResource.generateBox(size: [0.7, 0.15, 0.15], cornerRadius: 0.05), materials: [])
    minusModel.position.x = -0.5

    let background = self.addModel(part: .background)
    background.model = ModelComponent(mesh: .generateBox(size: [2, 1, 0.25], cornerRadius: 0.125), materials: [])
    background.scale = .init(repeating: -1)

    self.updateMaterials()
    self.collision = CollisionComponent(shapes: [.generateBox(size: [2, 1, 0.25])])
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
        if let downModel = stepperObj.getModel(part: .down) {
          stepperObj.springAnimate(entity: downModel)
        }
        stepperObj.downTrigger?(stepperObj)
      } else {
        if let upModel = stepperObj.getModel(part: .up) {
          stepperObj.springAnimate(entity: upModel)
        }
        stepperObj.upTrigger?(stepperObj)
      }
      //toggleObj.setOn(!toggleObj.isOn)
  }
}
