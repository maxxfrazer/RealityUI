# ``RealityUI/RUIDragComponent``

## Overview

`RUIDragComponent` is a key class for your 3D environment, responsible for managing drag interactions. This component allows for sophisticated manipulation of entities in a 3D environment, leveraging various constraints to guide these interactions.

Adding the RUIDragComponent to an entity lets you quickly get some basic interactions in your RealityKit scene.

An example of adding a drag component can be as follows:

```swift
let freeMoveComponent = RUIDragComponent(type: .move(nil))
entity.components.set(freeMoveComponent)
```

This entity will now be able to be moved with 3 degrees of freedom, anywhere in your 3D scene.

These gestures will automatically be picked up on iOS and macOS if ``RealityUI/RealityUI/enableGestures(_:on:)`` has been called with ``RealityUI/RealityUI/RUIGesture/all`` or ``RealityUI/RealityUI/RUIGesture/ruiDrag`` applied in the parameters. 

For other platforms you may need to add a custom gesture recogniser to send through to your RealityKit scene.

## Topics

### Properties

- ``type``
- ``delegate``
- ``touchState``

### Drag Types

- ``DragComponentType``
- ``DragComponentType/move(_:)``
- ``DragComponentType/click``
- ``DragComponentType/turn(axis:)``

### Drag Event Callbacks

- ``RUIDragDelegate``
