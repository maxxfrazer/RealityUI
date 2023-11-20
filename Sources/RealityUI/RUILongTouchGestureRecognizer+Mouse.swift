//
//  RUILongTouchGestureRecognizer+Mouse.swift
//  
//
//  Created by Max Cobb on 15/11/2023.
//

import Foundation

#if os(macOS)
import AppKit

extension RUILongTouchGestureRecognizer {
    override func mouseDown(with event: NSEvent) {
        guard self.touchLocation == nil
        else {
            return
        }
        let touchInView = self.arView.convert(event.locationInWindow, from: nil)
        //    self.activeTouch = touches.first
        if !globalTouchBegan(touchInView: touchInView) {
            self.mouseUp(with: event)
            return
        }
        super.mouseDown(with: event)
    }
    override func mouseDragged(with event: NSEvent) {
        if (entity == nil && entityComp == nil) || self.touchLocation == nil { return }

        let touchInView = self.arView.convert(event.locationInWindow, from: nil)
        if touchInView == self.touchLocation { return }
        self.touchLocation = touchInView
    }
    override func mouseUp(with event: NSEvent) {
        guard let touchLocation else { return }
        if let entity {
            let (newPos, hasCollided) = getCollisionPoints(touchLocation)
            entity.arTouchEnded(at: newPos, hasCollided: hasCollided)
        } else if let entityComp, let ray = self.arView.ray(through: touchLocation) {
            entityComp.components.get(RUIDragComponent.self)?.dragEnded(entityComp, ray: ray)
        }
        self.touchLocation = nil
        self.entity = nil
        self.entityComp = nil
        self.viewSubscriber?.cancel()
    }
}
#endif
