import AppKit
import SwiftUI
import RemoteFitCore

/// App-wide single hover owner for the toolbar and frosted panels.
/// Remote touch clients teleport the cursor, so per-view enter/exit pairs go missing and
/// several buttons stayed highlighted. Hover is now derived from real pointer samples
/// (screen coordinates), at most one item is hovered, and taps, scrolls and the pointer
/// leaving our windows clear it.
@MainActor
final class PointerHover: ObservableObject {
    static let shared = PointerHover()
    @Published private(set) var hoveredID: String?
    private var tracker = HoverTracker<String>()
    private var monitors: [Any] = []

    private init() {
        let reset: (NSEvent) -> Void = { _ in MainActor.assumeIsolated { PointerHover.shared.reset() } }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel], handler: reset) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .scrollWheel], handler: { event in
            MainActor.assumeIsolated { PointerHover.shared.reset() }
            return event
        }) { monitors.append(local) }
    }

    func moved(over id: String?) {
        let buttonDown = NSEvent.pressedMouseButtons & 1 != 0
        tracker.pointerMoved(to: NSEvent.mouseLocation, over: id, buttonDown: buttonDown)
        publish()
    }
    func left(_ id: String) { tracker.leave(id); publish() }
    func reset() { if tracker.reset() { publish() } }
    func isHovered(_ id: String) -> Bool { hoveredID == id }
    private func publish() { if hoveredID != tracker.hoveredID { hoveredID = tracker.hoveredID } }
}

private struct PointerHoverModifier: ViewModifier {
    let id: String
    let changed: (Bool) -> Void
    @ObservedObject private var hover = PointerHover.shared
    func body(content: Content) -> some View {
        tracked(content)
            .onValueChange(of: hover.hoveredID == id) { now in changed(now) }
    }

    /// macOS 12 has no continuous hover; an AppKit tracking area feeds the same pointer samples.
    @ViewBuilder
    private func tracked(_ content: Content) -> some View {
        if #available(macOS 13, *) {
            content.onContinuousHover { phase in
                switch phase {
                case .active: hover.moved(over: id)
                case .ended: hover.left(id)
                }
            }
        } else {
            content.background(PointerHoverTracking(id: id))
        }
    }
}

private struct PointerHoverTracking: NSViewRepresentable {
    let id: String
    func makeNSView(context: Context) -> TrackingView { TrackingView(id: id) }
    func updateNSView(_ view: TrackingView, context: Context) { view.id = id }

    final class TrackingView: NSView {
        var id: String { didSet { if oldValue != id { PointerHover.shared.left(oldValue) } } }
        init(id: String) { self.id = id; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            trackingAreas.forEach(removeTrackingArea)
            addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect], owner: self))
        }
        override func mouseEntered(with event: NSEvent) { PointerHover.shared.moved(over: id) }
        override func mouseMoved(with event: NSEvent) { PointerHover.shared.moved(over: id) }
        override func mouseExited(with event: NSEvent) { PointerHover.shared.left(id) }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window == nil { PointerHover.shared.left(id) }
        }
    }
}

extension View {
    /// Single-owner hover for frosted panels; `changed` reports this item's hover state.
    func pointerHover(_ id: String, changed: @escaping (Bool) -> Void) -> some View {
        modifier(PointerHoverModifier(id: id, changed: changed))
    }
}
