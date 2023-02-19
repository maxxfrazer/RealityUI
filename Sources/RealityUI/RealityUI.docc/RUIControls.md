# RUIControls

RUIControls are all the elements such as ``RUISlider``, ``RUISwitch``, ``RUIStepper`` and ``RUIButton``.

## Overview

Look below to see how to add all the RUIControls to your RealityKit Scene. Make sure to check out <doc:Setup> before adding RUIControls; otherwise the touch gestures may not work.

## Control Types

### RUISwitch

``RUISwitch`` is a 3D toggle switch with an on and off state.
Default bounding box is approximately 1.6x1x1m

#### Basic Implementation

```swift
let newSwitch = RUISwitch(
  changedCallback: { mySwitch in
    print(mySwitch.isOn ? "on" : "off")
  }
)
```

> The above will print "on" or "off", depending on the switch's new state.

![RUISwitch floating around with an orange background](ruiswitch-orange-example)

----

While this DocC page is being built out, head to [RealityUI's GitHub Wiki](https://github.com/maxxfrazer/RealityUI/wiki/Control-Entities) for more informatin about the control entities.
