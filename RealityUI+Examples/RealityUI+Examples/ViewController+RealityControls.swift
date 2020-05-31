//
//  ViewController+RealityControls.swift
//  RealityUI+Examples
//
//  Created by Max Cobb on 5/24/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import Foundation
import Combine

import RealityUI

class ControlsParent: Entity, HasAnchoring, HasCollision, HasModel, HasPivotTouch {
  func updateMaterials() {}

  var tumbler: ContainerCube?
  var tumblingCubes: [ModelEntity] = []
  required init() {
    super.init()
    self.anchoring = AnchoringComponent(.plane(
      .horizontal, classification: .any, minimumBounds: [0.5, 0.5]
    ))
    self.addControls()
    /*
    /// Uncomment this to try out HasPivotTouch, but it's still in an experimental stage.
    if let rotateImg = try? TextureResource.load(named: "rotato") {
      self.collision = CollisionComponent(shapes: [.generateBox(size: [10, 0.1, 10])])
      var unlitTextured = UnlitMaterial(color: .white)
      unlitTextured.baseColor = MaterialColorParameter.texture(rotateImg)
      unlitTextured.tintColor = unlitTextured.tintColor.withAlphaComponent(0.75)
      self.model = ModelComponent(mesh: .generatePlane(width: 1.5, depth: 1.5), materials: [unlitTextured])
    }
     */
  }

  func entityAnchored() {
    self.addTumbler()
  }

  /// Add all the RealityUI Controls
  func addControls() {
    let button = RUIButton(
      button: ButtonComponent(size: [2, 1, 0.4]),
      RUI: RUIComponent(respondsToLighting: true),
      updateCallback: { _ in self.popBoxes(power: 0.5)}
    )
    button.transform = Transform(
      scale: .init(repeating: 0.2),
      rotation: simd_quatf(angle: -.pi / 2, axis: [1, 0, 0]),
      translation: .zero
    )
    self.addChild(button)
    let toggle = RUISwitch(changedCallback: { tog in
      if tog.isOn {
        self.tumbler?.spin(in: [0, 0, 1], duration: 3)
        self.popBoxes(power: 0.1)
      } else {
        self.tumbler?.stopAllAnimations()
      }
    })
    toggle.transform = Transform(
      scale: .init(repeating: 0.15), rotation: .init(), translation: [0, 0.25, -0.25]
    )
    self.addChild(toggle)

    let slider = RUISlider(slider: SliderComponent(startingValue: 0.5, steps: 0)) { (slider, _) in
      for child in self.tumblingCubes {
        child.scale = .init(repeating: slider.value + 0.5)
      }
    }
    slider.transform = Transform(scale: .init(repeating: 0.1), rotation: .init(), translation: [0, 1.15, -0.25])
    self.addChild(slider)

    let minusPlusStepper = RUIStepper(upTrigger: { _ in
      if self.tumblingCubes.count <= 8 {
        self.spawnShape(with: SIMD3<Float>(repeating: slider.value + 0.5))
      }
    }, downTrigger: { _ in
      self.removeCube()
    })
    minusPlusStepper.transform = Transform(
      scale: .init(repeating: 0.15), rotation: .init(), translation: [-0.5, 0.25, -0.25]
    )
    self.addChild(minusPlusStepper)

    let shapeStepper = RUIStepper(style: .arrowLeftRight, upTrigger: { stepper in
      self.shiftShape(1, on: stepper)
    }, downTrigger: { stepper in
      self.shiftShape(-1, on: stepper)
    })
    shapeStepper.transform = Transform(
      scale: .init(repeating: 0.15), rotation: .init(), translation: [0.5, 0.25, -0.25]
    )
    self.addChild(shapeStepper)
    self.shiftShape(0, on: shapeStepper)
  }

  var currShape: Int = 0
  /// The object shapes that will be added
  var shiftShapes: [MeshResource] = [
    .generateBox(size: 0.2),
    // Slight problem with sphere and physics body, cause unknown to me
    .generateSphere(radius: 0.1),
    .generateBox(size: [0.2, 0.2, 0.01])
  ]
}

extension ViewController {
  static var letRotate = false
  func addObjectToPlane() {
    let controlsAnchor = ControlsParent()
    controlsAnchor.position.z = -0.25
    var anchorFoundCallback: Cancellable?
    anchorFoundCallback = self.arView.scene.subscribe(
      to: SceneEvents.AnchoredStateChanged.self, on: controlsAnchor, { anchorEvent in
      if anchorEvent.isAnchored {
        controlsAnchor.entityAnchored()
        if ViewController.letRotate {
          let visBounds = controlsAnchor.visualBounds(relativeTo: controlsAnchor)
          print(visBounds.center)
          controlsAnchor.collision = CollisionComponent(shapes: [
            ShapeResource.generateBox(size: visBounds.extents * 1.1).offsetBy(translation: visBounds.center)
          ])
          self.arView.installGestures(.rotation, for: controlsAnchor)
        }
        DispatchQueue.main.async {
          anchorFoundCallback?.cancel()
        }
      }
    })
    self.arView.scene.addAnchor(controlsAnchor)
  }
}
