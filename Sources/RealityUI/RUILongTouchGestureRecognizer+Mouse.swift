//
//  File.swift
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
        if (entity == nil && entityComp == nil) || self.touchLocation == nil {
            return
        }
//        print(event.locationInWindow)

        let touchInView = self.arView.convert(event.locationInWindow, from: nil)

        if touchInView == self.touchLocation {
            return
        }
//        print("touchInView: \(touchInView)")
        self.touchLocation = touchInView
    }
    override func mouseUp(with event: NSEvent) {
        guard self.touchLocation != nil else {
            return
        }
        let (newPos, hasCollided) = getCollisionPoints(touchLocation!)
        self.touchLocation = nil
        entity?.arTouchEnded(at: newPos, hasCollided: hasCollided)
        self.entity = nil
        self.entityComp = nil
        self.viewSubscriber?.cancel()
    }
}
#endif
