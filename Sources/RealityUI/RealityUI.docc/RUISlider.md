# ``RealityUI/RUISlider``

RUISlider is perfect for interpolating a value.

![RealityUI Slider](ruislider-orange-example)

```swift
RUISlider(length: 4, start: 2 / 4) {
    print(slider.value)
}
```

## Topics

### Creating a Slider

- ``init()``
- ``init(length:start:steps:updateCallback:)``
- ``init(slider:rui:sliderUpdateCallback:)``
- ``init(slider:RUI:updateCallback:)``

### Slider Value Updates

- ``sliderUpdateCallback``
- ``value``
- ``setPercent(to:animated:)``
- ``isContinuous``

### Slider Properties

- ``steps``
- ``RUISlider/sliderLength``
- ``SliderComponent``
- ``HasSlider``
