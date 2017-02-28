//
//  Blessing.swift
//  Blessing
//
//  Created by k on 02/11/2016.
//  Copyright © 2016 egg. All rights reserved.
//

import Foundation

public enum Server: CustomStringConvertible {
    case dnspod
    case qcloud(id: Int, key: String) // id, key
    case aliyun(account: String)

    public var description: String {
        switch self {
        case .qcloud: return "QCloud"
        case .dnspod: return "DNSPod"
        case .aliyun: return "AliYun"
        }
    }
}

public enum Result<T> {
    case success(T)
    case failure(Error)

    public var value: T? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }

    public var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

extension Result {

    public func map<U>(_ transform: (T) -> U) -> Result<U> {
        switch self {
        case .success(let value):
            return .success(transform(value))
        case .failure(let error):
            return .failure(error)
        }
    }

    public func flatMap<U>(_ transform: (T) -> Result<U>) -> Result<U> {
        switch self {
        case .success(let value):
            return transform(value)
        case .failure(let error):
            return .failure(error)
        }
    }
}

protocol RecordType {
    associatedtype T
    var ips: [T] { get }
    var ttl: Int { get }
    var timestamp: TimeInterval { get }

    var isExpired: Bool { get }
}

extension RecordType {
    var isExpired: Bool {
        return Date().timeIntervalSince1970 > (timestamp + Double(ttl))
    }
}

public struct Record: RecordType {
    public typealias T = String

    public var ips: [T]
    public var ttl: Int

    public var timestamp: TimeInterval
}

public class Blessing {

    public static let shared = Blessing()
    private init() {
        manager = NetworkReachabilityManager()
        bindListener()
    }

    public var debug: Bool = false
    
    private let cache: Cache<Record> = Cache()

    private let manager: NetworkReachabilityManager?

    private var host: String = ""
    private var server: Server = .dnspod

    /// Async query
    public func query(_ host: String, on server: Server = .dnspod, queue: DispatchQueue = .main, handler: ((Result<Record>) -> Void)? = nil) {

        self.host = host
        self.server = server

        let isDebug = debug

        // cache
        if let record = cache.get(for: host) {
            if isDebug {
                print("**Blessing**: Async query `\(host)` on \(server), record from cache.")
            }
            handler?(.success(record))
            return
        }

        switch server {
        case .dnspod:
            URLSessionRequestSender.shared.send(DnspodRequest(domain: host), queue: queue) { [weak self] (result: Result<Dnspod>) in
                let record = result.map { $0.toRecord() }
                handler?(record)
                if let value = record.value {
                    self?.cache.set(value, for: host)
                }
                if isDebug {
                    print("**Blessing**: Async query `\(host)` on \(server), record from server.")
                    print("**Blessing**: \(record.value)")
                }
            }
        case let .qcloud(id, key):
            URLSessionRequestSender.shared.send(QcloudRequest(domain: host, id: id, key: key), queue: queue) { [weak self] (result: Result<Qcloud>) in
                let record = result.map { $0.toRecord() }
                handler?(record)
                if let value = record.value {
                    self?.cache.set(value, for: host)
                }
                if isDebug {
                    print("**Blessing**: Async query `\(host)` on \(server), record from server.")
                    print("**Blessing**: \(record.value)")
                }
            }
        case .aliyun(let account):
            URLSessionRequestSender.shared.send(AliyunRequest(domain: host, account: account), queue: queue) { [weak self] (result: Result<Aliyun>) in
              let record = result.map { $0.toRecord() }
                handler?(record)
                if let value = record.value {
                    self?.cache.set(value, for: host)
                }
                if isDebug {
                    print("**Blessing**: Async query `\(host)` on \(server), record from server.")
                    print("**Blessing**: \(record.value)")
                }
            }
        }
    }

    /// Sync query
    public func query(_ host: String, on server: Server = .dnspod) -> Result<Record> {

        self.host = host
        self.server = server

        // cache
        if let record = cache.get(for: host) {
            if debug {
                print("**Blessing**: Sync query `\(host)` on \(server), record from cache.")
            }
            return .success(record)
        }

        let record: Result<Record>

        switch server {
        case .dnspod:
            let result = URLSessionRequestSender.shared.send(DnspodRequest(domain: host))
            record = result.map { $0.toRecord() }
        case let .qcloud(id, key):
            let result = URLSessionRequestSender.shared.send(QcloudRequest(domain: host, id: id, key: key))
            record = result.map { $0.toRecord() }
        case .aliyun(let account):
            let result = URLSessionRequestSender.shared.send(AliyunRequest(domain: host, account: account))
            record = result.map { $0.toRecord() }
        }

        if let value = record.value {
            self.cache.set(value, for: host)
            print("**Blessing**: Sync query `\(host)` on \(server), record from server.")
            print("**Blessing**: \(value)")
        }
        
        return record
    }

    private func bindListener() {

        manager?.listener = { [weak self] status in

            guard let sSelf = self else { return }
            
            switch status {
            case .notReachable:
                if sSelf.debug {
                    print("**Blessing**: Network not reachable.")
                }
                return
            case .unknown:
                if sSelf.debug {
                    print("**Blessing**: Unknown network.")
                }
            case .reachable(let type):
                if sSelf.debug {
                    print("**Blessing**: Connected with \(type).")
                }
            }

            sSelf.cache.clean()

            if !sSelf.host.isEmpty {
                sSelf.query(sSelf.host, on: sSelf.server, handler: nil)
            }
        }

        manager?.startListening()
    }
}
