import Foundation
import WatchNextLogging

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession
    private let logger: WatchNextLogger

    public init(session: URLSession = .shared, logger: WatchNextLogger = .shared) {
        self.session = session
        self.logger = logger
    }

    public func data(for request: HTTPRequest) async throws -> Data {
        let endpoint = sanitizedEndpoint(request.url)
        logger.debug("Starting \(request.method.rawValue) \(endpoint).", category: "Network")
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = 20
        for (name, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            logger.error("Request failed: \(request.method.rawValue) \(endpoint).", error: error, category: "Network")
            throw error
        }
        guard let response = response as? HTTPURLResponse else {
            logger.error("Invalid response for \(request.method.rawValue) \(endpoint).", category: "Network")
            throw NetworkError.invalidResponse
        }
        logger.debug(
            "Finished \(request.method.rawValue) \(endpoint) with HTTP \(response.statusCode), \(data.count) bytes.",
            category: "Network"
        )
        switch response.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            logger.error(
                "Authorization failed for \(request.method.rawValue) \(endpoint). \(bodySnippet(data))",
                category: "Network"
            )
            throw NetworkError.unauthorized
        default:
            logger.error(
                "Server returned HTTP \(response.statusCode) for \(request.method.rawValue) \(endpoint). \(bodySnippet(data))",
                category: "Network"
            )
            throw NetworkError.server(statusCode: response.statusCode)
        }
    }

    /// First few hundred characters of an error body, whitespace-collapsed, so
    /// validation messages from the server show up in the log without dumping
    /// whole payloads.
    private func bodySnippet(_ data: Data, limit: Int = 300) -> String {
        guard data.isEmpty == false else { return "Body: <empty>" }
        guard let text = String(data: data, encoding: .utf8) else {
            return "Body: <\(data.count) non-UTF-8 bytes>"
        }
        let collapsed = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let clipped = collapsed.count > limit ? String(collapsed.prefix(limit)) + "…" : collapsed
        return "Body: \(clipped)"
    }

    private func sanitizedEndpoint(_ url: URL) -> String {
        var value = url.host() ?? "unknown-host"
        if let port = url.port { value += ":\(port)" }
        value += url.path(percentEncoded: false)
        if let names = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.map(\.name),
           names.isEmpty == false {
            value += "?" + names.joined(separator: "&")
        }
        return value
    }
}
