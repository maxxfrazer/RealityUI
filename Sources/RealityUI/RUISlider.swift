//
//  RUISlider.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import Foundation
import RealityKit

/// A  RealityUI Slider to be added to a RealityKit scene.
public class RUISlider: Entity, HasSlider, HasModel {

  public var collisionPlane: float4x4? {
    return self.transformMatrix(relativeTo: nil)
      * float4x4(simd_quatf(angle: .pi / 2, axis: [1, 0, 0]))
  }
  /// Called whenever the slider value updates.
  /// set isContinuous to `true` to get every change,
  /// `false` to just get start and end on each gesture.
  public var sliderUpdated: ((HasSlider, SliderComponent.SlidingState) -> Void)?

  /// Creates a RealityUI Slider entity with optional `SliderComponent`, `RUIComponent` and `updateCallback`.
  /// - Parameters:
  ///   - slider: Details about the slider to be set when initialized
  ///   - RUI: Details about the RealityUI Entity
  ///   - updateCallback: callback function to receive updates on slider value changes.
  required public init(
    slider: SliderComponent? = nil, RUI: RUIComponent? = nil,
    updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
  ) {
    self.sliderUpdated = updateCallback
    super.init()
    self.RUI = RUI ?? RUIComponent()
    self.slider = slider ?? SliderComponent()
    self.ruiOrientation()
    self.makeModels()
    self.setPercent(to: self.slider.value)
    self.updateCollision()
  }

  /// Creates a RealityUI Slider entity with default visual appearance
  /// - Parameters:
  ///   - length: Length of the slider. The default for RUISlider is 10m.
  ///   - start: Starting value for the slider.
  ///   - steps: An Integer value indicating how many steps the slider should have.
  ///            0 is fluid, 1 has only lowest and highest steps
  ///   - updateCallback: Callback function to receive updates on slider value changes.
  public convenience init(
    length: Float, start: Float, steps: Int,
    updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
  ) {
    self.init(
      slider: SliderComponent(length: length, startingValue: start, steps: steps),
      updateCallback: updateCallback)
  }

  /// Creates a RealityUI Slider entity with default visual appearance
  /// - Parameters:
  ///   - length: Length of the slider. The default for RUISlider is 10m.
  ///   - start: Starting value for the slider.
  ///   - updateCallback: Callback function to receive updates on slider value changes.
  required public convenience init(
    length: Float, start: Float = 0,
    updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
  ) {
    self.init(
      slider: SliderComponent(length: length, startingValue: start),
      updateCallback: updateCallback
    )
  }

  /// Create an RUISlider with default configurations
  required public convenience init() {
    self.init(length: 10)
  }

  /// Called when a new touch has begun on an Entity
  /// - Parameters:
  ///   - worldCoordinate: Collision of the object or collision plane
  ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
  public func arTouchStarted(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool = true) {
    let localPos = self.convert(position: worldCoordinate, from: nil)
    self.panGestureOffset = self.value - (0.5 - localPos.x / self.sliderLength)
    self.sliderUpdated?(self, .started)
  }
  /// Called when a touch is still on screen or a mouse is still down.
  /// - Parameters:
  ///   - worldCoordinate: Where is the touch currently hits in world space
  ///   - hasCollided: Is the touch colliding with the `CollisionComponent` or not.
  public func arTouchUpdated(_ worldCoordinate: SIMD3<Float>, hasCollided: Bool = true) {
    let localPos = self.convert(position: worldCoordinate, from: nil)
    var newPercent = (0.5 - localPos.x / self.sliderLength) + self.panGestureOffset
    self.clampSlideValue(&newPercent)
    if self.value == newPercent {
      return
    }
    self.setPercent(to: newPercent, animated: false)
    if self.isContinuous {
      self.sliderUpdated?(self, .updated)
    }
  }

  public func arTouchCancelled() {
    self.arTouchEnded(nil)
  }

  public func arTouchEnded(_ worldCoordinate: SIMD3<Float>? = nil) {
    self.panGestureOffset = 0
    updateCollision()
    self.sliderUpdated?(self, .ended)
  }
}

/// A collection of resources that create the visual appearance a RealityUI Slider, `RUISlider`.
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

  internal var arGestureOffset: Float = 0
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
public protocol HasSlider: HasPanTouch, HasRUIMaterials {
  /// Called whenever the slider value updates.
  /// set isContinuous to `true` to get every change,
  /// `false` to just get start and end on each gesture.
  var sliderUpdated: ((HasSlider, SliderComponent.SlidingState) -> Void)? { get set }
}

public extension HasSlider {

  internal var slider: SliderComponent {
    get { self.components[SliderComponent.self] ?? SliderComponent() }
    set { self.components[SliderComponent.self] = newValue }
  }
  internal var panGestureOffset: Float {
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

  /// Set the sliders position
  /// - Parameters:
  ///   - percent: A Float value representing the slider progression from start to end.
  ///   - animated: A Boolean value of whether the change in percentage should animate.
  func setPercent(to percent: Float, animated: Bool = false) {
    let percentClamped = min(max(percent, 0), 1)
    self.value = percentClamped
    self.updateThumb(to: self.getSliderPosition(for: .thumb), animated: animated)
    self.updateFill(to: self.getSliderPosition(for: .fill), animated: animated)
    self.updateEmpty(to: self.getSliderPosition(for: .empty), animated: animated)
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

  internal func updateCollision() {
    guard let thumb = self.getModel(part: .thumb)
      else { return }
    let collisionShape = ShapeResource.generateSphere(radius: 0.5)
      .offsetBy(translation: thumb.position)
    self.collision = CollisionComponent(shapes: [collisionShape])
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

    self.addModel(part: .thumb).model = ModelComponent(
      mesh: .generateSphere(radius: 0.5), materials: []
    )

    self.updateMaterials()
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
