//
//  FloatingPanel.swift
//  TimeViewer
//
//  Borderless, non-activating panel that floats above all windows (including
//  fullscreen apps) and can be dragged anywhere on screen.
//

import AppKit

final class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        // Visible on every Space and above fullscreen apps.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Transparent so the SwiftUI content can draw its own rounded, translucent card.
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        isMovableByWindowBackground = true   // drag from anywhere on the background
        becomesKeyOnlyIfNeeded = true        // only takes key focus for text input
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow
    }

    // Borderless windows are non-key by default; allow key so the add-timer
    // text fields accept input — without activating (stealing focus from) the app.
    override var canBecomeKey: Bool { true }
}
