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
    self.makeModels()
    self.setPercent(to: self.slider.value)
    self.updateCollision()
  }

  public convenience init(
    length: Float, start: Float, steps: Int,
    updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
  ) {
    self.init(
      slider: SliderComponent(length: length, startingValue: start, steps: steps),
      updateCallback: updateCallback)
  }

  required public convenience init(
    length: Float, start: Float = 0,
    updateCallback: ((HasSlider, SliderComponent.SlidingState) -> Void)? = nil
  ) {
    self.init(
      slider: SliderComponent(length: length, startingValue: start),
      updateCallback: updateCallback
    )
  }

  required public convenience init() {
    self.init(length: 10)
  }
}

/// A collection of resources that create the visual appearance a RealityUI Slider, `RUISlider`.
public struct SliderComponent: Component {
  /// Length of the slider. The default is 10m.
  var length: Float
  /// The slider's current value.
  var value: Float
  /// The color set to the material on the left side of the slider. Default `.systemBlue`
  var minTrackColor: Material.Color
  /// The color set to the material on the right side of the slider. Default `.systemGray`
  var maxTrackColor: Material.Color
  /// The color set to the material of the thumb. Default `.white`
  var thumbColor: Material.Color
  /// A Boolean value indicating whether changes in the slider’s value generate continuous update events.
  /// If set to true, you can receive all changes to the value,
  /// otherwise only at the start and end of changes made via touch.
  var isContinuous: Bool
  /// The thickness of the track in meters, default is 0.2.
  var thickness: Float

  /// The nubmer of steps the slider should have.
  /// 0 (default) for continuous, no clamping.
  /// 1 would mean two possible values (0 and 1)
  /// 2 would allow 0, 0.5 and 1 etc.
  var steps: Int

  public enum SlidingState {
    case started
    case updated
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

public protocol HasSlider: HasPanTouch {
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
  var sliderLength: Float { self.slider.length }
  internal(set) var value: Float {
    get { self.slider.value }
    set { self.slider.value = newValue }
  }

  var steps: Int {
    get { self.slider.steps }
    set { self.slider.steps = newValue }
  }
  var isContinuous: Bool {
    get { self.slider.isContinuous }
    set { self.slider.isContinuous = newValue }
  }
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
      return [(self.value / 2 - 0.5) * self.sliderLength, 0, 0]
    case .thumb:
      return [(-0.5 + self.value) * self.sliderLength, 0, 0]
    case .empty:
      return [(self.value / 2) * self.sliderLength, 0, 0]
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
  func arTouchStarted(_ worldCoordinate: SIMD3<Float>) {
    let localPos = self.convert(position: worldCoordinate, from: nil)
    self.panGestureOffset = self.value - (localPos.x / self.sliderLength + 1 / 2)
    self.sliderUpdated?(self, .started)
  }
  private func clampSlideValue(_ newPercent: inout Float) {
    if self.steps <= 0 {
      return
    }
    let floatSteps = Float(self.steps)
    newPercent = roundf(newPercent * floatSteps) / floatSteps
  }
  func arTouchUpdated(_ worldCoordinate: SIMD3<Float>) {
    let localPos = self.convert(position: worldCoordinate, from: nil)
    var newPercent = (localPos.x / self.sliderLength + 1 / 2) + self.panGestureOffset
    self.clampSlideValue(&newPercent)
    if self.value == newPercent {
      return
    }
    self.setPercent(to: newPercent, animated: false)
    if self.isContinuous {
      self.sliderUpdated?(self, .updated)
    }
  }

  func arTouchEnded(_ worldCoordinate: SIMD3<Float>? = nil) {
    self.panGestureOffset = 0
    updateCollision()
    self.sliderUpdated?(self, .ended)
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
