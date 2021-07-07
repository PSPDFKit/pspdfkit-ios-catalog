//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

public protocol WebExamplesAPIClientDelegate: AnyObject {

    /// Called whenever the `WebExamplesAPIClient` instance receives a Basic Authentication challenge from the server.
    /// Call the `completion` closure with the appropriate `URLCredential`.
    /// Consider using the `UIViewController.presentBasicAuthPrompt(for:completion:)` helper to
    /// present an alert asking for username and password to create the `URLCredential`.
    func examplesAPIClient(_ apiClient: WebExamplesAPIClient, didReceiveBasicAuthenticationChallenge challenge: URLAuthenticationChallenge, completion: @escaping (URLCredential?) -> Void)

}

/// Interfaces with our PSPDFKit for Web examples server.
///
/// This is just networking and JSON parsing. It’s very specific our backend so not very useful as sample code.
/// In your own app you would connect to your own server backend to get Instant document identifiers and authentication tokens.
public class WebExamplesAPIClient: NSObject, URLSessionTaskDelegate {

    weak var delegate: WebExamplesAPIClientDelegate?

    /// Lock used for tracking the multiple `URLSession` instances.
    private lazy var urlSessionsLock = NSRecursiveLock()

    /// Currently active `URLSession` created for the API Client requests.
    private lazy var urlSessions: Set<URLSession> = []

    let userID: String
    let password: String

    private let apiBaseURL: URL
    private let base64EncodedUserPass: String

    public init(baseURL: URL = InstantWebExamplesServerURL, userID: String = "", password: String = "", delegate: WebExamplesAPIClientDelegate?) {
        self.userID = userID
        self.password = password

        apiBaseURL = baseURL.appendingPathComponent(Endpoint.api.rawValue, isDirectory: true)
        base64EncodedUserPass = "\(userID):\(password)".data(using: .utf8)!.base64EncodedString()

        self.delegate = delegate

        super.init()
    }

    struct Endpoint {
        let rawValue: String

        static let api = Endpoint(rawValue: "api")
        static let documentWithLayers = Endpoint(rawValue: InstantConstructionPlanDocumentIdentifier)
    }

    /// Creates a new session with multiple Instant Layers using the layer names supplied in `layers`.
    public func createNewSession(with layers: [String], completion: @escaping (Result<[String: InstantDocumentInfo], WebExamplesAPIClientError>) -> Void) {
        var request = authorizedRequest(forEndpoint: .documentWithLayers)
        request.httpMethod = "POST"

        let requestData = ["layers": layers]
        request.httpBody = try! JSONEncoder().encode(requestData)

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.dataTask(with: request) { data, response, error in
            let responseResult = self.resultFromResponse(with: data, response: response, error: error) {
                return try JSONDecoder().decode([String: InstantDocumentInfo].self, from: $0)
            }
            completion(responseResult)
        }.resume()
        session.finishTasksAndInvalidate()
        insertNewURLSession(session)
    }

    /// Starts a new session for the given `documentIdentifier`.
    /// The completion handler may be called on a background thread.
    public func createNewSession(for documentIdentifier: String, completion: @escaping (Result<InstantDocumentInfo, WebExamplesAPIClientError>) -> Void) {
        var request = authorizedRequest(forEndpoint: Endpoint(rawValue: documentIdentifier))
        request.httpMethod = "POST"

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.dataTask(with: request) { data, response, error in
            let responseResult = self.resultFromResponse(with: data, response: response, error: error) {
                return try JSONDecoder().decode(InstantDocumentInfo.self, from: $0)
            }
            completion(responseResult)
        }.resume()
        session.finishTasksAndInvalidate()
        insertNewURLSession(session)
    }

    /// Tries to join an existing session at the given `URL`.
    /// The completion handler may be called on a background thread.
    public func resolveExistingSessionURL(_ url: URL, completion: @escaping (Result<InstantDocumentInfo, WebExamplesAPIClientError>) -> Void) {
        var request = URLRequest(url: url)
        request.addValue("application/vnd.instant-example+json", forHTTPHeaderField: "Accept")

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.dataTask(with: request) { data, response, error in
            let responseResult = self.resultFromResponse(with: data, response: response, error: error) {
                return try JSONDecoder().decode(InstantDocumentInfo.self, from: $0)
            }
            completion(responseResult)
        }.resume()
        session.finishTasksAndInvalidate()
        insertNewURLSession(session)
    }

    /// Adds a session to the set of tracked session.
    /// At the same time clears any of the existing invalidated session.
    private func insertNewURLSession(_ session: URLSession) {
        _ = urlSessionsLock.withLock {
            urlSessions.insert(session)
        }
    }

    /// Returns the result using the `dataDecoder` to decode the data received in the response.
    private func resultFromResponse<T>(with data: Data?, response: URLResponse?, error: Error?, dataDecoder: ((Data) throws -> T)) -> Result<T, WebExamplesAPIClientError> {
        if let error = error as? URLError {
            switch error.code {
            case .cancelled:
                return .failure(.cancelled)
            default:
                return .failure(.internalError(underlying: error))
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(.internalError(underlying: nil))
        }

        switch httpResponse.statusCode {
        case 200:
            do {
                if let data = data {
                    let decodedData = try dataDecoder(data)
                    return .success(decodedData)
                } else {
                    return .failure(.noDataAvailable(reason: ""))
                }
            } catch {
                return .failure(.noDataAvailable(reason: "Unable to access data received. Error: \(error)."))
            }
        case 400:
            return .failure(.invalidCode)
        default:
            return .failure(.internalError(underlying: nil))
        }
    }

    private func authorizedRequest(forEndpoint endpoint: Endpoint) -> URLRequest {
        var request = URLRequest(url: apiBaseURL.appendingPathComponent(endpoint.rawValue))
        request.setValue("Basic \(base64EncodedUserPass)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        return request
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic, challenge.proposedCredential?.password == nil {
            promptForHTTPBasicAuthenticationCredential(challenge: challenge) { providedCredential in
                if let providedCredential = providedCredential {
                    completionHandler(.useCredential, providedCredential)
                } else {
                    completionHandler(.cancelAuthenticationChallenge, nil)
                }
            }
        } else {
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        urlSessionsLock.withLock {
            // Remove the session since is has been invalidated.
            assert(urlSessions.contains(session))
            urlSessions.remove(session)
        }
    }

    private func promptForHTTPBasicAuthenticationCredential(challenge: URLAuthenticationChallenge, completion: @escaping (URLCredential?) -> Void) {
        if let availableDelegate = delegate {
            availableDelegate.examplesAPIClient(self, didReceiveBasicAuthenticationChallenge: challenge, completion: completion)
        } else {
            completion(nil)
        }
    }

}

public enum WebExamplesAPIClientError: LocalizedError {
    case cancelled
    case invalidCode
    case noDataAvailable(reason: String?)
    case internalError(underlying: Error?)

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "The request has been cancelled."
        case .invalidCode:
            return "The document code is invalid."
        case .noDataAvailable(nil):
            return "No Document data found in the response."
        case .noDataAvailable(let reason?):
            return "No Document data found in the response. Reason: \(reason)"
        case .internalError(let underlying?):
            return "An error occurred: \(underlying)"
        case .internalError(nil):
            return "An internal error occurred."
        }
    }
}
