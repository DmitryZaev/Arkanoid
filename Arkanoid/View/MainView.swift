//
//  MainView.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 01.10.2022.
//

import Foundation
import UIKit

final class MainView: UIView {
    
    let boardView = UIView()
    let coverView = UIView()
    let mainBallView = UIView()
    let shotMenuView = UIView()
    let shotButton = UIButton()
    let shotReserveLabel = UILabel()
    var balls = [Int : BallView]()
    var bullets = [BulletView]()
    let bottomSafeArea: CGFloat = 10
    var bonusLabel = UILabel()
    let leftGunView = UIImageView()
    let rightGunView = UIImageView()
    
    override init(frame: CGRect) {
        super .init(frame: CGRect(x: 0,
                                  y: 0,
                                  width: [UIScreen.main.bounds.width, UIScreen.main.bounds.height].sorted(by: <)[1],
                                  height: [UIScreen.main.bounds.width, UIScreen.main.bounds.height].sorted(by: <)[0]))
        backgroundColor = .yellow
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addBoard(width: CGFloat, height: CGFloat) {
        boardView.frame.size = CGSize(width: width,
                                      height: height)
        boardView.center = center
        boardView.frame = boardView.frame.offsetBy(dx: 0,
                                                   dy: ((bounds.height / 2) - (height / 2)) - bottomSafeArea)
        boardView.layer.cornerRadius = height / 2
        coverView.frame = boardView.bounds
        coverView.center = CGPoint(x: boardView.bounds.midX,
                                   y: boardView.bounds.midY)
        boardView.addSubview(coverView)
        coverView.layer.cornerRadius = boardView.layer.cornerRadius
        coverView.backgroundColor = .orange
        addSubview(boardView)
    }
    
    func addMainBall(diameter: CGFloat) {
        mainBallView.frame.size = CGSize(width: diameter,
                                         height: diameter)
        mainBallView.layer.cornerRadius = diameter / 2
        mainBallView.center = boardView.center
        mainBallView.frame = mainBallView.frame.offsetBy(dx: 0,
                                                         dy: -(boardView.frame.height / 2) - (mainBallView.frame.height / 2))
        mainBallView.backgroundColor = .blue
        addSubview(mainBallView)
    }
    
    func addBall(diameter: CGFloat, origin: CGPoint, tag: Int) {
        var ball = BallView(frame: CGRect(origin: origin,
                                          size: CGSize(width: diameter,
                                                       height: diameter)))
        if Bool.random() {
            guard let bonus = Bonus.allCases.randomElement() else { return }
            ball = BonusBallView(bonus: bonus, frame: CGRect(origin: origin,
                                                             size: CGSize(width: diameter,
                                                                          height: diameter)))
        }
        
        ball.layer.cornerRadius = diameter / 2
        ball.layer.borderWidth = 1
        ball.layer.borderColor = UIColor.black.cgColor
        ball.clipsToBounds = true
        ball.backgroundColor = UIColor.init(red: .random(in: 0...1),
                                            green: .random(in: 0...1),
                                            blue: .random(in: 0...1),
                                            alpha: 1)
        addSubview(ball)
        balls[tag] = ball
    }
    
    func addShotMenu(width: CGFloat, height: CGFloat, origin: CGPoint) {
        shotMenuView.frame = CGRect(x: origin.x,
                                    y: origin.y,
                                    width: width,
                                    height: height)
        addSubview(shotMenuView)
        bringSubviewToFront(shotMenuView)
        shotMenuView.addSubview(shotButton)
        shotMenuView.addSubview(shotReserveLabel)
        shotButton.translatesAutoresizingMaskIntoConstraints = false
        shotReserveLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            shotButton.heightAnchor.constraint(equalTo: shotMenuView.heightAnchor),
            shotButton.widthAnchor.constraint(equalTo:shotMenuView.heightAnchor),
            shotButton.topAnchor.constraint(equalTo: shotMenuView.topAnchor),
            shotButton.rightAnchor.constraint(equalTo: shotMenuView.rightAnchor),
            shotReserveLabel.heightAnchor.constraint(equalTo: shotMenuView.heightAnchor),
            shotReserveLabel.widthAnchor.constraint(equalTo: shotMenuView.heightAnchor),
            shotReserveLabel.topAnchor.constraint(equalTo: shotMenuView.topAnchor),
            shotReserveLabel.leftAnchor.constraint(equalTo: shotMenuView.leftAnchor)
        ])
        
        shotReserveLabel.textColor = .red
        shotReserveLabel.font = UIFont(name: "Noteworthy Bold", size: 30)
        shotReserveLabel.textAlignment = .center
        shotReserveLabel.isUserInteractionEnabled = false
        
        shotButton.layer.cornerRadius = shotMenuView.bounds.height / 2
        shotButton.layer.borderWidth = 6
        shotButton.layer.borderColor = UIColor.red.cgColor
        shotButton.setTitle("\u{1F52B}", for: .normal)
        shotButton.titleLabel?.textAlignment = .center
        shotButton.titleLabel?.font = .systemFont(ofSize: 40)
        shotButton.isUserInteractionEnabled = false
    }
    
    func createBonusLabel() {
        bonusLabel.frame.size = CGSize(width: bounds.width,
                                       height: bounds.height)
        bonusLabel.alpha = 0
        addSubview(bonusLabel)
    }
    
    func updateBonusLabelFor(_ bonus: Bonus) {
        bonusLabel.center = center
        bonusLabel.text = bonus.rawValue
        bonusLabel.textColor = bonus.color
        bonusLabel.font = UIFont(name: "Noteworthy Bold", size: 50)
        bonusLabel.textAlignment = .center
        bonusLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        bonusLabel.alpha = 1
        UIView.animate(withDuration: 2) {
            self.bonusLabel.transform = self.bonusLabel.transform.inverted()
            self.bonusLabel.alpha = 0
            self.bonusLabel.center.y -= self.bounds.height / 4
        }
    }
    
    func addGun(gunView: UIImageView, gunSize: CGSize, gunCenter: CGPoint, imageName: String) {
        gunView.frame.size = gunSize
        gunView.center = gunCenter
        if let gunImage = UIImage(named: imageName) {
            gunView.image = gunImage
        }
        boardView.addSubview(gunView)
        boardView.sendSubviewToBack(gunView)
    }
    
    func addBulletFor(gun: UIView, bulletHeight: CGFloat, bulletWidth: CGFloat) -> BulletView {
        let bulletView = BulletView()
        bulletView.frame.size = CGSize(width: bulletWidth,
                                       height: bulletHeight)
        bulletView.center = CGPoint(x: boardView.frame.minX + gun.center.x,
                                    y: boardView.frame.minY + gun.center.y)
        bulletView.layer.cornerRadius = bulletWidth / 2
        bulletView.backgroundColor = .red
        bulletView.tag = bullets.count
        bullets.append(bulletView)
        addSubview(bulletView)
        sendSubviewToBack(bulletView)
        return bulletView
    }
}
