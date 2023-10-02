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
    /// Stepper tally will be displayed at the top of the view when `RUIStepper` is visible.
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

        // Setup RealityKit camera
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 0, -2.5], relativeTo: nil)
        anchor.addChild(cam)

        self.setModel(view: arView)
        RealityUI.enableGestures(.all, on: arView)
        return arView
    }

    /// Update the model in the scene depending on ``objectType``
    /// - Parameter view: The `ARView` being displayed.
    func setModel(view: ARView) {
        guard let worldAnchor = view.scene.anchors.first,
            prevObjectType != objectType else { return }
        if let oldRui = view.scene.findEntity(named: "ruiReplace") {
            worldAnchor.removeChild(oldRui)
        }
        view.environment.background = .color(.gray)
        let ruiModel: Entity
        switch objectType {
        case .toggle:
            ruiModel = RUISwitch(switchCallback: { hasSwitch in
                view.environment.background = .color(hasSwitch.isOn ? .green : .gray)
            })
        case .text:
            let textObj = RUIText(textComponent: TextComponent(
                text: "hello", font: .systemFont(ofSize: 1),
                alignment: .center, extrusion: 0.1
            ))
            textObj.components.set(TapActionComponent { ent, _ in
                ent.ruiSpin(
                    by: [[1, 0, 0], [0, 1, 0], [0, 0, 1]].randomElement()!,
                    period: 0.3, times: 1
                )
            })
            textObj.updateCollision()
            ruiModel = textObj
        case .slider:
            let scalingCube = ModelEntity(mesh: .generateBox(size: 3))
            scalingCube.position.z = 3
            ruiModel = RUISlider(start: 0.5) { slider, state in
                scalingCube.scale = .one * (slider.value + 0.2) / 1.2
            }
            ruiModel.addChild(scalingCube)
            ruiModel.scale = .init(repeating: 0.3)
            scalingCube.scale = .one * ((ruiModel as! HasSlider).value + 0.2) / 1.2
        case .stepper:
            ruiModel = RUIStepper { _ in
                stepperTally += 1
            } downTrigger: { _ in
                stepperTally -= 1
            }
        case .button:
            ruiModel = RUIButton(
                rui: RUIComponent(respondsToLighting: true)
            ) { button in
                button.ruiShake(by: .init(angle: .pi / 16, axis: [0, 0, 1]), period: 0.05, times: 3)
            }
            ruiModel.look(at: [0, 1, -1], from: .zero, relativeTo: nil)
        case .rotation:
            ruiModel = RotationPlane(turnAxis: [0, 0, 1])
            ruiModel.scale = .one * 2
        }
        ruiModel.name = "ruiReplace"
        worldAnchor.addChild(ruiModel)
        DispatchQueue.main.async {
            prevObjectType = objectType
        }
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        setModel(view: uiView)
    }
}

/// Class for demonstrating the HasTurnTouch protocol.
class RotationPlane: Entity, HasModel, HasCollision, HasTurnTouch {

    /// Create a new ``RotationPlane``, which conforms to HasTurnTouch
    /// - Parameter turnAxis: Axis that the object will be rotated around.
    required init(turnAxis: SIMD3<Float>) {
        super.init()
        self.turnAxis = turnAxis
        var rotateMat = SimpleMaterial()
        rotateMat.color = SimpleMaterial.BaseColor(
            tint: .white.withAlphaComponent(0.99), texture: MaterialParameters.Texture(
                try! TextureResource.load(named: "rotato")
            )
        )
        self.model = ModelComponent(mesh: .generatePlane(width: 1, height: 1), materials: [rotateMat])
        self.orientation = .init(angle: .pi, axis: [0, 1, 0])
        self.collision = CollisionComponent(shapes: [.generateBox(width: 1, height: 1, depth: 0.1)])
    }

    @MainActor required init() {
        fatalError("init() has not been implemented")
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
