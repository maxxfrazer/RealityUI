//
//  ViewController+NonRealityUI.swift
//  RealityUI+Examples
//
//  Created by Max Cobb on 5/24/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit

// import RealityUI

class ContainerCube: Entity, HasPhysicsBody, HasModel {
  private static var boxPositions: [SIMD3<Float>] = [
    [-1, 0, 0],
    [1, 0, 0],
    [0, -1, 0],
    [0, 1, 0],
    [0, 0, -1],
    [0, 0, 1]
  ]
  required init(showingInterior: Bool) {
    super.init()
    self.collision = CollisionComponent(
      shapes: ContainerCube.boxPositions.map {
        ShapeResource.generateBox(size: [1, 1, 1]).offsetBy(translation: $0) },
      mode: .default, filter: CollisionFilter(
        group: .init(rawValue: 1 << 31),
        mask: .init(rawValue: 1 << 31)
      )
    )
    if showingInterior {
      let cubeModel = ModelEntity(
        mesh: .generateBox(size: 1), materials: [
          SimpleMaterial(color: Material.Color.lightGray.withAlphaComponent(0.5), isMetallic: false)
      ])
      cubeModel.scale *= -1
      self.addChild(cubeModel)
    }
    self.physicsBody = PhysicsBodyComponent(shapes: ContainerCube.boxPositions.map {
      ShapeResource.generateBox(size: .one).offsetBy(translation: $0)
    }, mass: 1, mode: .static)
//    self.model = ModelComponent(mesh: .generateBox(size: 0.2), materials: [])
  }

  required init() {
    fatalError("init() has not been implemented")
  }
}

extension ControlsParent {
  func addTumbler() {
    let tumbler = ContainerCube(showingInterior: true)
    if let cubeColl = tumbler.collision {
      RealityUI.longGestureMask.remove(cubeColl.filter.group)
      RealityUI.tapGestureMask.remove(cubeColl.filter.group)
    }
    tumbler.position = [0, 0.75, -1.25]
    self.addChild(tumbler)
    self.tumbler = tumbler
  }
  func popBoxes(power: Float) {
    for cube in self.tumblingCubes {
      cube.applyImpulse([0, power * pow(cube.scale.x, 3), 0], at: .zero, relativeTo: nil)
    }
  }

  func shiftShape(_ shift: Int, on stepper: Entity) {
    self.currShape = (self.currShape + shift + self.shiftShapes.count)
      % self.shiftShapes.count
    for shape in self.tumblingCubes {
      shape.model?.mesh = self.shiftShapes[self.currShape]
      shape.collision = nil
      shape.physicsBody = nil
      shape.generateCollisionShapes(recursive: false)
      shape.collision?.filter = CollisionFilter(group: .all, mask: .all)
      shape.physicsBody = PhysicsBodyComponent(
        shapes: [.generateSphere(radius: 0.1)],
        mass: 1,
        material: .generate(friction: 20, restitution: 0.5),
        mode: .dynamic
      )
    }
    var shapeVisualised = stepper.findEntity(named: "shapeVisualised")
    if shapeVisualised == nil {
      let visModel = ModelEntity()
      visModel.name = "shapeVisualised"
      visModel.scale = .init(repeating: 3)
      visModel.position.y = 1
      stepper.addChild(visModel)
      shapeVisualised = visModel
    }
    shapeVisualised?.stopAllAnimations()
    (shapeVisualised as? ModelEntity)?.model = ModelComponent(
      mesh: self.shiftShapes[self.currShape],
      materials: [
        UnlitMaterial(color: Material.Color.blue.withAlphaComponent(0.9))
      ]
    )
    shapeVisualised?.spin(in: [0, 1, 0], duration: 5)
  }
  func removeCube() {
    if tumblingCubes.isEmpty {
      return
    }
    let lastCube = tumblingCubes.removeLast()
    lastCube.removeFromParent()
  }

  func spawnShape(with scale: SIMD3<Float>) {
    let newCube = ModelEntity(
      mesh: self.shiftShapes[self.currShape],
      materials: [SimpleMaterial(color: .blue, isMetallic: false)]
    )
    newCube.generateCollisionShapes(recursive: false)
    newCube.collision?.filter = CollisionFilter(group: .all, mask: .all)
    newCube.physicsBody = PhysicsBodyComponent(
      shapes: [.generateConvex(from: self.shiftShapes[self.currShape])],
      mass: 1,
      material: .generate(friction: 0.8, restitution: 0.3),
      mode: .dynamic
    )
    newCube.orientation = .init(angle: .pi / 1.5, axis: [1, 0, 0])
    newCube.scale = scale
    tumbler?.addChild(newCube)
    tumblingCubes.append(newCube)
  }
}
