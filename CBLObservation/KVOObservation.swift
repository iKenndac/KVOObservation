//
//  KVOObservation.swift
//  CBLObservation
//
//  Created by Daniel Kennett on 29/09/15.
//  Copyright © 2015 Cascable AB. All rights reserved.
//

import Foundation

public protocol KVOObservation {
    var callback: KVOObservationCallback? { get set }
    func invalidate()
}

public typealias KVOObservationCallback = (NSObject, String, AnyObject?, AnyObject?) -> ()

public class KVO {

    public static func observe(object: NSObject, keyPath: String, triggerInitial: Bool = true, callback: KVOObservationCallback? = nil) -> KVOObservation {
        return KVOSingleObservation(object: object, keyPath: keyPath, triggerInitial: triggerInitial, callback: callback)
    }

}

public class KVOSingleObservation : NSObject, KVOObservation {

    public var callback: KVOObservationCallback?
    let keyPath: String
    private var context = UInt8()
    weak var observedObject: NSObject?

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
            callback(observedObject, self.keyPath, old, new)
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}
