//
//  RUIText.swift
//  
//
//  Created by Max Cobb on 21/11/2020.
//

import CoreGraphics
import RealityKit
import CoreText

/// A RealityUI Text object to be added to a RealityKit scene.
open class RUIText: Entity, HasText, HasClick {
  /// Action to occus when the user taps on this Entity.
  public var tapAction: ((HasClick, SIMD3<Float>?) -> Void)? {
    didSet {
      self.updateCollision()
    }
  }

  /// Create a new RUIText object, adding text to your RealityKit scene.
  /// - Parameters:
  ///   - text: The text to render.
  ///   - width: The maximum width, in meters, of the text frame in the local coordinate system.
  ///   - height: The maximum height, in meters, of the text frame in the local coordinate system.
  ///   - font: The font to use.
  ///   - extrusion: The extent, in meters, of the extruded text in the z-axis direction.
  ///   - color: The color applied to the text mesh's material.
  public convenience init(
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
  ///   - textComponent: Details about the text object, including text, font, extrusion and more.
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
    self.ruiOrientation()
    self.makeModels()
  }

  internal func makeModels() {
    self.addModel(part: .textEntity)
      .look(at: [0, 0, 1], from: .zero, upVector: [0, 1, 0], relativeTo: self)
    self.setText(self.text)
  }

  /// Initialise the RUIText object with no text and default properties.
  required convenience public init() {
    self.init(textComponent: nil)
  }
}

/// Component containing all the data for the text to be rendered.
public struct TextComponent: Component {
  /// The text to render.
  public var text: String?
  /// The font to use.
  public var font: MeshResource.Font = .systemFont(ofSize: 0.1)
  /// The maximum width, in meters, of the text frame in the local coordinate system.
  /// Set to `0` (default) for unbounded.
  public var width: CGFloat = 0
  /// The maximum height, in meters, of the text frame in the local coordinate system.
  /// Set to `0` (default) for unbounded.
  public var height: CGFloat = 0
  #if os(iOS)
  /// The color of the text material. `.label` by default (iOS)
  public var color: Material.Color = .label
  #elseif os(macOS)
  /// The color of the text material. `.labelColor` by default (macOS)
  public var color: Material.Color = .labelColor
  #endif
  /// How the text should be aligned in the text frame
  public var alignment: CTTextAlignment = .center
  /// The extent, in meters, of the extruded text in the z-axis direction.
  public var extrusion: Float = 1
  /// How the text should wrap when reaching a frame boundary.
  public var lineBreakMode: CTLineBreakMode = .byWordWrapping

  internal enum UIPart: String {
    case textEntity
  }

  /// Create a new TextComponent, all values are optional
  /// - Parameters:
  ///   - text: The text to render.
  ///   - font: The font to use.
  ///   - width: The maximum width, in meters, of the text frame in the local coordinate system.
  ///   - height: The maximum height, in meters, of the text frame in the local coordinate system.
  ///   - color: The color of the text material. `.label`/`.labelColor` by default (iOS/macOS)
  ///   - alignment: How the text should be aligned in the text frame
  ///   - extrusion: The extent, in meters, of the extruded text in the z-axis direction.
  ///   - lineBreakMode: How the text should wrap when reaching a frame boundary.
  public init(
    text: String? = nil, font: MeshResource.Font? = nil,
    width: CGFloat? = nil, height: CGFloat? = nil, color: Material.Color? = nil,
    alignment: CTTextAlignment? = nil, extrusion: Float? = nil,
    lineBreakMode: CTLineBreakMode? = nil
  ) {
    if let text = text { self.text = text }
    if let font = font { self.font = font }
    if let width = width { self.width = width }
    if let height = height { self.height = height }
    if let color = color { self.color = color }
    if let alignment = alignment { self.alignment = alignment }
    if let extrusion = extrusion { self.extrusion = extrusion }
    if let lineBreakMode = lineBreakMode { self.lineBreakMode = lineBreakMode }
  }

  /// Create a new TextComponent using only the default values.
  public init() {}
}

