`KVOObservation` is a simple little Key-Value Observing helper written in Swift. Its key feature is the ability to merge multiple observations together into one callback point.

Basically, if you're looking to replace using ReactiveCocoa's `combineLatest:` to chain multiple Key-Value Observers together, this is for you!

You can use `KVOObservation` from either Swift of Objective-C.

**Important:** Since Key-Value Observing is an Objective-C runtime feature, your Swift objects need to descend from NSObject to work. In addition, properties you wish to observe must be marked with the `dynamic` keyword.

```swift
class TestObject : NSObject {
    dynamic var name: String?
    dynamic var address: String?

    init(name: String, address: String) {
        self.name = name
        self.address = address
    }
}
```

### Basic Usage

To observe a single object/keypath pair:

```swift
var testObject = TestObject(name: "Daniel", address: "123 Cool St.")

let observation = KVO.observe(testObject, keyPath: "name") {
    observed, keyPath, old, new in

    print(keyPath) // "name"
    print(old) // "Daniel"
    print(new) // "Dan"
}

// Setting the property value will trigger the
// observation above. 
testObject.name = "Dan"
```

To combine multiple object/keypath pairs into one observation:

```swift
var obj1 = TestObject(name: "Daniel", address: "123 Cool St.")
var obj2 = TestObject(name: "Alana", address: "67a Warm St.")
var obj3 = TestObject(name: "Chester", address: "12102 Ice Blvd.")

let groupObservation = KVO.combine([KVO.observe(obj1, keyPath: "name"),
                                    KVO.observe(obj2, keyPath: "address"),
                                    KVO.observe(obj3, keyPath: "name")]) {
    objects, values in

    print(objects) // [obj1, obj2, obj3]
    print(values) // ["Dan", "67a Warm St.", "Chester"]
}

// Setting the property value will trigger the
// observation above. 
obj1.name = "Dan"
```

If you're observing the same key path of multiple objects, you can use this convenience function:

```swift
var obj1 = TestObject(name: "Daniel", address: "123 Cool St.")
var obj2 = TestObject(name: "Alana", address: "67a Warm St.")
var obj3 = TestObject(name: "Chester", address: "12102 Ice Blvd.")

let groupObservation = KVO.observeKeyPath("name", ofObjects: [obj1, obj2, obj3]) {
    objects, values in

    print(objects) // [obj1, obj2, obj3]
    print(values) // ["Dan", "Alana", "Chester"]
}

// Setting the property value will trigger the
// observation above. 
obj1.name = "Dan"
```

You can find some usage examples in the unit tests included with the project.

### Advanced Usage

By default, observations will fire immediately on creation. If you don't want this to happen, create your observations with the optional `triggerInitial` parameter set to `false`.

```swift
var testObject = TestObject(name: "Daniel", address: "123 Cool St.")

let nameObservation = KVO.observe(testObject, keyPath: "name", triggerInitial: false) {
    observed, keyPath, old, new in
	// Do some stuff
}
```

Grouped observations infer whether to fire immediately from the observations they're created from. If any of the grouped observations are set to fire immediately, the group will also fire immediately.

```swift
var testObject = TestObject(name: "Daniel", address: "123 Cool St.")

let nameObservation = KVO.observe(testObject, keyPath: "name", triggerInitial: false)
let addressObservation = KVO.observe(testObject, keyPath: "address", triggerInitial: false)

let groupObservation = KVO.combine([nameObservation, addressObservation]) {
    objects, values in
    // This will NOT fire immediately since none of the observations the
    // group was created from were set to fire immediately.
}

let immediateNameObservation = KVO.observe(testObject, keyPath: "name", triggerInitial: true)

let immediateGroupObservation = KVO.combine([immediateNameObservation, addressObservation]) {
    objects, values in
    // This WILL fire immediately since one of the observations the
    // group was created from was set to fire immediately.
}
```

As shown in the sample code above, you can create observations without callbacks. Normally, the only reason to do this is when setting up observations that will go into a group - otherwise, observations are pretty useless without a way of reacting to them!

### License 

Copyright (c) 2015, Daniel Kennett
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
