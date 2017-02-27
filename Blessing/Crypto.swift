//
//  Crypto.swift
//  Blessing
//
//  Created by k on 27/02/2017.
//  Copyright © 2017 egg. All rights reserved.
//

import Foundation
import CommonCrypto

public func encrypt(_ text: String, key: String) -> String? {

    guard let textData = text.data(using: .utf8), let keyData: Data = key.data(using: .utf8) else { return nil }

    let textBytes: UnsafePointer<UInt8> = textData.withUnsafeBytes { $0 }

    let keyBytes: UnsafePointer<UInt8> = keyData.withUnsafeBytes { $0 }

    var bufferData = Data(count: textData.count + kCCBlockSizeDES)

    let buffer: UnsafeMutablePointer<UInt8> = bufferData.withUnsafeMutableBytes { $0 }
    let bufferLength     = size_t(bufferData.count)
    var numBytesEncrypted: size_t = 0

    let cryptStatus = CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmDES), CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode), keyBytes, kCCKeySizeDES, nil, textBytes, textData.count, buffer, bufferLength, &numBytesEncrypted)

    if cryptStatus == Int32(kCCSuccess) {
        let data = Data(bytes: buffer, count: numBytesEncrypted)
        return bytesToHex(data)
    } else {
        return nil
    }
}

public func decrypt(_ text: String, key: String) -> String? {

    let textData = hexToBytes(text)
    let textBytes: UnsafePointer<UInt8> = textData.withUnsafeBytes { $0 }

    guard let keyData: Data = key.data(using: .utf8) else { return nil }

    let keyBytes: UnsafePointer<UInt8> = keyData.withUnsafeBytes { $0 }

    var bufferData = Data(count: textData.count + kCCBlockSizeDES)

    let buffer: UnsafeMutablePointer<UInt8> = bufferData.withUnsafeMutableBytes { $0 }
    let bufferLength     = size_t(bufferData.count)
    var numBytesEncrypted: size_t = 0

    let cryptStatus = CCCrypt(CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmDES), CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode), keyBytes, kCCKeySizeDES, nil, textBytes, textData.count, buffer, bufferLength, &numBytesEncrypted)

    if cryptStatus == Int32(kCCSuccess) {
        let data = Data(bytes: buffer, count: numBytesEncrypted)
        return String(data: data, encoding: .utf8)
    } else {
        return nil
    }
}

func bytesToHex(_ bytes: Data) -> String {
    return bytes.map { String(format: "%02hhx", $0) }.joined()
}

func hexToBytes(_ hex: String) -> Data {
    var hex = hex
    var data = Data()
    while(hex.characters.count > 0) {
        let c: String = hex.substring(to: hex.index(hex.startIndex, offsetBy: 2))
        hex = hex.substring(from: hex.index(hex.startIndex, offsetBy: 2))
        var ch: UInt32 = 0
        Scanner(string: c).scanHexInt32(&ch)
        var char = UInt8(ch)
        data.append(&char, count: 1)
    }
    return data
}
