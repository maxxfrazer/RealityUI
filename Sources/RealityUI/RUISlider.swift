//
//  RUISlider.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import Foundation
import RealityKit
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit.UIColor
#endif

/// A  RealityUI Slider to be added to a RealityKit scene.
public class RUISlider: Entity, HasSlider, HasModel {

    /// Called whenever the slider value updates.
    /// set isContinuous to `true` to get every change,
    /// `false` to just get start and end on each gesture.
    public var sliderUpdateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)?

    @available(*, deprecated, renamed: "sliderUpdateCallback")
    public var sliderUpdated: ((HasSlider, SliderComponent.SlidingState) -> Void)? {
        get { self.sliderUpdateCallback }
        set { self.sliderUpdateCallback = newValue }
    }

    @available(*, deprecated, renamed: "init(slider:rui:sliderUpdateCallback:)")
    public convenience init(
        slider: SliderComponent? = nil, RUI: RUIComponent? = nil,
        updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
    ) {
        self.init(slider: slider, rui: RUI, sliderUpdateCallback: updateCallback)
    }

    /// Creates a RealityUI Slider entity with optional ``SliderComponent``, ``RUIComponent`` and ``sliderUpdated``.
    /// - Parameters:
    ///   - slider: Details about the slider to be set when initialized
    ///   - rui: Details about the RealityUI Entity
    ///   - sliderUpdated: callback function to receive updates on slider value changes.
    required public init(
        slider: SliderComponent? = nil, rui: RUIComponent? = nil,
        sliderUpdateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
    ) {
        self.sliderUpdateCallback = sliderUpdateCallback
        super.init()
        self.rui = rui ?? RUIComponent()
        self.slider = slider ?? SliderComponent()
        self.ruiOrientation()
        self.makeModels()
        self.setPercentInternal(to: self.slider.value, moveThumb: true)
    }

    /// Creates a RealityUI Slider entity with default visual appearance
    /// - Parameters:
    ///   - length: Length of the slider. The default for RUISlider is 10m.
    ///   - start: Starting value for the slider.
    ///   - steps: An Integer value indicating how many periods the slider should have.
    ///            0 is infinite, 1 has only lowest and highest steps.
    ///          See ``SliderComponent/steps`` for more information.
    ///   - updateCallback: Callback function to receive updates on slider value changes.
    public convenience init(
        length: Float = 10, start: Float = 0, steps: Int = 0,
        updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
    ) {
        self.init(
            slider: SliderComponent(length: length, startingValue: start, steps: steps),
            sliderUpdateCallback: updateCallback)
    }

    /// Create an ``RUISlider`` with default configurations
    required public convenience init() {
        self.init(length: 10)
    }

}

