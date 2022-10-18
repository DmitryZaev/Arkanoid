//
//  ShotMenuModel.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 12.10.2022.
//

import Foundation

struct ShotMenuModel {
    let height : Double
    let width : Double
    let origin : PointModel
    
    
    init(height: Double, width: Double, origin: PointModel) {
        self.height = height
        self.width = width
        self.origin = origin
    }
}



