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
        arView.cameraMode = .ar
        #endif

        // Add the anchor to the scene
        #if os(iOS)
        let anchor = AnchorEntity(world: [0, 0, -2])
        anchor.scale *= 0.5
        #else
        let anchor = AnchorEntity(world: .zero)
        #endif
        arView.scene.addAnchor(anchor)

        arView.debugOptions.insert(.showPhysics)
        // Setup RealityKit camera
        #if os(macOS)
        let cam = PerspectiveCamera()
        cam.look(at: .zero, from: [0, 0, -3], relativeTo: nil)
        anchor.addChild(cam)
        #endif

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
        let smallMove: Float = .random(in: 0.1...0.4)
        switch objectType {
        case .mover:
            ruiModel = Entity()
            for idx in 0...5 {
                let modEnt = ModelEntity(
                    mesh: .generateBox(width: 0.5, height: 0.5, depth: 0.5, splitFaces: true),
                    materials: [
                        SimpleMaterial(color: .blue, isMetallic: false),
                        SimpleMaterial(color: .yellow, isMetallic: false),
                        SimpleMaterial(color: .orange, isMetallic: false),
                        SimpleMaterial(color: .purple, isMetallic: false),
                        SimpleMaterial(color: .green, isMetallic: false),
                        SimpleMaterial(color: .red, isMetallic: false)
                    ].shuffled()
                )
                modEnt.generateCollisionShapes(recursive: false)
                modEnt.components.set(RUIDragComponent(
                    type: .move(.box(
                        BoundingBox(min: [-2, -1, -1], max: [2, 1, 1])
                    ))
                ))
                modEnt.position.x = 2 * sin(
                    Float(idx) / 3 * .pi + smallMove
                )
                modEnt.position.y = cos(
                    Float(idx) / 3 * .pi + smallMove
                )
                ruiModel.addChild(modEnt)
            }
            let container = ModelEntity(
                mesh: .generateBox(width: 4.5, height: 2.5, depth: 2.5),
                materials: [SimpleMaterial(color: .white.withAlphaComponent(0.2), isMetallic: false)]
            )
            container.scale *= -1
            ruiModel.addChild(container)
        case .toggle:
            ruiModel = RUISwitch(switchCallback: { hasSwitch in
                view.environment.background = .color(hasSwitch.isOn ? .green : .gray)
            })
        case .text:
            let textObj = RUIText(textComponent: TextComponent(
                text: "hello", font: .systemFont(ofSize: 1),
                alignment: .center, extrusion: 0.1
            ))
            textObj.components.set(RUITapComponent { ent, _ in
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
            ruiModel = RUISlider(length: 7, start: 0.5, steps: Bool.random() ? 4 : 0) { slider, state in
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
            ruiModel = RotationPlane()
            // stand up the model, so it's facing the camera
            ruiModel.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])

            // set the turn/rotation component
            ruiModel.components.set(RUIDragComponent(type: .turn(axis: [0, 0, 1])))
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
class RotationPlane: Entity, HasModel, HasCollision {

    /// Create a new ``RotationPlane``, which conforms to HasTurnTouch
    /// - Parameter turnAxis: Axis that the object will be rotated around.
    required init() {
        super.init()
        var rotateMat = SimpleMaterial()
        rotateMat.color = SimpleMaterial.BaseColor(
            tint: .white.withAlphaComponent(0.99), texture: MaterialParameters.Texture(
                try! TextureResource.load(named: "rotato")
            )
        )
        self.scale = .one * 2

        self.model = ModelComponent(mesh: .generatePlane(width: 1, height: 1), materials: [rotateMat])
        self.collision = CollisionComponent(shapes: [.generateBox(width: 1, height: 1, depth: 0.1)])
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
