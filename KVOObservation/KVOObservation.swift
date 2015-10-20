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

import Foundation

//# MARK: KVOObservation

/**
A base interface for KVO observations. If you don't need to mutate or query the state of observations 
after creating them, this is all you need.
*/
public protocol KVOObservation {

    /**
    Invalidates the observation. After calling this, the observation will no longer trigger its callback.
    
    - Note: Observations will automatically invalidate themselves on deallocation.
    */
    func invalidate()
}

//# MARK: - Types

/** 
The callback triggered by an observation of a single object/keypath pair.

- Parameter observed: The object being observed.
- Parameter keyPath: The key path that changed.
- Parameter oldValue: The observed object's value for the observed key path before the change occurred.
- Parameter newValue: The observed object's value for the observed key path after the change occurred.

- Note: This callback will be triggered on the thread that the change took place.
*/
public typealias KVOObservationCallback = (observed: NSObject, keyPath: String, oldValue: AnyObject?, newValue: AnyObject?) -> ()

/** 
The callback triggered by an observation of a group of objects.

- Parameter observed: An array of the objects being observed.
- Parameter values: An array of the new values
*/
public typealias KVOGroupObservationCallback = (observed: [NSObject], values: [AnyObject]) -> ()

//# MARK: - Helpers

/**
Convenience methods for generating KVO observations.
*/
public class KVO {

    /** 
    Create an observation for the given key path on the given object.
    
    - Parameter object: The object to observe.
    - Parameter keyPath: The key path to observe changes on `object` for.
    - Parameter triggerInitial: Optional, defaults to `true`. If set to `true`, the callback (if given) will trigger immediately, before the function returns.
    - Parameter callback: The callback to be triggered when the observation fires.
    
    - Returns: Returns a `KVOSingleObservation` object for the observation.

    - Note: The callback will be triggered on the thread that the change took place.

    - Seealso: `KVOSingleObservation`
    - Seealso: `KVOObservationCallback`
    */
    public static func observe(object: NSObject, keyPath: String, triggerInitial: Bool = true, callback: KVOObservationCallback? = nil) -> KVOSingleObservation {
        return KVOSingleObservation(object: object, keyPath: keyPath, triggerInitial: triggerInitial, callback: callback)
    }

    /**
    Combine the given observations into a single group observation.

    - Parameter observations: An array of `KVOSingleObservation` objects to combine.
    - Parameter callback: The callback to be triggered when any of the given observations fire.

    - Returns: Returns a `KVOGroupObservation` object for the observation.

    - Note: The callbacks for the given `KVOSingleObservation` objects will be replaced by this operation. Use the 
        `KVOGroupObservationCallback` object passed into this function instead.

    - Seealso: `KVOSingleObservation`
    - Seealso: `KVOGroupObservation`
    - Seealso: `KVOGroupObservationCallback`
    */
    public static func combine(observations: [KVOSingleObservation], callback: KVOGroupObservationCallback) -> KVOGroupObservation {
        return KVOGroupObservation(observations: observations, callback: callback)
    }

    /**
    Observe a single key path of multiple objects.
    
    Handy if you have a list of objects of the same type and want to observe when a property changes on any one of them.

    - Parameter keyPath: The key path to observe.
    - Parameter objects: The objects to observe `keyPath` on.
    - Parameter callback: The callback to be triggered when any of the observations fire.
    
    - Returns: Returns a `KVOGroupObservation` object for the observation.
    - Seealso: `KVOGroupObservation`
    - Seealso: `KVOGroupObservationCallback`
*/
    public static func observeKeyPath(keyPath: String, ofObjects objects: [NSObject], callback: KVOGroupObservationCallback) -> KVOGroupObservation {
        var observations = [KVOSingleObservation]()

        for object in objects {
            observations.append(KVO.observe(object, keyPath: keyPath))
        }

        return KVO.combine(observations, callback: callback)
    }
}

//# MARK: - Classes

/**
Represents a single observation of an object/keypath pair.
*/
public class KVOSingleObservation : NSObject, KVOObservation {

    /** 
    The callback to be triggered when the value for the key path of the observed object changes.
    
    - Note: The callback will be triggered on the thread that the change originally occurred.
    */
    public var callback: KVOObservationCallback?

