//
//  BallView.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 04.10.2022.
//

import UIKit

class BallView: UIView, DynamicItemWithTag {

    override init(frame: CGRect) {
        super .init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
