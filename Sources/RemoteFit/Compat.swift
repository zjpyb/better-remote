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
