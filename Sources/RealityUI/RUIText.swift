//
//  RUIText.swift
//  
//
//  Created by Max Cobb on 21/11/2020.
//

import CoreGraphics
import RealityKit

/// A  RealityUI Text object to be added to a RealityKit scene.
open class RUIText: Entity, HasText, HasClick {
  public var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? {
    didSet {
      self.updateCollision()
    }
  }

  convenience init(
    with text: String, width: CGFloat = 0, height: CGFloat = 0,
    font: MeshResource.Font = RUIText.mediumFont, extrusion: Float = 0.1,
    color: Material.Color = .green
  ) {
    let textComponent = TextComponent(
      text: text, font: font,
      width: width, height: height,
      color: color, extrusion: extrusion
    )
    self.init(textComponent: textComponent)
  }

  /// Creates a RealityUI Text entity.
  /// - Parameters:
  ///   - textComponent: Details about the text object, including text, font, extrusion and others.
  ///   - RUI: Details about the RealityUI Entity.
  ///   - tapAction: callback function to receive updates touchUpInside the RealityUI Text.
  required public init(
    textComponent: TextComponent? = nil, RUI: RUIComponent = RUIComponent(),
    tapAction: ((HasClick, SIMD3<Float>?) -> Void)? = nil
  ) {
    self.tapAction = tapAction
    super.init()
    self.RUI = RUI
    self.textComponent = textComponent ?? TextComponent()
    self.makeModels()
  }

  func makeModels() {
    self.addModel(part: .textEntity)
      .look(at: [0, 0, 1], from: .zero, upVector: [0, 1, 0], relativeTo: self)
    self.setText(self.text)
  }

  required public init() {
    fatalError("init() has not been implemented")
  }
}

public struct TextComponent: Component {
  var text: String? = nil
  var font: MeshResource.Font = .systemFont(ofSize: 0.1)
  var width: CGFloat = 0
  var height: CGFloat = 0
  #if os(iOS)
  var color: Material.Color = .label
  #elseif os(macOS)
  var color: Material.Color = .labelColor
  #endif
  var extrusion: Float = 1

  enum UIPart: String {
    case textEntity
  }
}

public protocol HasText: HasRUI {}
public extension HasText {
  var textComponent: TextComponent {
    get { self.components[TextComponent.self] ?? TextComponent() }
    set { self.components[TextComponent.self] = newValue }
  }
  var text: String? {
    get { self.textComponent.text }
    set {
      self.setText(newValue)
    }
  }

  var textModel: ModelComponent? {
    get { self.getModel(part: .textEntity)?.model }
    set { self.addModel(part: .textEntity).model = newValue }
  }

  var font: MeshResource.Font {
    self.textComponent.font
  }
  var color: Material.Color {
    self.textComponent.color
  }

  private func getModel(part: TextComponent.UIPart) -> ModelEntity? {
    return (self as HasRUI).getModel(part: part.rawValue)
  }

  internal func addModel(part: TextComponent.UIPart) -> ModelEntity {
    self.addModel(part: part.rawValue)
  }


  func updateMaterials() {
    self.getModel(part: .textEntity)?.model?.materials = [self.getMaterial(with: self.textComponent.color)]
  }
  func setText(_ text: String?) {
    guard let text = text else {
      self.getModel(part: .textEntity)?.model = nil
      return
    }
    let textMesh = MeshResource.generateText(
      text,
      extrusionDepth: self.textComponent.extrusion,
      font: self.font,
      containerFrame: .init(
        origin: .zero,
        size: CGSize(width: self.textComponent.width, height: self.textComponent.height)),
      alignment: .center,
      lineBreakMode: .byWordWrapping
    )

    self.textModel = ModelComponent(mesh: textMesh, materials: [SimpleMaterial(color: self.textComponent.color, isMetallic: false)])
    self.getModel(part: .textEntity)?.model = self.textModel
    guard let textModel = self.textModel else {
      return
    }
    let textSize = textModel.mesh.bounds.extents
    let textOffset = -textModel.mesh.bounds.center
    self.getModel(part: .textEntity)?.position = [
      -textOffset.x,
      textOffset.y,
      -textSize.z / 2
    ]
    self.updateCollision()
  }
  func updateCollision() {
    guard let selfCol = (self as? HasClick) else {
      return
    }
    if selfCol.tapAction == nil {
      selfCol.collision = nil
      return
    }
    let visbounds = self.visualBounds(relativeTo: nil)
    selfCol.collision = CollisionComponent(
      shapes: [ShapeResource.generateBox(size: visbounds.extents)
                .offsetBy(translation: visbounds.center)]
    )
  }
}

extension RUIText {
  /// Used as default larger text to be displayed in the scene
  static var largeFont = MeshResource.Font(
    descriptor: .init(
      name: "Helvetica",
      size: 1),
    size: MeshResource.Font.systemFontSize / 20
  ) ?? MeshResource.Font.systemFont(ofSize: MeshResource.Font.systemFontSize / 20)

  /// Used as default medium text to be displayed in the scene
  static var mediumFont = MeshResource.Font(
    descriptor: .init(
      name: "Helvetica",
      size: 1),
    size: MeshResource.Font.systemFontSize / 28
  ) ?? MeshResource.Font.systemFont(ofSize: MeshResource.Font.systemFontSize / 28)
}
