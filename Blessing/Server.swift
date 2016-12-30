//
//  Server.swift
//  Blessing
//
//  Created by k on 03/11/2016.
//  Copyright © 2016 egg. All rights reserved.
//

import Foundation

extension Record {
    init?(data: Data) {

        guard let json = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any] else {
            return nil
        }

        guard let ips = json?["ips"] as? [String], !ips.isEmpty else {
            return nil
        }
        
        guard let ttl = json?["ttl"] as? Int else {
            return nil
        }

        self.ips = ips
        self.ttl = ttl

        self.timestamp = Date().timeIntervalSince1970
    }
}

protocol Decodable {

    static func parse(data: Data) -> Self?
}

// MAKR: - Qcloud

struct Qcloud {

    let ips: [String]
    let ttl: Int

    var timestamp: TimeInterval

    func toRecord() -> Record {
        return Record(ips: ips, ttl: ttl, timestamp: timestamp)
    }
}

extension Qcloud {

    init?(data: Data) {

        guard let raw = String(data: data, encoding: .utf8) else { return nil }

        let components = raw.components(separatedBy: ",")

        if components.count != 2 {
            return nil
        }

        guard let ttlString = components.last, let ttl = Int(ttlString), ttl >= 0 else { return nil }

        guard let ips = components.first?.components(separatedBy: ";"), !ips.isEmpty else { return nil }

        self.ips = ips

        self.ttl = ttl

        self.timestamp = Date().timeIntervalSince1970
    }
}

extension Qcloud: Decodable {
    static func parse(data: Data) -> Qcloud? {

        return Qcloud(data: data)
    }
}

struct QcloudRequest: Request {
    typealias Response = Qcloud

    let host: String = "https://182.254.12.34"
    let dns: String? = "dns.qq.com"
    let headers: HTTPHeaders?
    let path: String = "/d"
    let method: String = "GET"

    var parameters: [String : Any]
    
    init(domain: String) {
        self.parameters =  ["dn": domain, "ttl": "1"]
        self.headers = ["Host": "dns.qq.com"]
    }
}


// MAKR: - Dnspod

struct Dnspod {

    let ips: [String]
    let ttl: Int

    var timestamp: TimeInterval

    func toRecord() -> Record {
        return Record(ips: ips, ttl: ttl, timestamp: timestamp)
    }
}

extension Dnspod {

    init?(data: Data) {

        guard let raw = String(data: data, encoding: .utf8) else { return nil }

        let components = raw.components(separatedBy: ",")

        if components.count != 2 {
            return nil
        }

        guard let ttlString = components.last, let ttl = Int(ttlString), ttl >= 0 else { return nil }

        guard let ips = components.first?.components(separatedBy: ";"), !ips.isEmpty else { return nil }

        self.ips = ips

        self.ttl = ttl

        self.timestamp = Date().timeIntervalSince1970
    }
}

extension Dnspod: Decodable {
    static func parse(data: Data) -> Dnspod? {

        return Dnspod(data: data)
    }
}

struct DnspodRequest: Request {
    typealias Response = Dnspod

    let host: String = "https://119.29.29.229"
    let path: String = "/d"
    let method: String = "GET"
    let headers: HTTPHeaders? = nil
    let dns: String? = nil

    var parameters: [String : Any]

    init(domain: String) {
        self.parameters =  ["dn": domain, "ttl": "1"]
    }
}

// MARK: - Aliyum

struct Aliyun {

    let host: String
    let ips: [String]
    let ttl: Int
    var timestamp: TimeInterval

    func toRecord() -> Record {
        return Record(ips: ips, ttl: ttl, timestamp: timestamp)
    }
}

extension Aliyun {

    init?(data: Data) {

        guard let json = try? JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any] else {
            return nil
        }

        guard let host = json?["host"] as? String else { return nil }

        guard let ips = json?["ips"] as? [String], !ips.isEmpty else {
            return nil
        }
        guard let ttl = json?["ttl"] as? Int else {
            return nil
        }

        self.host = host
        self.ips = ips
        self.ttl = ttl
        self.timestamp = Date().timeIntervalSince1970
    }
}


extension Aliyun: Decodable {

    static func parse(data: Data) -> Aliyun? {
        return Aliyun(data: data)
    }
}

struct AliyunRequest: Request {
    typealias Response = Aliyun

    let host: String = "http://203.107.1.1/"
    let dns: String? = nil
    let path: String
    let headers: HTTPHeaders? = nil
    let method: String = "GET"

    var parameters: [String : Any]

    init(domain: String, account: String) {
        self.parameters = ["host": domain, "ttl": 1]
        self.path = "/\(account)/d"
    }
}
