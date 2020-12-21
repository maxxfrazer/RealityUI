//
//  HasRUI.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import CoreGraphics

/// A collection of properties for all RealityUI Entities.
public struct RUIComponent: Component {
  /// A Boolean value indicating whether the RealityUI Entity is enabled.
  public internal(set) var ruiEnabled: Bool
  /// A Boolean value indicating whether the RealityUI Entity materials respond to light.
  internal var respondsToLighting: Bool

  /// Create a new `RUIComponent` for a RealityUI Entity
  /// - Parameters:
  ///   - isEnabled: A Boolean value indicating whether the RealityUI Entity is enabled.
  ///   - respondsToLighting: A Boolean value indicating whether the RealityUI Entity materials respond to light.
  public init(isEnabled: Bool = true, respondsToLighting: Bool = false) {
    self.ruiEnabled = isEnabled
    self.respondsToLighting = respondsToLighting
  }
}

/// An interface used for all entities in the RealityUI package
public protocol HasRUI: Entity {
}
public extension HasRUI {
  /// A Boolean value that determines whether touch events are ignored on this RealityUI Entity
  var ruiEnabled: Bool {
    get { self.RUI.ruiEnabled }
    set {
      if self.RUI.ruiEnabled == newValue { return }
      self.RUI.ruiEnabled = newValue
      (self as? HasRUIMaterials)?.materialsShouldChange()
    }
  }

  /// A Boolean value that determines whether this Entity's materials respond to lighting
  var respondsToLighting: Bool {
    get { self.RUI.respondsToLighting }
    set {
      if self.RUI.respondsToLighting == newValue { return }
      self.RUI.respondsToLighting = newValue
      (self as? HasRUIMaterials)?.materialsShouldChange()
    }
  }

  /// Replace the current RUIComponent
  /// - Parameter RUI: new RUIComponent
  func replaceRUI(with RUI: RUIComponent) {
    self.RUI = RUI
    (self as? HasRUIMaterials)?.materialsShouldChange()
  }

  /// RealityUI Component for the entity.
  internal(set) var RUI: RUIComponent {
    get {
      if let ruiComp = self.components[RUIComponent.self] as? RUIComponent {
        return ruiComp
      } else {
        self.components[RUIComponent.self] = RUIComponent()
        return self.components[RUIComponent.self]!
      }
    }
    set {
      self.components[RUIComponent.self] = newValue
    }
  }

}

internal extension HasRUI {
  func getModel(part: String) -> ModelEntity? {
    self.findEntity(named: part) as? ModelEntity
  }
  func ruiOrientation() {
    if let startOrient = RealityUI.startingOrientation {
      self.orientation = startOrient
    }
  }
  func addModel(part: String) -> ModelEntity {
    if let modelPart = self.getModel(part: part) {
      return modelPart
    }
    let newModelPart = ModelEntity()
    newModelPart.name = part
    self.addChild(newModelPart)
    return newModelPart
  }
}

/// An interface used for RealityUI entities that have materials generated from colours
/// These materials change with ruiEnabled and `self.RUI.respondsToLighting`.
public protocol HasRUIMaterials: HasRUI {
  /// All RealityUI Entities should have a method for updating all the materials
  /// This is in case of disabling entities or changing their responsiveness to light.
  /// This method does not need to be called by outside of a RealityUI class.
  func updateMaterials()
}
extension HasRUIMaterials {
  fileprivate func materialsShouldChange() {
    self.updateMaterials()
  }
  func getMaterial(with color: Material.Color) -> Material {
    var alpha: CGFloat = 0
    #if os(macOS)
    alpha = color.alphaComponent
    #else
    color.getWhite(nil, alpha: &alpha)
    #endif
    let adjustedColor = color.withAlphaComponent(alpha * (self.ruiEnabled ? 1 : 0.5))
    if self.RUI.respondsToLighting {
      return SimpleMaterial(color: adjustedColor, isMetallic: false)
    }
    return UnlitMaterial(color: adjustedColor)
  }
}
