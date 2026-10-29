import Foundation

/// Official Better Remote site URLs. Keep one origin so help/API never diverge.
public enum BetterRemoteSite {
    public static let origin = URL(string: "https://betterremote.pincc.dev")!
    public static let help = origin.appendingPathComponent("help")
    public static let diagnosticLogs = origin.appendingPathComponent("api/diagnostic-logs")
    public static let rewardQR = origin.appendingPathComponent("qr/reward.png")
}
