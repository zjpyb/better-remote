import Foundation

public extension Task where Success == Never, Failure == Never {
    /// `Task.sleep(for:)` needs macOS 13.
    static func sleep(seconds: TimeInterval) async throws {
        try await sleep(nanoseconds: UInt64(max(0, seconds) * 1_000_000_000))
    }
}
