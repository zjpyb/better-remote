import AppKit
import SwiftUI

/// macOS 12/13 fallbacks for SwiftUI APIs the app uses; macOS 14+ takes the original path unchanged.
extension View {
    @ViewBuilder
    func onValueChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(macOS 14, *) {
            onChange(of: value) { _, new in action(new) }
        } else {
            onChange(of: value, perform: action)
        }
    }

    /// `.never` when `never`, otherwise `.hidden`. macOS 12 keeps the system scroller setting.
    @ViewBuilder
    func hidesScrollIndicators(never: Bool = false, axes: Axis.Set = [.vertical, .horizontal]) -> some View {
        if #available(macOS 13, *) { scrollIndicators(never ? .never : .hidden, axes: axes) } else { self }
    }

    @ViewBuilder
    func defaultScrollAnchorIfAvailable(_ anchor: UnitPoint?) -> some View {
        if #available(macOS 14, *) { defaultScrollAnchor(anchor) } else { self }
    }

    @ViewBuilder
    func onSizeChange<T: Equatable & Sendable>(_ transform: @escaping @Sendable (CGSize) -> T, action: @escaping (T) -> Void) -> some View {
        if #available(macOS 13, *) {
            onGeometryChange(for: T.self) { transform($0.size) } action: { action($0) }
        } else {
            background(GeometryReader { proxy in
                Color.clear
                    .onAppear { action(transform(proxy.size)) }
                    .onValueChange(of: transform(proxy.size), perform: action)
            })
        }
    }
}

extension Animation {
    static func snappyIfAvailable(duration: Double) -> Animation {
        if #available(macOS 14, *) { .snappy(duration: duration) } else { .easeInOut(duration: duration) }
    }
}

extension NSRunningApplication {
    /// macOS 14 activation is cooperative; before it a background agent must ignore the active app to bring this one forward.
    @discardableResult
    func activateFromAgent() -> Bool {
        if #available(macOS 14, *) { activate() } else { activate(options: .activateIgnoringOtherApps) }
    }
}

/// `sizingOptions` needs macOS 13; macOS 12 keeps the hosting defaults.
extension NSHostingView {
    func disableAutomaticSizing() {
        if #available(macOS 13, *) { sizingOptions = [] }
    }
}

extension NSHostingController {
    func disableAutomaticSizing() {
        if #available(macOS 13, *) { sizingOptions = [] }
    }

    func sizeToIntrinsicContent() {
        if #available(macOS 13, *) { sizingOptions = [.intrinsicContentSize] }
    }
}
