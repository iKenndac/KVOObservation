//
//  CBLObservationTests.swift
//  CBLObservationTests
//
//  Created by Daniel Kennett on 29/09/15.
//  Copyright © 2015 Cascable AB. All rights reserved.
//

import XCTest
@testable import CBLObservation

class TestObject : NSObject {
    dynamic var name: String?
    dynamic var address: String?

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}

class CBLObservationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitial() {

        let initial = self.expectationWithDescription("Got initial")

        let testObject = TestObject(name: "Daniel", address: "123 Cool St.")
        let observation = KVO.observe(testObject, keyPath: "name") {
            observed, keyPath, old, new in

            XCTAssertEqual(observed, testObject)
            XCTAssertNil(old)
            XCTAssertEqual(new as? String, "Daniel")
            XCTAssertEqual(keyPath, "name")

            print("Got callback!")
            initial.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0) {
            error in
        }

        observation.invalidate()
    }

    func testAfter() {

        let nameExpectation = self.expectationWithDescription("Got name callback")
        let addressExpectation = self.expectationWithDescription("Got address callback")

        let testObject = TestObject(name: "Daniel", address: "123 Cool St.")

        let nameObservation = KVO.observe(testObject, keyPath: "name", triggerInitial: false) {
            observed, keyPath, old, new in

            XCTAssertEqual(observed, testObject)
            XCTAssertEqual(old as? String, "Daniel")
            XCTAssertEqual(new as? String, "Dan")
            XCTAssertEqual(keyPath, "name")

            print("Got callback!")
            nameExpectation.fulfill()
        }

        let addressObservation = KVO.observe(testObject, keyPath: "address", triggerInitial: false) {
            observed, keyPath, old, new in

            XCTAssertEqual(observed, testObject)
            XCTAssertEqual(old as? String, "123 Cool St.")
            XCTAssertEqual(new as? String, "123 Coolest St.")
            XCTAssertEqual(keyPath, "address")

            print("Got callback!")
            addressExpectation.fulfill()
        }

        testObject.name = "Dan"
        testObject.address = "123 Coolest St."

        self.waitForExpectationsWithTimeout(1.0) {
            error in
        }

        nameObservation.invalidate()
        addressObservation.invalidate()
    }
    

    
}
