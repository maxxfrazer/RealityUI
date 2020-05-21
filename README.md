# RealityUI

RealityUI is a collection of User Interface classes for RealityKit.
The classes included in RealityUI aim to offer familiar User Interface guidelines, but in a 3D setting for Augmented and Virtual Reality through RealityKit.

## Requirements

- iOS 13 (or macos 10.15 without drag gestures)
- Swift 5.2
- Xcode 11

## Content

- [Installation](#installation)
- [Usage](#usage)
- [RUIElements](#creating-realityui-entities)
  - [RUISwitch](#ruiswitch-creation)
  - [RUISlider](#ruislider-creation)
  - [RUIStepper](#ruistepper-creation)

RUIStepper is used to increment or decrement a value.


## Installation

### Swift Package Manager

Add the URL of this repository to your Xcode 11+ Project under `Swift Packages`.

`https://github.com/maxxfrazer/RealityUI.git`

## Usage

Add `import RealityUI` to the top of your swift file to start.

#### Registering RealityUI Components

All components used in RealityUI must be registered before they are used, simply call `RealityUI.registerComponents()` anywhere in your app before any classes starting with `RUI` are initialised to avoid issues with that. For more information on what is meant by registering components [see Apple's documentation here](https://developer.apple.com/documentation/realitykit/component/3243766-registercomponent).

#### Activating Gestures

If you plan on using RUISwitch or RUIStepper, then you should at least enable `.tap`
RUISlider uses `.pan`, but I would just recommend using `.all` to avoid issues, as these will inevitably move around ad RealityUI develops, and will not interfere with the rest of your RealityKit scene.

`arView.enableRealityUIGestures(.all)`

### Creating RealityUI Entities

For the sake of all these examples, the _Simple_ heading will create an Entity with no custom properties or callbacks, and for _Functional_, imagine there is a `ModelEntity` in the scene which we can reference from the variable `adjustmentCuboid`.

By default all RealityUI Entities are quite large. This is used to standardize the sizes so that you always know what to expect. For example, all UI thumbs are spheres with a diameter of 1 meter, which is 1 unit in RealityKit.

#### RUISwitch Creation

RUISwitch is a 3D toggle switch with an on and off state.
![RUISwitches with and without light responsiveness](media/switches_combined.gif)

Default bounding box is 2x1x1m

##### Simple

```swift
let newSwitch = RUISwitch()
```

##### Functional

This RUISwitch will respond to lighting, and will change a ModelEntity's material between a red and a green color.

```swift
let newSwitch = RUISwitch(
  RUI: RUIComponent(respondsToLighting: true),
  changedCallback: { mySwitch in
    adjustmentCuboid.model?.materials = [
      SimpleMaterial(
        color: rSwitch.isOn ? .green : .red,
        isMetallic: false
      )
    ]
  }
))
```

#### RUIStepper Creation

![RUIStepper with light responsiveness](media/stepper_light.gif)

Default bounding box is 2x1x0.25m

##### Simple

```swift
let newStepper = RUIStepper()
```

##### Functional

This RUIStepper will move a ModelEntity's y position up and down by 0.1m on each tap.

```swift
let stepper = RUIStepper(upTrigger: { _ in
  adjustmentCuboid.position.y += 0.1
}, downTrigger: { _ in
  adjustmentCuboid.position.y -= 0.1
})
```

#### RUISlider Creation
An interactive track to represent an interpolated value.

![RUISlider with light responsiveness](media/slider_light.gif)


Default bounding box is 10x1x1m (Including thumb)

##### Simple

```swift
let newSlider = RUISlider()
```

##### Functional

This RUISlider has a starting value of 0.9, meaning that the thumb will be positioned 90% of the way along. The callback function will happen every time the slider value changes (set with `isContinuous`). The callback function will adjust the x scale of an Entity to the slider's value (0-1), plus an arbitrary value of 0.1.

```swift
let newSlider = RUISlider(
  slider: SliderComponent(startingValue: 0.9, isContinuous: true)
) { (slider, state) in
  adjustmentCuboid.scale.x = slider.value + 0.1
}
```

#### More

To see more, check out [RealityUI+Examples](./RealityUI+Examples) in this repository.
