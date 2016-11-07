//
//  BlessingTests.swift
//  BlessingTests
//
//  Created by k on 02/11/2016.
//  Copyright © 2016 egg. All rights reserved.
//

import XCTest
@testable import Blessing

class BlessingTests: XCTestCase {

    var host = "apple.com"

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testSyncQuery() {

        let res = Blessing.shared.query(host, on: .dnspod)

        XCTAssertNotNil(res.value)
    }

    func testAsyncQuery() {

        let exp = expectation(description: "test async")
        Blessing.shared.query("www.aliyun.com", on: .aliyun(account: "139450")) { result in
            switch result {
            case .success(let record):
                XCTAssertNotNil(record)
                exp.fulfill()
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }

        waitForExpectations(timeout: 30.0, handler: nil)

    }

    func testAliyun() {

        let res = Blessing.shared.query("www.aliyun.com", on: .aliyun(account: "139450"))

        XCTAssertNotNil(res.value, res.error!.localizedDescription)
    }

}
