//
//  Dynamic.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 12.10.2022.
//

import Foundation

final class Dynamic<T> {
    typealias Listener = (T) -> Void
    private var listener: Listener?
    
    var value: T {
        didSet {
            listener?(value)
        }
    }
    
    init(_ value: T) {
        self.value = value
    }
    
    func bind(_ listener: Listener?) {
        self.listener = listener
    }
    
    func unbind() {
        self.listener = nil
    }
}
