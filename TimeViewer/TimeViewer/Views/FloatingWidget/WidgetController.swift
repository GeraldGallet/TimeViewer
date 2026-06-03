//
//  WidgetController.swift
//  TimeViewer
//
//  Owns the floating panel's lifecycle and visibility. Bridges the SwiftUI
//  content into the AppKit NSPanel and keeps the widget anchored by its
//  top-left corner so it grows downward as timers are added.
//

import SwiftUI
import AppKit
import Combine

final class WidgetController: NSObject, ObservableObject, NSWindowDelegate {
    /// Whether the user wants the widget on. The popover toggle binds to this.
    @Published private(set) var isEnabled = false

    private let store: TimerStore
    private let settings: WidgetSettings
    private let presetStore: PresetStore
    private var panel: FloatingPanel?
    /// Screen position of the widget's top-left corner; kept fixed across resizes.
    private var desiredTopLeft: NSPoint?

    /// True while the menu-bar popover is open. The widget is hidden during that
    /// time and restored (if still enabled) once the popover closes — so the menu
    /// and the widget are never on screen together.
    private var isMenuOpen = false
    private var popoverObservers: [NSObjectProtocol] = []

    init(store: TimerStore, settings: WidgetSettings, presetStore: PresetStore) {
        self.store = store
        self.settings = settings
        self.presetStore = presetStore
        super.init()
    }

    // MARK: - Intent

    /// Driven by the popover's toggle.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        // Turning it on from the popover closes the menu; the widget then appears
        // when the popover finishes closing (menuDidClose).
        if enabled { dismissMenuBarPopover() }
        updatePanelVisibility()
    }

    /// The widget's own ✕ button — turns the widget off entirely.
    func disable() {
        isEnabled = false
        updatePanelVisibility()
    }

    /// Popover opened: hide the widget for the duration of the menu.
    func menuDidOpen() {
        isMenuOpen = true
        updatePanelVisibility()
        observePopoverDismissal()
    }

    /// Popover closed: bring the widget back if it's still enabled.
    func menuDidClose() {
        guard isMenuOpen else { return }
        stopObservingPopover()
        isMenuOpen = false
        updatePanelVisibility()
    }

    // MARK: - Visibility

    private func updatePanelVisibility() {
        if isEnabled && !isMenuOpen {
            showPanel()
        } else {
            panel?.orderOut(nil)
        }
    }

    private func showPanel() {
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.orderFrontRegardless()
    }

    // MARK: - Popover coordination

    // Close the menu-bar popover so the widget is the single visible interface.
    // We close every visible window except our own panel and the status-bar
    // window (the icon), which works even when the app isn't frontmost.
    private func dismissMenuBarPopover() {
        for window in NSApp.windows where window !== panel && window.isVisible {
            guard !isStatusBarWindow(window) else { continue }
            window.close()
        }
        // Force-closing the popover skips MenuBarExtra's own teardown, which would
        // otherwise un-highlight the icon — so clear the button's selected state.
        deselectStatusBarButton()
    }

    private func deselectStatusBarButton() {
        for window in NSApp.windows where isStatusBarWindow(window) {
            guard let contentView = window.contentView,
                  let button = firstButton(in: contentView) else { continue }
            button.highlight(false)
        }
    }

    private func firstButton(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = firstButton(in: subview) { return button }
        }
        return nil
    }

    // Detect the popover closing via window notifications — SwiftUI's onDisappear
    // is unreliable for MenuBarExtra. A popover dismisses when it closes or
    // resigns key, so we listen for both.
    private func observePopoverDismissal() {
        stopObservingPopover()
        guard let popover = NSApp.windows.first(where: { window in
            window !== panel && window.isVisible && !isStatusBarWindow(window)
        }) else { return }

        let center = NotificationCenter.default
        let handler: (Notification) -> Void = { [weak self] _ in self?.menuDidClose() }
        popoverObservers = [
            center.addObserver(forName: NSWindow.willCloseNotification, object: popover, queue: .main, using: handler),
            center.addObserver(forName: NSWindow.didResignKeyNotification, object: popover, queue: .main, using: handler),
        ]
    }

    private func stopObservingPopover() {
        popoverObservers.forEach(NotificationCenter.default.removeObserver)
        popoverObservers.removeAll()
    }

    private func isStatusBarWindow(_ window: NSWindow) -> Bool {
        String(describing: type(of: window)).contains("StatusBar")
    }

    // MARK: - Panel construction

    private func makePanel() -> FloatingPanel {
        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 120))
        panel.delegate = self

        let rootView = FloatingWidgetView(onClose: { [weak self] in self?.disable() })
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(presetStore)
        let hosting = NSHostingController(rootView: rootView)
        hosting.sizingOptions = .preferredContentSize
        panel.contentViewController = hosting

        // Size to the SwiftUI content before placing it, so top-right is accurate.
        hosting.view.layoutSubtreeIfNeeded()
        let fitting = hosting.view.fittingSize
        if fitting.width > 0, fitting.height > 0 {
            panel.setContentSize(fitting)
        }

        positionTopRight(panel)
        return panel
    }

    private func positionTopRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let margin: CGFloat = 16
        let visible = screen.visibleFrame
        let topLeft = NSPoint(
            x: visible.maxX - panel.frame.width - margin,
            y: visible.maxY - margin
        )
        panel.setFrameTopLeftPoint(topLeft)
        desiredTopLeft = topLeft
    }

    // MARK: - NSWindowDelegate

    // Content height changes (timers added/removed, add form shown): re-pin the
    // top-left so the widget grows/shrinks downward rather than jumping upward.
    func windowDidResize(_ notification: Notification) {
        guard let panel, let topLeft = desiredTopLeft else { return }
        panel.setFrameTopLeftPoint(topLeft)
    }

    // User dragged the widget: remember the new anchor.
    func windowDidMove(_ notification: Notification) {
        guard let panel else { return }
        desiredTopLeft = NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
    }
}
