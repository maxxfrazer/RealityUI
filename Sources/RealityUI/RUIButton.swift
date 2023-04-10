//
//  RUIButton.swift
//  
//
//  Created by Max Cobb on 5/22/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit.UIColor
#endif

/// A  RealityUI Button to be added to a RealityKit scene.
public class RUIButton: Entity, HasButton, HasModel, HasPhysics {

    public internal(set) var collisionPlane: float4x4?

    @available(*, deprecated, renamed: "touchUpInside")
    public var touchUpCompleted: ((HasButton) -> Void)? {
        get { self.touchUpInside}
        set { self.touchUpInside = newValue }
    }

    /// Function that will be called when button is successfully tapped.
    public var touchUpInside: ((HasButton) -> Void)?

    @available(*, deprecated, renamed: "init(button:rui:touchUpInside:)")
    public convenience init(
        button: ButtonComponent? = nil, RUI: RUIComponent? = nil,
        updateCallback: ((HasButton) -> Void)? = nil
    ) {
        self.init(button: button, rui: RUI, touchUpInside: updateCallback)
    }

    /// Creates a RealityUI Button entity with optional ``ButtonComponent``, ``RUIComponent`` and ``touchUpInside``.
    /// - Parameters:
    ///   - button: Details about the button to be set when initialized.
    ///   - rui: Details about the RealityUI Entity.
    ///   - touchUpInside: callback function to receive updates touchUpInside the RealityUI Button.
    required public init(
        button: ButtonComponent? = nil, rui: RUIComponent? = nil,
        touchUpInside: ((HasButton) -> Void)? = nil
    ) {
        self.touchUpInside = touchUpInside
        super.init()
        self.rui = rui ?? RUIComponent()
        self.button = button ?? ButtonComponent()
        self.ruiOrientation()
        self.makeModels()
    }

    /// Creates a default RealityUI Button
    required public convenience init() {
        self.init(button: nil)
    }

    public func arTouchStarted(at worldCoordinate: SIMD3<Float>, hasCollided: Bool) {
        self.compressButton()
    }

    public func arTouchUpdated(at worldCoordinate: SIMD3<Float>, hasCollided: Bool) {
        if hasCollided != self.isCompressed {
            if hasCollided {
                self.compressButton()
            } else {
                self.releaseButton()
            }
        }
    }

    public func arTouchCancelled() {
        if self.isCompressed {
            self.releaseButton()
        }
    }

    public func arTouchEnded(at worldCoordinate: SIMD3<Float>?, hasCollided: Bool?) {
        if self.isCompressed {
            self.releaseButton()
            self.touchUpInside?(self)
        }
    }

}

/// A collection of properties for the entities that conform to ``HasButton``.
public struct ButtonComponent: Component {
    /// Size of the RUIButton base.
    let size: SIMD3<Float>
    /// Color of the button.
    var buttonColor: Material.Color
    /// Color of the button base.
    var baseColor: Material.Color
    /// Padding (in meters) between the base and the button.
    let padding: Float
    /// Multiplyer amount that the button sticks out from the base when unpressed.
    /// The extrude amount will be a multiplier of the button z size
    let extrude: Float
    /// Multiplyer amount that the button sticks out from the base when pressed.
    /// The compress amount will be a multiplier of the button z size
    let compress: Float
    /// A corner radius applied to both the button and the button base.
    let cornerRadius: Float
    internal var isCompressed = false
    /// Style of button used.
    let style: ButtonComponent.Style

    internal enum UIPart: String {
        case button
        case base
    }
    /// Style for an RUIButton object
    public enum Style {
        /// A button style that is cuboid in shape.
        case rectangular
    }

    /// Default size of the button, if no properties are specifically set.
    public static let defaultSize: SIMD3<Float> = [1, 1, 0.2]

    /// Creates a ButtonComponent specifying the layout and appearance of a RUIButton
    /// - Parameters:
    ///   - size: Size of the RUIButton base
    ///   - buttonColor: Color of the button
    ///   - baseColor: Color of the button base
    ///   - padding: Padding (in meters) between the base and the button. Default 5% of the button's min(x, y) size.
    ///   - extrude: Multiplyer amount that the button sticks out from the base when unpressed.
    ///              The extrude amount will be a multiplier of the button z size
    ///   - compress: Multiplyer amount that the button sticks out from the base when pressed.
    ///               The compress amount will be a multiplier of the button z size
    ///   - cornerRadius: A corner radius applied to both the button and the button base.
    ///   - style: Style of RUIButton
    public init(
        size: SIMD3<Float> = ButtonComponent.defaultSize,
        buttonColor: Material.Color = .systemBlue,
        baseColor: Material.Color = .systemGray,
        padding: Float? = nil,
        extrude: Float = 0.5,
        compress: Float = 0.2,
        cornerRadius: Float? = nil,
        style: Style = .rectangular
    ) {
        self.size = size
        self.buttonColor = buttonColor
        self.baseColor = baseColor
        self.padding = padding ?? (min(size.x, size.y) * 0.05)
        assert(min(size.x, size.y) / 2 > self.padding, "Padding is too large for this button")
        self.extrude = extrude
        self.compress = compress
        self.cornerRadius = cornerRadius ?? self.size.min() * 0.2
        self.style = style
    }
    /// Create a new ButtonComponent with defautl values for a given style
    /// - Parameter style: Style of the button.
    public init(style: Style) {
        self.init(size: ButtonComponent.defaultSize, style: style)
    }

