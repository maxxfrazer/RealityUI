//
//  RealityUI.swift
//
//
//  Created by Max Cobb on 5/16/20.
//  Copyright © 2020 Max Cobb. All rights reserved.
//

import RealityKit
import Foundation
#if os(iOS)
import UIKit.UIGestureRecognizer
#elseif os(macOS)
import AppKit
#endif

import Combine

/// RealityUI contains some properties for RealityUI to run in your application.
/// ![RealityUI Banner](https://repository-images.githubusercontent.com/265939509/77c8eb00-a362-11ea-995e-482183f9acbd)
@objc public class RealityUI: NSObject {
    internal var componentsRegistered = false

    /// Registers all RealityUI's component types. Call this before creating any RealityUI classes to avoid issues.
    /// This method will be automatically called when ``enableGestures(_:on:)`` is called.
    public static func registerComponents() {
        RealityUI.shared.logActivated()
    }
    /// Orientation of all RealityUI Entities upon creation. If nil, none will be set.
    public static var startingOrientation: simd_quatf?

    /// Mask to exclude entities from being hit by the long/panning gesture
    public static var longGestureMask: CollisionGroup = .all

    /// Mask to exclude entities from being hit by the tap gesture.
    public static var tapGestureMask: CollisionGroup = .all

    /// Store all the RealityUI Animations for an Entity. It's important for memory management that this is empty when it should be.
    internal static var anims: [Entity: [String: Cancellable]] = [:]
    /// Use this to add GestureRecognisers for different RealityUI elements in your scene.
    /// You do not need multiple GestureRecognisers for multiple elements in the scene.
    /// - Parameters:
    ///   - gestures: A list of gestures to be installed, such as ``RUIGesture/ruiDrag`` and ``RUIGesture/tap``
    ///   - arView: ARView the gestures will be enabled on
    public static func enableGestures(_ gestures: RealityUI.RUIGesture, on arView: ARView) {
        RealityUI.shared.enable(gestures: gestures, on: arView)
    }

    private func logActivated() {
        RealityUI.RUIPrint("Activated, registered components")
    }
    internal static func RUIPrint(_ message: String) {
        print("RealityUI: \(message)")
    }
    private func registerComponents() {
        if self.componentsRegistered {
            return
        }
        for comp in RealityUI.RUIComponents {
            comp.registerComponent()
        }
        self.componentsRegistered = true
    }

    /// Different type of gestures used by RealityUI and set to an ARView object.
    public struct RUIGesture: OptionSet {
        /// Integer raw value used by the OptionSet
        public let rawValue: Int

        /// Initialise a new option set
        /// - Parameter rawValue: Integer raw value used by the OptionSet
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// OptionSet value for tap gestures.
        public static let tap = RUIGesture(rawValue: 1 << 0)

        /// OptionSet value for long touch gestures. This will catch all entities with ``RUIDragComponent`` and a collision body.
        public static let ruiDrag = RUIGesture(rawValue: 1 << 1)

        @available(*, deprecated, renamed: "ruiDrag")
        public static let longTouch = RUIGesture.ruiDrag

        /// Encapsulates all the possible values of this OptionSet
        public static let all: RUIGesture = [.tap, .ruiDrag]
    }

    /// Gestures that have been enabled, ``RUIGesture/tap``, ``RUIGesture/ruiDrag`` etc
    public internal(set) var enabledGestures: [ARView: RUIGesture] = [:]

    /// Gestures that have been installed. Plan to expose this property later.
    private var installedGestures: [ARView: [GestureBase]] = [:]

    /// All the components used by RealityUI
    public static var RUIComponents: [Component.Type] = [
        RUIComponent.self,
        ButtonComponent.self,
        SwitchComponent.self,
        StepperComponent.self,
        SliderComponent.self,
        TextComponent.self,
        RUITapComponent.self,
        RUIDragComponent.self
    ]

    internal static var shared = RealityUI()

    private override init() {
        super.init()
        self.registerComponents()
    }

    fileprivate func enable(gestures: RealityUI.RUIGesture, on arView: ARView) {
        if !self.enabledGestures.contains(where: { $0.key == arView}) {
            self.enabledGestures[arView] = []
        }
        let newGestures = gestures.subtracting(self.enabledGestures[arView] ?? [])
        if newGestures.isEmpty { return }
        if newGestures.contains(.tap) {
            self.addTap(to: arView)
        }
        if newGestures.contains(.ruiDrag) {
            self.addDragGesture(to: arView)
        }
        self.enabledGestures[arView]?.formUnion(newGestures)
    }
    private func addTap(to arView: ARView) {
        #if os(iOS)
        let addUITapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapReco))
        #elseif os(macOS)
        let addUITapGesture = NSClickGestureRecognizer(target: self, action: #selector(self.clickReco))
        #endif
        arView.addGestureRecognizer(addUITapGesture)
        self.installedGestures[arView]?.append(addUITapGesture)
    }
    private func addDragGesture(to arView: ARView) {
        let dragGesture = RUIDragGestureRecognizer(
            target: self, action: #selector(self.arTouchReco),
            view: arView
        )
        arView.addGestureRecognizer(dragGesture)
        self.installedGestures[arView]?.append(dragGesture)
    }

    #if os(macOS)
    @objc internal func clickReco(sender: NSGestureRecognizer) {
        guard let arView = sender.view as? ARView else {
            return
        }
        let tapInView = sender.location(in: arView)
        tapActionChecker(arView, tapInView)
    }
    #elseif os(iOS)
    @objc internal func tapReco(sender: UITapGestureRecognizer? = nil) {
        guard let arView = sender?.view as? ARView, let tapInView = sender?.location(in: arView) else {
            return
        }
        tapActionChecker(arView, tapInView)
    }
    #endif

    fileprivate func tapActionChecker(_ arView: ARView, _ tapInView: CGPoint) {
        if let ccHit = arView.hitTest(tapInView, mask: RealityUI.tapGestureMask).first,
           let comp = ccHit.entity.components[RUITapComponent.self] as? RUITapComponent {
            // if the element has RUIComponent, and it has `ruiEnabled` set to false
            if let ruiComp = ccHit.entity.components[RUIComponent.self] as? RUIComponent,
               !ruiComp.ruiEnabled {
                return
            }
            comp.action(ccHit.entity, ccHit.position)
        }
    }

    @objc internal func arTouchReco(sender: RUIDragGestureRecognizer) {}
}

public extension ARView {
    /// Use this method on your ARView to add GestureRecognisers for different RealityKit elements in your scene.
    /// You do not need multiple GestureRecognisers for multiple elements in the scene.
    /// - Parameter gestures: A list of gestures to be installed, such as ``RealityUI/RealityUI/RUIGesture/ruiDrag``
    /// and ``RealityUI/RealityUI/RUIGesture/tap``
    @available(*, deprecated, message: "Instead call RealityUI.enableGestures(:)")
    func enableRealityUIGestures(_ gestures: RealityUI.RUIGesture) {
        RealityUI.shared.enable(gestures: gestures, on: self)
    }
}

extension Entity.ComponentSet {
    func get<T>(_ component: T.Type) -> T? where T: Component {
        self[T.self] as? T
    }
}