    /** The key path being observed. */
    public let keyPath: String

    /** The object being observed. */
    public private(set) weak var observedObject: NSObject?

    // Private properties
    private var context = UInt8()
    private var didTriggerInitial: Bool

    /**
    Initialise a new observation.
    
    - Parameter object: The object to observe.
    - Parameter keyPath: The key path to observe changes on `object` for.
    - Parameter triggerInitial: Optional, defaults to `true`. If set to `true`, the callback (if given) will trigger immediately, before the function returns.
    - Parameter callback: The callback to be triggered when the observation fires.
    
    - Note: The callback will be triggered on the thread that the change originally occurred.

    - Seealso: `KVOObservationCallback`
    */
    public init(object: NSObject, keyPath: String, triggerInitial: Bool = true, callback: KVOObservationCallback? = nil) {
        self.callback = callback
        self.keyPath = keyPath
        self.observedObject = object
        self.didTriggerInitial = triggerInitial
        super.init()

        let options = triggerInitial ? NSKeyValueObservingOptions([.Initial, .New, .Old]) : NSKeyValueObservingOptions([.New, .Old])
        object.addObserver(self, forKeyPath: self.keyPath, options: options, context: &self.context)
    }

    deinit {
        self.invalidate()
    }

    // Public API

    /** 
    Invalidate the observation.
    
    After calling this function, the observation will no longer trigger its callback.
    
    - Note: The observation will automatically invalidate itself when it is deallocated.
    */
    public func invalidate() {
        if let observedObject = self.observedObject {
            observedObject.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
            self.observedObject = nil
        }
    }

    // Internal Helpers

    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {

        guard let observedObject = self.observedObject else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        guard let callback = self.callback else {
            return
        }

        if (keyPath == self.keyPath && context == &self.context) {
            let old = change![NSKeyValueChangeOldKey]
            let new = change![NSKeyValueChangeNewKey]
            callback(observed: observedObject, keyPath: self.keyPath, oldValue: old, newValue: new)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}


public class KVOGroupObservation : NSObject, KVOObservation {

    /**
    The callback to be triggered when any of the grouped observations are triggered.

    - Note: The callback will be triggered on the thread that the change originally occurred.
    */
    public var callback: KVOGroupObservationCallback?

    // Private properties
    private let observations: [KVOSingleObservation]

    /**
    Initialise a new group observation.

    - Parameter observations: The `KVOSingleObservation` objects to group together.
    - Parameter callback: The callback to be triggered when the observation fires.

    - Note: The callback will be triggered on the thread that the change originally occurred.
    
    - Note: The callbacks for the given `KVOSingleObservation` objects will be replaced by this operation. Use the
    `KVOGroupObservationCallback` object passed into this object instead.

    - Seealso: `KVOSingleObservation`
    - Seealso: `KVOGroupObservationCallback`
    */
    public init(observations: [KVOSingleObservation], callback: KVOGroupObservationCallback) {
        self.observations = observations
        self.callback = callback
        super.init()

        var triggerInitial = false
        // We'll infer whether to trigger initial from whether any of our observations were set to trigger initially.

        for observation in self.observations {

            if (observation.didTriggerInitial) {
                triggerInitial = true
            }

            observation.callback = {
                observed, keyPath, old, new in
                self.triggerCallback()
            }
        }

        if (triggerInitial) {
            self.triggerCallback()
        }
    }

    deinit {
        self.invalidate()
    }

    // Public API

    /**
    Invalidate the observation.

    After calling this function, the observation will no longer trigger its callback.

    - Note: The observation will automatically invalidate itself when it is deallocated.
    */
    public func invalidate() {
        for observation in self.observations {
            observation.invalidate()
        }
    }

    // Internal Helpers

    private func triggerCallback() {

        guard let callback = self.callback else {
            return
        }

        var objects = [NSObject]()
        var values = [AnyObject]()

        for observation in self.observations {
            objects.append(observation.observedObject!)
            let value = observation.observedObject!.valueForKeyPath(observation.keyPath)
            if let value = value {
                values.append(value)
            } else {
                values.append(NSNull())
            }
        }

        callback(observed: objects, values: values)
    }

}
