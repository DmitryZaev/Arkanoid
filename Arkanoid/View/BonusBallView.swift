//
//  BonusBallView.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 07.10.2022.
//

import Foundation
import UIKit

enum Bonus : String, CaseIterable {
    case longBoard = "Long Board!!!"
    case shortBoard = "Short Board!!!"
    case acceleration = "Acceleration!!!"
    case deceleration = "Deceleration!!!"
    case shotgun = "\u{1F52B}Shotgun\u{1F52B}"
    var color: UIColor {
        switch self {
        case .longBoard, .deceleration, .shotgun:
            return UIColor.green
        case .shortBoard, .acceleration:
            return UIColor.red
        }
    }
}

final class BonusBallView: BallView {
    
    let bonus: Bonus
    
    init(bonus : Bonus, frame: CGRect) {
        self.bonus = bonus
        super .init(frame: frame)
        
        guard let star = UIImage(named: "star") else { return }
        let imageView = UIImageView(image: star)
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7),
            imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.7)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
