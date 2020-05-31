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

  func addARView() {
    arView.frame = self.view.bounds
    self.arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.view.addSubview(arView)
    self.arView.renderOptions.insert(.disableGroundingShadows)

    let config = ARWorldTrackingConfiguration()
    config.planeDetection = [.horizontal]
    arView.session.run(config, options: [])

    // Replaces camera feed, if 6dof VR look is wanted
//    arView.environment.background = .color(.systemGray)

    // Register all the components used in RealityUI
    RealityUI.registerComponents()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.addARView()

    // Add all RealityUI gestures to the current ARView
    self.arView.enableRealityUIGestures(.all)
    self.addObjectToPlane()
  }
}
