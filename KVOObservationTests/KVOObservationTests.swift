/*
Copyright (c) 2015, Daniel Kennett
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the
following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest
@testable import KVOObservation

class TestObject : NSObject {
    dynamic var name: String?
    dynamic var address: String?

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}

class KVOObservationTests: XCTestCase {

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
