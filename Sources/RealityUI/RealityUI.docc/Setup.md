# Setup

Setting up RealityUI, so you're able to start adding RUIControls.

## Overview

Follow the steps below to install the package, register RealityKit components, and activate all the RealityUI Gestures.

## Install

To install with Swift Package Manager, add the URL of this repository to your Xcode 12+ Project under `Project > Swift Packages`.

```
https://github.com/maxxfrazer/RealityUI.git
```

## Registering RealityUI Components

All components used in RealityUI must be registered before they are used, simply call ``RealityUI/RealityUI/registerComponents()`` anywhere in your app before any classes starting with `RUI` are initialised to avoid issues with that. For more information on what is meant by registering components [see Apple's documentation here](https://developer.apple.com/documentation/realitykit/component/3243766-registercomponent).

## Activating Gestures

Enabling RealityUI gestures can be doen by calling ``RealityUI/RealityUI/enableGestures(_:on:)``, with `ARView` being your instance of [ARView](https://developer.apple.com/documentation/realitykit/arview) object.

``RUISlider``, ``RUISwitch``, ``RUIStepper`` and ``RUIButton`` all use ``RealityUI/RealityUI/RUIGesture/ruiDrag``, and if you are adding elements that use the component `TapActionComponent` you can use the gesture ``RealityUI/RealityUI/RUIGesture/tap``.
I would just recommend using ``RealityUI/RealityUI/RUIGesture/all`` when enabling gestures, as these will inevitably move around as RealityUI develops.

```
RealityUI.enableGestures(.all, on: arView)
```
