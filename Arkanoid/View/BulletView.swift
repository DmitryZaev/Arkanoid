//
//  BulletView.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 12.10.2022.
//

import Foundation
import UIKit

final class BulletView: UIView, DynamicItemWithTag {

    override init(frame: CGRect) {
        super .init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
