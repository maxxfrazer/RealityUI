# ``RealityUI/HasARTouch``

## Overview

HasARTouch makes it easy to add touch events similar to those seen with <doc:RUIControls>.

Creating a method that inherits the protocol ``HasARTouch`` lets you use the callback methods to add your own custom events to this AR object. ``arTouchUpdated(at:hasCollided:)`` is not only called when you move your finger, but on every new frame in the RealityKit scene.

If you want to use a specific plane, rather that the object's collision shape after the initial touch, just set-up the ``collisionPlane`` parameter. If it is set up, all touch event callbacks will have the collision location as the location on that plane. This is used in classes such as ``RUISlider``, so that you can keep moving the slider without needing to always touch the slider's thumb.

## Topics

### Touch Event Callbacks

- ``arTouchStarted(at:hasCollided:)``
- ``arTouchUpdated(at:hasCollided:)``
- ``arTouchEnded(at:hasCollided:)``
- ``arTouchCancelled()``
