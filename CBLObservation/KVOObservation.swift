//
//  KVOObservation.swift
//  CBLObservation
//
//  Created by Daniel Kennett on 29/09/15.
//  Copyright © 2015 Cascable AB. All rights reserved.
//

import Foundation

public protocol KVOObservation {
    func invalidate()
}

public typealias KVOObservationCallback = (observed: NSObject, keyPath: String, oldValue: AnyObject?, newValue: AnyObject?) -> ()
public typealias KVOGroupObservationCallback = (observed: [NSObject], values: [AnyObject]) -> ()

public class KVO {

    public static func observe(object: NSObject, keyPath: String, triggerInitial: Bool = true, callback: KVOObservationCallback? = nil) -> KVOSingleObservation {
        return KVOSingleObservation(object: object, keyPath: keyPath, triggerInitial: triggerInitial, callback: callback)
    }

    public static func combine(observervations: [KVOSingleObservation], callback: KVOGroupObservationCallback) -> KVOGroupObservation {
        return KVOGroupObservation(observations: observervations, callback: callback)
    }

    public static func observeKeyPath(keyPath: String, ofObjects objects: [NSObject], callback: KVOGroupObservationCallback) -> KVOGroupObservation {
        var observations = [KVOSingleObservation]()

        for object in objects {
            observations.append(KVO.observe(object, keyPath: keyPath))
        }

        return KVO.combine(observations, callback: callback)
    }

}

public class KVOSingleObservation : NSObject, KVOObservation {

    public var callback: KVOObservationCallback?
    public let keyPath: String
    private var context = UInt8()
    internal var didTriggerInitial: Bool
    public private(set) weak var observedObject: NSObject?

    convenience init (object: NSObject, keyPath: String) {
        self.init(object: object, keyPath: keyPath, callback: nil)
    }

    convenience init(object: NSObject, keyPath: String, callback: KVOObservationCallback?) {
        self.init(object: object, keyPath: keyPath, triggerInitial: true, callback: callback)
    }

    init(object: NSObject, keyPath: String, triggerInitial: Bool, callback: KVOObservationCallback?) {
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

    public func invalidate() {
        if let observedObject = self.observedObject {
            observedObject.removeObserver(self, forKeyPath: self.keyPath, context: &self.context)
            self.observedObject = nil
        }
    }

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

    private let observations: [KVOSingleObservation]
    var callback: KVOGroupObservationCallback?

    init(observations: [KVOSingleObservation], callback: KVOGroupObservationCallback) {
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

    public func invalidate() {
        for observation in self.observations {
            observation.invalidate()
        }
    }

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
