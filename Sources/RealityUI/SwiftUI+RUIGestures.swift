//
//  RUIDragDelegate.swift
//  
//
//  Created by Max Cobb on 20/11/2023.
//

import RealityKit
import SwiftUI

#if os(visionOS)
public extension View {
    func addRUIDragGesture() -> some View {
        self.gesture(RUIDragGesture())
    }
    func addRUITapGesture() -> some View {
        self.gesture(RUITapGesture())
    }
}

public struct RUITapGesture: Gesture {

    public init() {}

    public var body: some Gesture {
        TapGesture().targetedToEntity(where: .has(RUITapComponent.self))
            .onEnded { value in
                value.entity.components.get(RUITapComponent.self)?.action(value.entity, nil)
            }
    }
}

internal extension EntityTargetValue where Value == DragGesture.Value {
    var ray3D: Ray3D? {
        guard let devicePose = self.inputDevicePose3D, let parent = self.entity.parent else { return nil }
        let devicePos = self.convert(devicePose.position, from: .local, to: .scene)
        let endPos = self.convert(self.location3D, from: .local, to: .scene)
        let direction = endPos - devicePos
//        print(endPos)
        return Ray3D(origin: devicePos, direction: direction)
    }
}

extension Ray3D {
    var rayTuple: (SIMD3<Float>, SIMD3<Float>) {
        (origin.vector.toFloat3(), direction.vector.toFloat3())
    }
}

public struct RUIDragGesture: Gesture {
    public var body: some Gesture {
        DragGesture(minimumDistance: 0).targetedToEntity(where: .has(RUIDragComponent.self))
            .onChanged { value in
                guard let touchRay = value.ray3D,
                      let dragComp = value.entity.components[RUIDragComponent.self] else {
                    return
                }
//                print(value.location3D)
                if value.entity.components[RUIComponent.self]?.ruiEnabled == false { return }

                if dragComp.touchState == nil {
                    dragComp.dragStarted(value.entity, ray: touchRay.rayTuple)
                } else {
                    dragComp.dragUpdated(value.entity, ray: touchRay.rayTuple, hasCollided: true)
                }
            }.onEnded { value in
                guard let dragComp = value.entity.components[RUIDragComponent.self],
                      dragComp.touchState != nil, let touchRay = value.ray3D
                else { return }
                dragComp.dragEnded(value.entity, ray: touchRay.rayTuple)
            }
    }
    public init() {
        print("making new draggy")
    }
}
#endif