/// An interface used for all entities that render text
public protocol HasText: HasRUIMaterials {}
public extension HasText {
  /// Component containing all the data for the text to be rendered.
  var textComponent: TextComponent {
    get { self.components[TextComponent.self] ?? TextComponent() }
    set { self.components[TextComponent.self] = newValue }
  }
  /// The text to render.
  var text: String? {
    get { self.textComponent.text }
    set {
      self.textComponent.text = newValue
      self.setText(newValue)
    }
  }

  /// ModelComponent containig the visual text
  internal var textModel: ModelComponent? {
    get { self.getModel(part: .textEntity)?.model }
    set { self.addModel(part: .textEntity).model = newValue }
  }

  /// The font to use.
  var font: MeshResource.Font {
    self.textComponent.font
  }
  /// The color of the text material.
  var color: Material.Color {
    self.textComponent.color
  }

  private func getModel(part: TextComponent.UIPart) -> ModelEntity? {
    return (self as HasRUI).getModel(part: part.rawValue)
  }

  internal func addModel(part: TextComponent.UIPart) -> ModelEntity {
    self.addModel(part: part.rawValue)
  }

  internal func getMaterials(
    for part: TextComponent.UIPart
  ) -> [Material] {
    switch part {
    case .textEntity:
      return [self.getMaterial(with: self.textComponent.color)]
    }
  }

  /// Update materials for all models in this RUIEntity
  func updateMaterials() {
    self.getModel(part: .textEntity)?.model?.materials = self.getMaterials(for: .textEntity)
  }

  /// Change the text currently presented on the HasText Entity
  /// - Parameter text: New text to be rendered.
  internal func setText(_ text: String?) {
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
      alignment: self.textComponent.alignment,
      lineBreakMode: self.textComponent.lineBreakMode
    )

    self.textModel = ModelComponent(
      mesh: textMesh,
      materials: [SimpleMaterial(color: self.textComponent.color, isMetallic: false)]
    )
    self.getModel(part: .textEntity)?.model = self.textModel
    guard let textModel = self.textModel else {
      return
    }
//    let textSize = textModel.mesh.bounds.extents
    let textOffset = -textModel.mesh.bounds.center
    self.getModel(part: .textEntity)?.position = [
      -textOffset.x,
      textOffset.y,
      0 // textSize.z / 2
    ]
    self.updateCollision()
  }
  internal func updateCollision() {
    guard let selfCol = (self as? HasClick) else {
      return
    }
    if selfCol.tapAction == nil {
      selfCol.collision = nil
      return
    }
    let visbounds = self.visualBounds(relativeTo: nil)
    selfCol.collision = CollisionComponent(
      shapes: [ShapeResource.generateBox(size: visbounds.extents).offsetBy(translation: visbounds.center)]
    )
  }
}

extension RUIText {
  #if os(iOS)
  /// Used as default larger text to be displayed in the scene
  static public var largeFont = MeshResource.Font(
    descriptor: .init(
      name: "Helvetica",
      size: 1),
    size: MeshResource.Font.systemFontSize / 20
  )

  /// Used as default medium text to be displayed in the scene
  static public var mediumFont = MeshResource.Font(
    descriptor: .init(
      name: "Helvetica",
      size: 1),
    size: MeshResource.Font.systemFontSize / 28
  )
  #elseif os(macOS)
  /// Used as default larger text to be displayed in the scene
  static public var largeFont = MeshResource.Font(
    descriptor: .init(
      name: "Helvetica",
      size: 1),
    size: MeshResource.Font.systemFontSize / 20
  ) ?? MeshResource.Font.systemFont(ofSize: MeshResource.Font.systemFontSize / 20)

  /// Used as default medium text to be displayed in the scene
  static public var mediumFont = MeshResource.Font(
    descriptor: .init(
      name: "Helvetica",
      size: 1),
    size: MeshResource.Font.systemFontSize / 28
  ) ?? MeshResource.Font.systemFont(ofSize: MeshResource.Font.systemFontSize / 28)
  #endif
}
