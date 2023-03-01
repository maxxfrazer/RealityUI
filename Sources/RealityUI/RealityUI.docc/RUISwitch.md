# ``RealityUI/RUISwitch``

``RUISwitch`` is a 3D toggle switch with an on and off state.
Default bounding box is approximately 1.6x1x1m

![RUISwitch floating around with an orange background](ruiswitch-orange-example.gif)

```swift
RUISwitch() { switch in
    print(switch.isOn)
}
```

## Topics

### Creating a Switch

- ``init()``
- ``init(switchness:rui:switchCallback:)``
- ``switchCallback``
- ``init(switchness:RUI:changedCallback:)``

### Customising The Switch

- ``switchness``
- ``SwitchComponent``
- ``HasSwitch``
