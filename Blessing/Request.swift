//
//  Request.swift
//  Blessing
//
//  Created by k on 03/11/2016.
//  Copyright © 2016 egg. All rights reserved.
//

import Foundation

struct BlessingError: Error, CustomStringConvertible {

    let code: Int
    let description: String

    static var `default`: BlessingError {
        return BlessingError(code: -1, description: "Unkown error")
    }
}

extension BlessingError: CustomDebugStringConvertible {

    var debugDescription: String {
        return NSLocalizedString(description, comment: "")
    }
}

protocol Request {
    var host: String { get }
    var dns: String? { get }
    var method: String { get }
    var headers: HTTPHeaders? { get }
    var path: String { get }
    var parameters: [String: Any] { get }

    associatedtype Response: Decodable

    func transform(_ response: String) -> String
}

extension Request {
    var parameters: [String: Any] {
        return [:]
    }

    func transform(_ response: String) -> String {
        return response
    }
}

protocol RequestSender {
    func send<T: Request>(_ request: T, queue: DispatchQueue, handler: @escaping (Result<T.Response>) -> Void)
    func send<T: Request>(_ request: T) -> Result<T.Response>
}

protocol RequestBuilder {
    func build<T: Request>(_ request: T) -> URLRequest?
}

extension RequestBuilder {

    func build<T: Request>(_ request: T) -> URLRequest? {

        guard let url = URL(string: request.host.appending(request.path)) else { return nil }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method

        if let headers = request.headers {
            for (headerField, headerValue) in headers {
                urlRequest.setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }

        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !request.parameters.isEmpty {

            let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(request.parameters)
            urlComponents.percentEncodedQuery = percentEncodedQuery
            urlRequest.url = urlComponents.url
        }

        return urlRequest
    }

    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []

        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }

        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }

    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []

        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape((value.boolValue ? "1" : "0"))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape((bool ? "1" : "0"))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }

        return components
    }

    private func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    }

}

/// A dictionary of headers to apply to a `URLRequest`.
public typealias HTTPHeaders = [String: String]

struct URLSessionRequestSender: RequestSender, RequestBuilder {

    static let shared = URLSessionRequestSender()

    let session: URLSession
    let delegate: SessionDelegate
    let queue = DispatchQueue(label: "com.xspyhack.blessing.session" + UUID().uuidString)

    private init() {
        let delegate = SessionDelegate()
        self.delegate = delegate
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.httpAdditionalHeaders = URLSessionRequestSender.defaultHTTPHeaders

        self.session =  URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }

    /// Creates default values for the "Accept-Encoding", "Accept-Language" and "User-Agent" headers.
    /// see https://github.com/alamofire/alamofire
    public static let defaultHTTPHeaders: HTTPHeaders = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5, deflate"

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
        }.joined(separator: ", ")

        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        // Example: `iOS Example/1.0 (org.alamofire.iOS-Example; build:1; iOS 10.0.0) Alamofire/4.0.0`
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

                let osNameVersion: String = {
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

                    let osName: String = {
                        #if os(iOS)
                            return "iOS"
                        #elseif os(watchOS)
                            return "watchOS"
                        #elseif os(tvOS)
                            return "tvOS"
                        #elseif os(macOS)
                            return "OS X"
                        #elseif os(Linux)
                            return "Linux"
                        #else
                            return "Unknown"
                        #endif
                    }()

                    return "\(osName) \(versionString)"
                }()

                let blessingVersion: String = {
                    guard
                        let afInfo = Bundle(for: Blessing.self).infoDictionary,
                        let build = afInfo["CFBundleShortVersionString"]
                        else { return "Unknown" }

                    return "Blessing/\(build)"
                }()

                return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion)) \(blessingVersion)"
            }

            return "Blessing"
        }()

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": userAgent,
        ]
    }()

    func send<T: Request>(_ request: T, queue: DispatchQueue = DispatchQueue.main, handler: @escaping (Result<T.Response>) -> Void) {

        guard let urlRequest = build(request) else {
            queue.async {
                handler(.failure(BlessingError(code: 1001, description: "Can't build URLRequest.")))
            }
            return
        }

        if Blessing.shared.debug {
            print(urlRequest)
        }

        let task = session.dataTask(with: urlRequest) { data, response, error in

            if Blessing.shared.debug {
                print(response!)
            }

            if let data = data, let result = T.Response.parse(data: data, transform: request.transform) {
                queue.async {
                    handler(.success(result))
                }
            } else if let error = error {
                queue.async {
                    handler(.failure(error))
                }
            } else if let response = response as? HTTPURLResponse {
                queue.async {
                    handler(.failure(BlessingError(code: response.statusCode, description: "URLSession Error")))
                }
            } else {
                queue.async {
                    handler(.failure(BlessingError.default))
                }
            }
        }
        
        task.resume()
    }

    func send<T: Request>(_ request: T) -> Result<T.Response> {

        guard let urlRequest = build(request) else {
            return .failure(BlessingError(code: 1001, description: "Can't build URLRequest."))
        }

        if Blessing.shared.debug {
            print(urlRequest)
        }

        let (data, response, error) = session.sync(with: urlRequest)

        if Blessing.shared.debug, let response = response {
            print(response)
        }

        if let data = data, let result = T.Response.parse(data: data, transform: request.transform) {
            return .success(result)
        } else if let error = error {
            return .failure(error)
        } else if let response = response as? HTTPURLResponse {
            return .failure(BlessingError(code: response.statusCode, description: "URLSession Error"))
        } else {
            return .failure(BlessingError.default)
        }
    }
}

extension URLSession {

    func sync(with request: URLRequest) -> (Data?, URLResponse?, Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        var result: (Data?, URLResponse?, Error?) = (nil, nil, nil)

        dataTask(with: request) { data, response, error in
            result = (data, response, error)
            semaphore.signal()
        }.resume()

        semaphore.wait()

        return result
    }
}

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

