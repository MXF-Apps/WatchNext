import Foundation
import Testing
@testable import WatchNextCore

struct ServiceFailureTests {
    @Test
    func attributingWrapsErrors() async {
        await #expect(throws: ServiceFailure.self) {
            try await ServiceFailure.attributing(.radarr) { throw NetworkError.unauthorized }
        }
    }

    @Test
    func nestedFailuresKeepTheirOwnServer() async {
        do {
            try await ServiceFailure.attributing(.sonarr) {
                throw ServiceFailure(service: .jellyfin, underlying: NetworkError.unauthorized)
            }
            Issue.record("expected a failure")
        } catch let failure as ServiceFailure {
            #expect(failure.service == .jellyfin)
        } catch {
            Issue.record("unexpected error \(error)")
        }
    }

    @Test
    func descriptionNamesTheServer() {
        let failure = ServiceFailure(service: .jellyfin, underlying: NetworkError.unauthorized)
        #expect(failure.localizedDescription.hasPrefix("Jellyfin"))
        #expect(failure.localizedDescription.contains(NetworkError.unauthorized.localizedDescription))
    }
}