extension RUISlider: RUIDragDelegate {
    public func ruiDrag(_ entity: Entity, dragDidStart ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {
        self.sliderUpdateCallback?(self, .started)
    }
    public func ruiDrag(_ entity: Entity, dragDidUpdate ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {
        var newPercent = 0.5 - entity.position.x / sliderLength
        self.clampSlideValue(&newPercent)
        if self.value == newPercent { return }

        self.setPercentInternal(to: newPercent, animated: false)
        if self.isContinuous { self.sliderUpdateCallback?(self, .updated) }
    }
    public func ruiDrag(_ entity: Entity, dragDidEnd ray: (origin: SIMD3<Float>, direction: SIMD3<Float>)) {
        self.sliderUpdateCallback?(self, .ended)
    }
}

/// A collection of resources that create the visual appearance a RealityUI Slider, ``RUISlider``.
public struct SliderComponent: Component {
    /// Length of the slider. The default is 10m.
    public internal(set) var length: Float
    /// The slider's current value. Ranges from 0 to 1.
    public internal(set) var value: Float
    /// The color set to the material on the left side of the slider. Default `.systemBlue`
    public internal(set) var minTrackColor: Material.Color
    /// The color set to the material on the right side of the slider. Default `.systemGray`
    public internal(set) var maxTrackColor: Material.Color
    /// The color set to the material of the thumb. Default `.white`
    public internal(set) var thumbColor: Material.Color
    /// A Boolean value indicating whether changes in the slider’s value generate continuous update events.
    /// If set to true, you can receive all changes to the value,
    /// otherwise only at the start and end of changes made via touch.
    public var isContinuous: Bool
    /// The thickness of the track in meters, default is 0.2.
    public internal(set) var thickness: Float

    /// The nubmer of steps the slider should have.
    /// 0 (default) for continuous, no clamping.
    /// 1 would mean two possible values (0 and 1)
    /// 2 would allow 0, 0.5 and 1 etc.
    public internal(set) var steps: Int

    /// What stage the slider is in. Start is the first update, ended is the last, and updated
    /// means the slider is still updating, so you should expect another update on the next frame.
    public enum SlidingState {
        /// Slider has started updating.
        case started
        /// Slider has updated its value, but not for the first or last time in this update.
        case updated
        /// Slider has reached its final position for this update.
        case ended
    }

    internal var arGestureOffset: SIMD3<Float> = .zero

    internal enum UIPart: String {
        case thumb
        case empty
        case fill
    }

    /// Creates a SliderComponent using a list of completely optional parameters.
    /// - Parameters:
    ///   - length: Length of the slider. The default is 10m.
    ///   - startingValue: Starting value for the slider. Default 0
    ///   - minTrackColor: The color set to the material on the left side of the slider. Default `.systemBlue`
    ///   - maxTrackColor: The color set to the material on the right side of the slider. Default `.systemGray`
    ///   - thumbColor: The color set to the material of the thumb. Default `.white`
    ///   - thickness: The thickness of the track in meters, default is 0.2m.
    ///   - isContinuous: A Boolean value indicating whether changes in the slider’s value generate
    ///                   continuous update events. Default true.
    ///   - steps: An Integer value indicating how many steps the slider should have.
    public init(
        length: Float = 10,
        startingValue: Float = 0,
        minTrackColor: Material.Color = .systemBlue,
        maxTrackColor: Material.Color = .systemGray,
        thumbColor: Material.Color = .white,
        thickness: Float = 0.2,
        isContinuous: Bool = true,
        steps: Int = 0
    ) {
        self.length = length
        self.value = startingValue
        self.minTrackColor = minTrackColor
        self.maxTrackColor = maxTrackColor
        self.thumbColor = thumbColor
        self.thickness = thickness
        self.isContinuous = isContinuous
        self.steps = steps
    }
}

/// An interface used for an entity where a thumb is dragged along a fixed space.
public protocol HasSlider: HasRUIMaterials {
    /// Called whenever the slider value updates.
    /// set isContinuous to `true` to get every change,
    /// `false` to just get start and end on each gesture.
    var sliderUpdateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? { get set }

}

public extension HasSlider {

    internal var slider: SliderComponent {
        get { self.components[SliderComponent.self] ?? SliderComponent() }
        set { self.components[SliderComponent.self] = newValue }
    }
    var panGestureOffset: SIMD3<Float> {
        get { self.slider.arGestureOffset }
        set { self.slider.arGestureOffset = newValue }
    }
    /// Length of the slider. The default is 10m.
    var sliderLength: Float { self.slider.length }
    /// The slider's current value. Ranges from 0 to 1.
    internal(set) var value: Float {
        get { self.slider.value }
        set { self.slider.value = newValue }
    }

    /// The nubmer of steps the slider should have.
    /// 0 (default) for continuous, no clamping.
    /// 1 would mean two possible values (0 and 1)
    /// 2 would allow 0, 0.5 and 1 etc.
    var steps: Int {
        get { self.slider.steps }
        set { self.slider.steps = newValue }
    }
    /// A Boolean value indicating whether changes in the slider’s value generate continuous update events.
    /// If set to true, you can receive all changes to the value,
    /// otherwise only at the start and end of changes made via touch.
    var isContinuous: Bool {
        get { self.slider.isContinuous }
        set { self.slider.isContinuous = newValue }
    }
    /// The thickness of the track in meters, default is 0.2.
    var trackThickness: Float {
        self.slider.thickness
    }

    internal func setPercentInternal(to percent: Float, animated: Bool = false, moveThumb: Bool = false) {
        let percentClamped = min(max(percent, 0), 1)
        self.value = percentClamped
        if moveThumb { self.updateThumb(to: self.getSliderPosition(for: .thumb), animated: animated) }
        self.updateFill(to: self.getSliderPosition(for: .fill), animated: animated)
        self.updateEmpty(to: self.getSliderPosition(for: .empty), animated: animated)
    }

    /// Set the sliders position
    /// - Parameters:
    ///   - percent: A Float value representing the slider progression from start to end.
    ///   - animated: A Boolean value of whether the change in percentage should animate.
    func setPercent(to percent: Float, animated: Bool = false) {
        self.setPercentInternal(to: percent, animated: animated, moveThumb: true)
    }

    private func getSliderPosition(for part: SliderComponent.UIPart) -> SIMD3<Float> {
        switch part {
        case .fill:
            return [(0.5 - self.value / 2) * self.sliderLength, 0, 0]
        case .thumb:
            return [(0.5 - self.value) * self.sliderLength, 0, 0]
        case .empty:
            return [-self.value / 2 * self.sliderLength, 0, 0]
        }
    }

    internal func getMaterials(
        for part: SliderComponent.UIPart
    ) -> [Material] {
        switch part {
        case .empty:
            return [self.getMaterial(with: self.slider.maxTrackColor)]
        case .fill:
            return [self.getMaterial(with: self.slider.minTrackColor)]
        case .thumb:
            return [self.getMaterial(with: self.slider.thumbColor)]
        }
    }

    internal func clampSlideValue(_ newPercent: inout Float) {
        if self.steps <= 0 {
            return
        }
        let floatSteps = Float(self.steps)
        newPercent = roundf(newPercent * floatSteps) / floatSteps
    }

    private func getModel(part: SliderComponent.UIPart) -> ModelEntity? {
        return (self as HasRUI).getModel(part: part.rawValue)
    }
    private func addModel(part: SliderComponent.UIPart) -> ModelEntity {
        return (self as HasRUI).addModel(part: part.rawValue)
    }
    fileprivate func makeModels() {
        let length = self.sliderLength
        self.addModel(part: .empty).model = ModelComponent(
            mesh: .generateBox(size: [length, trackThickness, trackThickness], cornerRadius: trackThickness / 2),
            materials: []
        )

        self.addModel(part: .fill).model = ModelComponent(
            mesh: .generateBox(size: [length, trackThickness, trackThickness], cornerRadius: trackThickness / 2),
            materials: []
        )

        let thumb = self.addModel(part: .thumb)

        thumb.model = ModelComponent(
            mesh: .generateSphere(radius: 0.5), materials: []
        )
        thumb.collision = CollisionComponent(shapes: [.generateSphere(radius: 0.5)])
        #if os(visionOS)
        thumb.components.set(InputTargetComponent())
        #endif
        thumb.components.set(RUIDragComponent(
            type: .move(.clamp(self.clampThumb)),
            delegate: self as? RUIDragDelegate
        ))

        self.updateMaterials()
    }

    private func clampFloat(_ value: Float, minVal: Float, maxVal: Float) -> Float {
        min(max(value, minVal), maxVal)
    }

    private func clampThumb(input: SIMD3<Float>) -> SIMD3<Float> {
        let halfLen = self.sliderLength / 2
        var output: SIMD3<Float> = [min(max(input.x, -halfLen), halfLen), 0, 0]
        if self.steps == 0 {
            return output
        }
        let stepsFloat = Float(self.steps)

        // Calculate the step size
        let stepSize = self.sliderLength / stepsFloat

        // Find the closest step
        let closestStep = clampFloat(
            round((input.x + halfLen) / stepSize), minVal: 0, maxVal: stepsFloat
        )

        // Calculate and return the x-coordinate of the closest step
        output.x = -halfLen + stepSize * closestStep

        return output
    }

    func updateMaterials() {
        self.getModel(part: .empty)?.model?.materials = getMaterials(for: .empty)
        self.getModel(part: .fill)?.model?.materials = getMaterials(for: .fill)
        self.getModel(part: .thumb)?.model?.materials = getMaterials(for: .thumb)
    }

    private func updateThumb(to position: SIMD3<Float>, animated: Bool) {
        guard let thumb = self.findEntity(named: "thumb") as? ModelEntity else { return }
        thumb.stopAllAnimations()

        var thumbTransform = thumb.transform
        thumbTransform.translation = position
        if animated {
            thumb.move(to: thumbTransform, relativeTo: self, duration: 0.3)
        } else {
            thumb.transform = thumbTransform
        }
    }

    private func updateFill(to position: SIMD3<Float>, animated: Bool) {
        guard let fthread = self.findEntity(named: "fill") else {return}
        fthread.stopAllAnimations()
        var threadTransform = fthread.transform
        threadTransform.scale.x = self.value
        threadTransform.translation = position
        if animated {
            fthread.move(to: threadTransform, relativeTo: self, duration: 0.3)
        } else {
            fthread.transform = threadTransform
        }
    }

    private func updateEmpty(to position: SIMD3<Float>, animated: Bool) {
        guard let fthread = self.getModel(part: .empty) else {return}
        fthread.stopAllAnimations()
        var threadTransform = fthread.transform
        threadTransform.scale.x = 1 - self.value
        threadTransform.translation = position
        if animated {
            fthread.move(to: threadTransform, relativeTo: self, duration: 0.3)
        } else {
            fthread.transform = threadTransform
        }
    }
}
