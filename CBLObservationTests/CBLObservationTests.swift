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

    func testInitial() {

        let initial = self.expectationWithDescription("Got initial")

        let testObject = TestObject(name: "Daniel", address: "123 Cool St.")
        let observation = KVO.observe(testObject, keyPath: "name") {
            observed, keyPath, old, new in

            XCTAssertEqual(observed, testObject)
            XCTAssertNil(old)
            XCTAssertEqual(new as? String, "Daniel")
            XCTAssertEqual(keyPath, "name")

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

            nameExpectation.fulfill()
        }

        let addressObservation = KVO.observe(testObject, keyPath: "address", triggerInitial: false) {
            observed, keyPath, old, new in

            XCTAssertEqual(observed, testObject)
            XCTAssertEqual(old as? String, "123 Cool St.")
            XCTAssertEqual(new as? String, "123 Coolest St.")
            XCTAssertEqual(keyPath, "address")

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

    func testGroupWithInitial() {

        let obj1 = TestObject(name: "Daniel", address: "123 Cool St.")
        let obj2 = TestObject(name: "Alana", address: "67a Warm St.")
        let obj3 = TestObject(name: "Chester", address: "12102 Ice Blvd.")

        var callbacksReceived = 0
        let gotFourCallbacksExpectation = self.expectationWithDescription("Got four callbacks")

        let groupObservation = KVO.combine([KVO.observe(obj1, keyPath: "name"), KVO.observe(obj2, keyPath: "name"), KVO.observe(obj3, keyPath: "name")]) {
            objects, values in

                XCTAssertEqual([obj1, obj2, obj3], objects)
                XCTAssertEqual([obj1.name!, obj2.name!, obj3.name!], values as! [String])

                callbacksReceived++
                
                if (callbacksReceived == 4) {
                    // Since the single observations will trigger on creation, the group one
                    // will as well, so we expect four triggers - one initial, three change.
                    gotFourCallbacksExpectation.fulfill()
                }

        }

        obj1.name = "Dan"
        obj2.name = "Elena"
        obj3.name = "Dumbass"

        self.waitForExpectationsWithTimeout(1.0) {
            error in
        }

        groupObservation.invalidate()
    }

    func testGroupConvenienceWithInitial() {

        let obj1 = TestObject(name: "Daniel", address: "123 Cool St.")
        let obj2 = TestObject(name: "Alana", address: "67a Warm St.")
        let obj3 = TestObject(name: "Chester", address: "12102 Ice Blvd.")

        var callbacksReceived = 0
        let gotFourCallbacksExpectation = self.expectationWithDescription("Got four callbacks")

        let groupObservation = KVO.observeKeyPath("name", ofObjects:[obj1, obj2, obj3]) {
            objects, values in

            XCTAssertEqual([obj1, obj2, obj3], objects)
            XCTAssertEqual([obj1.name!, obj2.name!, obj3.name!], values as! [String])

            callbacksReceived++

            if (callbacksReceived == 4) {
                // Since the single observations will trigger on creation, the group one
                // will as well, so we expect four triggers - one initial, three change.
                gotFourCallbacksExpectation.fulfill()
            }

        }

        obj1.name = "Dan"
        obj2.name = "Elena"
        obj3.name = "Dumbass"

        self.waitForExpectationsWithTimeout(1.0) {
            error in
        }

        groupObservation.invalidate()
    }
}
