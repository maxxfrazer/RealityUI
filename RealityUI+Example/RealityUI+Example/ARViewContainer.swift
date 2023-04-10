//
//  ARViewContainer.swift
//  RealityUI+Example
//
//  Created by Max Cobb on 10/04/2023.
//

import Foundation
import RealityKit
import SwiftUI
import RealityUI
#if os(macOS)
typealias UIViewRepresentable = NSViewRepresentable
#endif

struct ARViewContainer: UIViewRepresentable {
    func makeNSView(context: Context) -> ARView {
        self.makeUIView(context: context)
    }

    func updateNSView(_ nsView: ARView, context: Context) {
        updateUIView(nsView, context: context)
    }

    typealias NSViewType = ARView


    @Binding var objectType: RealityObject
    @Binding var stepperTally: Int
    @State fileprivate var prevObjectType: RealityObject? = nil
    func makeUIView(context: Context) -> ARView {
        // Create an ARView
        let arView = ARView(frame: .zero)
        #if os(iOS)
        arView.cameraMode = .nonAR
        #endif

        // Add the anchor to the scene
        let anchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(anchor)
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 0, -2.5], relativeTo: nil)
        anchor.addChild(cam)

        self.setModel(view: arView)
        RealityUI.enableGestures(.all, on: arView)
        return arView
    }

    func setModel(view: ARView) {
        guard let worldAnchor = view.scene.anchors.first,
            prevObjectType != objectType else
        { return }
        if let oldRui = view.scene.findEntity(named: "ruiReplace") {
            worldAnchor.removeChild(oldRui)
        }
        view.environment.background = .color(.gray)
        switch objectType {
        case .toggle:
            let mySwitch = RUISwitch(switchCallback: { hasSwitch in
                view.environment.background = .color(hasSwitch.isOn ? .green : .gray)
            })
            mySwitch.name = "ruiReplace"
            worldAnchor.addChild(mySwitch)
        case .slider:
            let scalingCube = ModelEntity(mesh: .generateBox(size: 3))
            scalingCube.position.z = 3
            let slider = RUISlider(start: 1) { slider, state in
                scalingCube.scale = .one * (slider.value + 0.2) / 1.2
            }
            slider.addChild(scalingCube)
            slider.scale = .init(repeating: 0.3)
            slider.name = "ruiReplace"
            worldAnchor.addChild(slider)
        case .stepper:
            let stepper = RUIStepper { _ in
                stepperTally += 1
            } downTrigger: { _ in
                stepperTally -= 1
            }

            stepper.name = "ruiReplace"
            worldAnchor.addChild(stepper)
        case .button:
            let button = RUIButton(
                rui: RUIComponent(respondsToLighting: true)
            ) { button in
                button.ruiShake(by: .init(angle: .pi / 16, axis: [0, 0, 1]), period: 0.05, times: 3)
            }
            button.look(at: [0, 1, -1], from: .zero, relativeTo: nil)
            button.name = "ruiReplace"
            worldAnchor.addChild(button)
        }
        DispatchQueue.main.async {
            prevObjectType = objectType
        }
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        setModel(view: uiView)
    }
}

extension ARViewContainer {
    func switchAction(switch: HasSwitch) {

    }
}

struct ARViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ARViewContainer(objectType: .constant(.toggle), stepperTally: .constant(0))
    }
}
