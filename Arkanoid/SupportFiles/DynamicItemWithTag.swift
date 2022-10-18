//
//  DynamicItemWithTag.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 04.10.2022.
//

import Foundation
import UIKit

protocol DynamicItemWithTag: UIDynamicItem {
    var tag: Int { get set }
}
