# ``RealityUI/RUIStepper``

A control for incrementing or decrementing a value.

## Overview

RUIStepper can be used for changing a value by either incrementing or decrementing based on a set value. This can also be used to cycle through a carousel of options by iterating over an array of elements.

To activate the stepper, the user must press and release from the same side of the stepper. Holding the stepper will not repeatedly call the increment/decrement event.

## Topics

### Creating a Stepper

- ``init()``
- ``init(upTrigger:downTrigger:)``
- ``init(style:upTrigger:downTrigger:)``
- ``init(stepper:rui:upTrigger:downTrigger:)``

### Stepper Value Updates

- ``upTrigger``
- ``downTrigger``

### Customising

- ``style``
- ``stepper``
- ``StepperComponent``
- ``HasStepper``
