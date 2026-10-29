import XCTest
@testable import RemoteFit

@MainActor
final class NoticeLifetimeTests: XCTestCase {
    @MainActor
    private final class ManualSleeper {
        var durations: [TimeInterval] = []
        var waits: [CheckedContinuation<Void, Never>] = []

        func sleep(_ duration: TimeInterval) async {
            durations.append(duration)
            await withCheckedContinuation { waits.append($0) }
        }
    }

    func testNoticeExpiresAfterRequestedThreeSecondLifetime() async throws {
        let sleeper = ManualSleeper()
        let lifetime = NoticeLifetime(sleep: { await sleeper.sleep($0) })
        var expired = false
        lifetime.restart { expired = true }
        try await wait { sleeper.waits.count == 1 }
        XCTAssertEqual(sleeper.durations, [3])
        XCTAssertFalse(expired)
        sleeper.waits[0].resume()
        try await wait { expired }
    }

    func testRepeatedNoticeGetsFreshLifetimeAndOldDeadlineCannotDismissIt() async throws {
        let sleeper = ManualSleeper()
        let lifetime = NoticeLifetime(sleep: { await sleeper.sleep($0) })
        var oldExpired = false
        var newExpired = false
        lifetime.restart { oldExpired = true }
        try await wait { sleeper.waits.count == 1 }
        lifetime.restart { newExpired = true }
        try await wait { sleeper.waits.count == 2 }
        // The fake clock deliberately completes the cancelled wait as well.
        sleeper.waits[0].resume()
        sleeper.waits[1].resume()
        try await wait { newExpired }
        XCTAssertFalse(oldExpired)
        XCTAssertEqual(sleeper.durations, [3, 3])
    }

    func testDismissCancelsPendingExpiryEvenIfSleepReturnsNormally() async throws {
        let sleeper = ManualSleeper()
        let lifetime = NoticeLifetime(sleep: { await sleeper.sleep($0) })
        var expired = false
        lifetime.restart { expired = true }
        try await wait { sleeper.waits.count == 1 }
        lifetime.cancel()
        sleeper.waits[0].resume()
        // A second lifetime is a scheduler barrier, without relying on a delay.
        var barrier = false
        lifetime.restart { barrier = true }
        try await wait { sleeper.waits.count == 2 }
        sleeper.waits[1].resume()
        try await wait { barrier }
        XCTAssertFalse(expired)
    }

    private func wait(_ condition: () -> Bool) async throws {
        let deadline = ProcessInfo.processInfo.systemUptime + 2
        while !condition() {
            guard ProcessInfo.processInfo.systemUptime < deadline else {
                XCTFail("Notice lifecycle did not reach the expected state")
                throw CancellationError()
            }
            await Task.yield()
        }
    }
}
