//
//  File.swift
//  
//
//  Created by Max Cobb on 14/11/2023.
//

#if os(iOS)
import UIKit

internal extension RUILongTouchGestureRecognizer {
    /// Sent to the gesture recognizer when one or more fingers touch down in the associated view.
    /// - Parameters:
    ///   - touches: A set of UITouch instances in the event represented by event that represent the touches in the UITouch.Phase.began phase.
    ///   - event: A `UIEvent` object representing the event to which the touches belong.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard activeTouch == nil,
              let firstTouch = touches.first,
              let touchInView = touches.first?.location(in: self.arView),
              self.arView.frame.contains(touchInView)
        else {
            if let activeTouch = self.activeTouch {
                self.touchesCancelled([activeTouch], with: event)
            }
            return
        }
        if touches.count > 1 {
            self.touchesCancelled(touches, with: event)
            return
        }
        self.activeTouch = firstTouch
        if !globalTouchBegan(touchInView: touchInView) {
            self.touchesCancelled(touches, with: event)
            return
        }
        super.touchesBegan(touches, with: event)
        self.state = .began
    }
    /// Sent to the gesture recognizer when one or more fingers move in the associated view.
    /// - Parameters:
    ///   - touches: A set of `UITouch` instances in the event represented by event that represent touches in the `UITouch.Phase.moved` phase.
    ///   - event: A `UIEvent` object representing the event to which the touches belong.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard entity != nil || entityComp != nil,
              let activeTouch,
              touches.contains(activeTouch),
              let touchInView = self.activeTouch?.location(in: self.arView),
              self.arView.frame.contains(touchInView),
              touchInView != self.touchLocation
        else { return }

        self.touchLocation = touchInView
        super.touchesMoved(touches, with: event)
        self.state = .changed
    }

    /// Sent to the gesture recognizer when a system event (such as an incoming phone call) cancels a touch event.
    /// - Parameters:
    ///   - touches: A set of `UITouch` instances in the event represented by event that represent the touches in the `UITouch.Phase.cancelled` phase.
    ///   - event: A `UIEvent` object representing the event to which the touches belong.
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.clearTouch(touches, with: event, state: .cancelled)
    }

    /// Sent to the gesture recognizer when one or more fingers lift from the associated view.
    /// - Parameters:
    ///   - touches: A set of `UITouch` instances in the event represented by event that represent the touches in the `UITouch.Phase.ended` phase.
    ///   - event: A `UIEvent` object representing the event to which the touches belong.
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        self.clearTouch(touches, with: event, state: .ended)
    }

    private func clearTouch(_ touches: Set<UITouch>, with event: UIEvent, state: UIGestureRecognizer.State) {
        guard let activeTouch = self.activeTouch, touches.contains(activeTouch) else {
            return
        }
        self.activeTouch = nil
        guard let touchLocation = self.touchLocation else {
            return
        }
        if let entity {
            switch state {
            case .cancelled:
                entity.arTouchCancelled()
                super.touchesCancelled(touches, with: event)
            case .ended:
                let (newPos, hasCollided) = getCollisionPoints(touchLocation)
                entity.arTouchEnded(at: newPos, hasCollided: hasCollided)
                super.touchesEnded(touches, with: event)
            default:
                break
            }
        } else if let entityComp, let touchComponent = entityComp.components.get(RUIDragComponent.self) {
            switch state {
            case .cancelled:
                touchComponent.dragCancelled(entityComp)
                super.touchesCancelled(touches, with: event)
            case .ended:
                // _ = hasCollided
                guard let ray = self.arView.ray(through: touchLocation)
                else { return }
                touchComponent.dragEnded(entityComp, ray: ray)
                super.touchesEnded(touches, with: event)
            default:
                break
            }
        }
        self.touchLocation = nil
        self.entity = nil
        self.entityComp = nil
        self.viewSubscriber?.cancel()
        self.state = state
    }
}
#endif
