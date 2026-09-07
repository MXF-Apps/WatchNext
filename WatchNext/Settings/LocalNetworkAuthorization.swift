import Foundation
import Network

/// Local network permission as far as the app can tell.
enum LocalNetworkAccess: String, Equatable, Sendable {
    /// Never asked, or the last check could not decide (timed out, no network).
    case unknown
    /// A check started from the Settings button is in flight.
    case checking
    case granted
    case denied
}

/// Triggers the iOS Local Network prompt and reports how it went.
///
/// iOS has no API that returns the local network permission. The workaround
/// Apple recommends is to advertise a Bonjour service and browse for it from the
/// same process: browsing finds the service when access is allowed and fails
/// with `kDNSServiceErr_PolicyDenied` when the user refused. Doing both also
/// makes the system show the permission prompt the first time.
///
/// Each check runs its own listener and browser and tears them down as soon as
/// it resolves, so nothing keeps advertising afterwards. The simulator has no
/// local network privacy, so it always reports `granted`.
enum LocalNetworkAuthorization {
    /// Resolves to `.granted` or `.denied`, or `.unknown` after `timeout`
    /// seconds without a decision (for example while the prompt is still up).
    static func check(timeout: TimeInterval = 30) async -> LocalNetworkAccess {
        await Probe().run(timeout: timeout)
    }
}

/// One listener + browser pair. All state lives on `queue`, which is also the
/// queue the Network framework calls back on, hence `@unchecked Sendable`.
private final class Probe: @unchecked Sendable {
    private static let serviceType = "_watchnext._tcp"
    /// `kDNSServiceErr_PolicyDenied` from dns_sd.h: the user refused local network access.
    private static let policyDenied: DNSServiceErrorType = -65570

    private let queue = DispatchQueue(label: "WatchNext.LocalNetworkAuthorization")
    private var listener: NWListener?
    private var browser: NWBrowser?
    private var continuation: CheckedContinuation<LocalNetworkAccess, Never>?

    func run(timeout: TimeInterval) async -> LocalNetworkAccess {
        await withCheckedContinuation { continuation in
            queue.async {
                self.continuation = continuation
                self.start()
                self.queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
                    self?.finish(.unknown, reason: "no decision after \(Int(timeout)) s")
                }
            }
        }
    }

    private func start() {
        let listener: NWListener
        do {
            listener = try NWListener(using: .tcp)
        } catch {
            finish(.unknown, reason: "listener could not be created: \(error)")
            return
        }
        listener.service = NWListener.Service(name: "WatchNext", type: Self.serviceType)
        listener.newConnectionHandler = { connection in connection.cancel() }
        listener.stateUpdateHandler = { [weak self] state in
            if case .failed(let error) = state {
                self?.finish(.unknown, reason: "listener failed: \(error)")
            }
        }

        let browser = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: .tcp)
        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .waiting(let error), .failed(let error):
                if case .dns(let code) = error, code == Self.policyDenied {
                    self?.finish(.denied, reason: "browse refused by policy")
                } else if case .failed = state {
                    self?.finish(.unknown, reason: "browser failed: \(error)")
                }
            default:
                break
            }
        }
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            if results.isEmpty == false {
                self?.finish(.granted, reason: "own service found")
            }
        }

        self.listener = listener
        self.browser = browser
        listener.start(queue: queue)
        browser.start(queue: queue)
    }

    private func finish(_ outcome: LocalNetworkAccess, reason: String) {
        guard let continuation else { return }
        self.continuation = nil
        listener?.cancel()
        browser?.cancel()
        listener = nil
        browser = nil
        logger.info("Local network access \(outcome.rawValue): \(reason).", category: "Network")
        continuation.resume(returning: outcome)
    }
}
