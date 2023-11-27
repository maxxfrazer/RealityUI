# ``RealityUI/RUIDragComponent/DragComponentType``

`DragComponentType` is an enumeration used in your 3D interaction framework to specify the type of drag interaction a user can have with entities in a 3D environment. It plays a crucial role in defining the behavior of draggable entities and how they respond to user input. This enum facilitates the customization of interaction models, allowing developers to tailor the user experience to the specific needs of their application.

This documentation provides a comprehensive overview of each case within the `DragComponentType` enum and offers insights into their practical applications.

## Available Properties

The `DragComponentType` enum consists of three primary interaction types: `move`, `turn`, and `click`. Each of these types is designed to handle a specific kind of user interaction in a 3D space, providing a flexible and robust framework for handling touch inputs.

 - `move`: This case represents a movement interaction where an entity can be moved within the 3D environment.
   The movement can be restricted or guided by an optional `MoveConstraint` that defines how the movement behaves.
   Use this for interactions where entities need to be repositioned dynamically.

 - `turn`: This case represents a rotational interaction where an entity can be rotated around a specified axis.
   The axis is defined by a `SIMD3<Float>` representing the axis of rotation.
   This is useful for scenarios where an entity needs to be oriented or turned to face different directions.

 - `click`: This case represents a click-type interaction, typically used for selecting or interacting with an entity without moving or rotating it.
   It's often used for simple interactions like selecting, activating, or focusing on an entity within the 3D space.
   In contrast to ``RUITapComponent``, click interacts in a similar way to `touchUpInside`, where it will only execute
   if your touch in the 3D scene starts and ends on the model with this component.

### Move Interaction

The ``move(_:)`` case is used for translating entities in 3D space. It can optionally incorporate a `MoveConstraint` to limit or guide the movement along specific paths or planes. This type is ideal for applications where objects need to be repositioned or rearranged by the user.

```swift
// Example: Moving an entity along the x axis from -2 to 2
let dragComponent = RUIDragComponent(type: .move(.box(
    BoundingBox(min: [-2, 0, 0], max: [2, 0, 0])
)))
entity.components.set(dragComponent)
```

### Turn Interaction

The ``turn(axis:)`` case allows entities to be rotated around a specified axis. This is particularly useful in scenarios where orientation or perspective changes are required. The axis of rotation is defined using a `SIMD3<Float>`.

```swift
// Example: Rotating an entity around the y-axis
let dragComponent = RUIDragComponent(type: .turn(axis: [0, 1, 0]))
entity.components.set(dragComponent)
```

### Click Interaction

The ``click`` case is used for simple interactions like selecting or activating an entity. Unlike ``move(_:)`` and ``turn(axis:)``, `click` does not involve movement or rotation but is used to trigger specific actions upon user interaction.

```swift
// Example: Adding a click interaction
let dragComponent = RUIDragComponent(type: .click)
entity.addComponent(dragComponent)
```

By utilizing these interaction types, developers can create intuitive and engaging 3D experiences that respond fluidly to user inputs.

## Topics

### Enum Cases

- ``move(_:)``
- ``turn(axis:)``
- ``click``

## See Also

- ``RUIDragComponent``
- ``RUIDragDelegate``

