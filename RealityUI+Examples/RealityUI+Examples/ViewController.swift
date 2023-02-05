//
//  ViewController.swift
//  RealityUI+Examples
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import UIKit
import RealityKit
import ARKit

import RealityUI

class ViewController: UIViewController {

  var arView = ARView(frame: .zero, cameraMode: .ar, automaticallyConfigureSession: false)
  var arMode = true
  func addARView() {

    arView.frame = self.view.bounds
    self.arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.view.addSubview(arView)
    RealityUI.enableGestures(.all, on: self.arView)
    self.arView.renderOptions.insert(.disableGroundingShadows)

      if self.arMode {
          let config = ARWorldTrackingConfiguration()
          config.planeDetection = [.horizontal]
          arView.session.run(config, options: [])
          self.addObjectToPlane()
      } else {
          arView.cameraMode = .nonAR
          arView.environment.background = .color(.orange)
          self.addNonARParts()
      }
    // Replaces camera feed, if 6dof VR look is wanted
//    arView.environment.background = .color(.systemGray)

    // Register all the components used in RealityUI
    RealityUI.registerComponents()
  }

    func addNonARParts() {
        let stepper = RUIStepper()
        let anchor = AnchorEntity(world: .zero)
        self.arView.scene.addAnchor(anchor)
        anchor.addChild(stepper)
    }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Add all RealityUI gestures to the current ARView
    self.addARView()
  }
}