    /// Create a new rectangular style button.
    /// - Parameters:
    ///   - width: Width of the rectangular button
    ///   - height: Height of the rectangular button
    ///   - depth: Depth of the rectangular button
    ///   - padding: Padding (in meters) between the base and the button. Default 5% of the button's min(x, y) size.
    ///   - cornerRadius: A corner radius applied to both the button and the button base.
    public init(
        width: Float = 1, height: Float = 1, depth: Float = 0.2,
        padding: Float? = nil, cornerRadius: Float? = nil
    ) {
        self.init(size: [width, height, depth], padding: padding, cornerRadius: cornerRadius)
    }
}

/// An interface that provides a button component that defines the visual appearance.
public protocol HasButton: HasTouchUpInside, HasRUIMaterials {
    /// Button has been clicked callback, similar to UIKit `.touchUpInside`
    var touchUpInside: ((HasButton) -> Void)? { get set }
}

public extension HasButton {
    /// Properties of the button to be rendered
    internal(set) var button: ButtonComponent {
        get { self.components[ButtonComponent.self] ?? ButtonComponent() }
        set { self.components[ButtonComponent.self] = newValue }
    }

    /// Padding (in meters) between the base and the button. Default 0.1.
    var padding: Float { self.button.padding }
    /// Size of the RUIButton base
    var size: SIMD3<Float> { self.button.size }
    /// A corner radius applied to both the button and the button base.
    var cornerRadius: Float { self.button.cornerRadius }

    /// Multiplyer amount that the button sticks out from the base when unpressed.
    /// The extrude amount will be a multiplier of the button z size, which is 0.9 * the base
    var extrude: Float { self.button.extrude }
    /// Multiplyer amount that the button sticks out from the base when pressed.
    /// The compress amount will be a multiplier of the button z size, which is 0.9 * the base
    var compress: Float { self.button.compress }
    /// Color of the button
    var buttonColor: Material.Color {
        get { self.button.buttonColor }
        set {
            self.button.buttonColor = newValue
            self.updateMaterials()
        }
    }
    /// Color of the button base
    var baseColor: Material.Color {
        get { self.button.baseColor }
        set {
            self.button.baseColor = newValue
            self.updateMaterials()
        }
    }

    func updateMaterials() {
        self.getModel(part: .base)?.model?.materials = self.getMaterials(for: .base)
        self.getModel(part: .button)?.model?.materials = self.getMaterials(for: .button)
    }

    private func updateCollision() {
        guard let buttonInner = self.getModel(part: .button) else {
            return
        }
        let collShape = ShapeResource.generateBox(size: self.innerBoxSize).offsetBy(translation: buttonInner.position)
        self.collision = CollisionComponent(shapes: [collShape])
    }
    private func getModel(part: ButtonComponent.UIPart) -> ModelEntity? {
        return (self as HasRUI).getModel(part: part.rawValue)
    }
    private func addModel(part: ButtonComponent.UIPart) -> ModelEntity {
        return (self as HasRUI).addModel(part: part.rawValue)
    }
}

internal extension HasButton {
    var innerBoxSize: SIMD3<Float> {[
        self.size.x - self.padding * 2,
        self.size.y - self.padding * 2,
        self.size.z
    ]}
    var buttonOutPos: SIMD3<Float> {
        return [
            0, 0,
            -(self.button.size.z + self.innerBoxSize.z * (2 * extrude - 1)) / 2
        ]
    }
    var buttonInPos: SIMD3<Float> {
        return [
            0, 0,
            -(self.button.size.z + self.innerBoxSize.z * (2 * compress - 1)) / 2
        ]
    }

    var isCompressed: Bool {
        get { self.button.isCompressed }
        set { self.button.isCompressed = newValue}
    }
    func getMaterials(
        for part: ButtonComponent.UIPart
    ) -> [Material] {
        switch part {
        case .button:
            return [self.getMaterial(with: self.button.buttonColor)]
        case .base:
            return [self.getMaterial(with: self.button.baseColor)]
        }
    }

    func makeModels() {
        let buttonOuter = self.addModel(part: .base)
        buttonOuter.model = ModelComponent(
            mesh: .generateBox(
                size: self.size,
                cornerRadius: cornerRadius
            ), materials: []
        )
        let buttonInner = self.addModel(part: .button)
        let innerBoxSize = self.innerBoxSize
        buttonInner.model = ModelComponent(
            mesh: MeshResource.generateBox(
                size: innerBoxSize,
                cornerRadius: cornerRadius
            ), materials: []
        )
        buttonInner.position = self.buttonOutPos
        self.updateMaterials()
        self.updateCollision()
    }
    func compressButton() {
        guard let innerModel = self.getModel(part: .button) else {
            return
        }
        self.isCompressed = true
        innerModel.stopAllAnimations()
        innerModel.move(
            to: Transform(scale: .one, rotation: .init(), translation: self.buttonInPos),
            relativeTo: self, duration: 0.15
        )
    }
    func releaseButton() {
        guard let innerModel = self.getModel(part: .button) else {
            return
        }
        self.isCompressed = false
        innerModel.stopAllAnimations()
        innerModel.move(
            to: Transform(scale: .one, rotation: .init(), translation: self.buttonOutPos),
            relativeTo: self, duration: 0.15
        )
    }
}
