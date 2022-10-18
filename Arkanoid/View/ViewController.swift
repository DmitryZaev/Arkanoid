//
//  ViewController.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 01.10.2022.
//

import Foundation
import UIKit
import CoreMotion

class ViewController: UIViewController {

    let viewModel = ViewModel()
    let mainView = MainView()
    let animator = UIDynamicAnimator()
    let collisionBehavior = UICollisionBehavior()
    let boardCollisionBehavior = UICollisionBehavior()
    let bulletsCollisionBehavior = UICollisionBehavior()
    let velocityBehavior = UIFieldBehavior.velocityField(direction: CGVector(dx: 0, dy: 0))
    let boardVelocityBehavior = UIFieldBehavior.velocityField(direction: CGVector(dx: 0, dy: 0))
    let bulletsVelocityBehavior = UIFieldBehavior.velocityField(direction: CGVector(dx: 0, dy: -3))
    var attachBehavior = UIAttachmentBehavior(item: UIView(), attachedTo: UIView())

    let startTapRecognizer = UITapGestureRecognizer()
    let restartTapRecognizer = UITapGestureRecognizer()

    let motionManager = CMMotionManager()

    var dynamicMainBall : UIDynamicItem = UIView()
    var dynamicBoard: UIDynamicItem = UIView()

    var snapBehaviors = [Int : UISnapBehavior]()

    override func loadView() {
        view = mainView
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        createBoard()
        createMainBall()
        createBalls(count: 177)
        mainView.createBonusLabel()
        createGuns()
        createShotMenu()
        bindShotReserve()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        startAccelerometer()
        configureDynamicAnimator()
        calculateBoardVelocity()
        configureTapRecognizers()
    }

    private func configureTapRecognizers() {
        startTapRecognizer.numberOfTapsRequired = 1
        startTapRecognizer.addTarget(self, action: #selector(startGame))
        mainView.addGestureRecognizer(startTapRecognizer)
        
        restartTapRecognizer.numberOfTapsRequired = 1
        restartTapRecognizer.addTarget(self, action: #selector(restartGame))
    }

    @objc private func startGame() {
        animator.removeBehavior(attachBehavior)
        viewModel.getRandomVector { [weak self] vector in
            self?.velocityBehavior.direction = CGVector(dx: vector.dx,
                                                        dy: vector.dy)
        }
        collisionBehavior.collisionDelegate = self
        mainView.removeGestureRecognizer(startTapRecognizer)
    }

    private func createBoard() {
        viewModel.createBoard(viewWidth: Double(mainView.bounds.width),
                              viewHeight: Double(mainView.bounds.height)) { [weak self] board in
            self?.mainView.addBoard(width: CGFloat(board.size.width),
                                    height: CGFloat(board.size.height))
        }
    }

    private func createMainBall() {
        viewModel.createBalls(count: 1, viewWidth: Double(mainView.bounds.width)) { [weak self] ball in
            self?.mainView.addMainBall(diameter: CGFloat(ball.diameter))
        }
    }

    private func createBalls(count: Int) {
        viewModel.createBalls(count: count, viewWidth: Double(mainView.bounds.width)) { [weak self] ball in
            self?.mainView.addBall(diameter: CGFloat(ball.diameter),
                                   origin: CGPoint(x: ball.origin.x,
                                                   y: ball.origin.y),
                                   tag: ball.number)
        }
    }
    
    private func createGuns() {
        viewModel.createGun(leftGun: true,
                            boardMinX: mainView.boardView.bounds.minX,
                            boardMaxX: mainView.boardView.bounds.maxX,
                            boardMidY: mainView.boardView.bounds.midY,
                            boardHeight: mainView.boardView.bounds.height) { [weak self] gun in
            guard let self else { return }
            self.mainView.addGun(gunView: self.mainView.leftGunView,
                                 gunSize: CGSize(width: gun.size.width,
                                                 height: gun.size.height),
                                 gunCenter: CGPoint(x: gun.center.x,
                                                    y: gun.center.y),
                                 imageName: gun.imageName)
        }
        viewModel.createGun(leftGun: false,
                            boardMinX: mainView.boardView.bounds.minX,
                            boardMaxX: mainView.boardView.bounds.maxX,
                            boardMidY: mainView.boardView.bounds.midY,
                            boardHeight: mainView.boardView.bounds.height) { [weak self] gun in
            guard let self else { return }
            self.mainView.addGun(gunView: self.mainView.rightGunView,
                                 gunSize: CGSize(width: gun.size.width,
                                                 height: gun.size.height),
                                 gunCenter: CGPoint(x: gun.center.x,
                                                    y: gun.center.y),
                                 imageName: gun.imageName)
        }
    }

    private func createShotMenu() {
        viewModel.createShotMenu(viewWidth: mainView.bounds.width, viewHeight: mainView.bounds.height) { [weak self] shotMenu in
            self?.mainView.addShotMenu(width: shotMenu.width,
                                       height: shotMenu.height,
                                       origin: CGPoint(x: shotMenu.origin.x,
                                                       y: shotMenu.origin.y))
        }
        mainView.shotButton.addTarget(self, action: #selector(shot), for: .touchUpInside)
    }

    private func startAccelerometer() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates()
    }

    private func calculateBoardVelocity() {
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateBoardVelocity), userInfo: nil, repeats: true)
    }

    @objc private func updateBoardVelocity() {
        guard let acelerationY = motionManager.accelerometerData?.acceleration.y else { return }
        boardVelocityBehavior.direction = CGVector(dx: acelerationY * 10,
                                                   dy: 0)
    }

    @objc private func shot() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.viewModel.playSound(sound: .shot)
        }
        viewModel.shotReserve.value -= 1
        viewModel.createBullets(gunWidth: mainView.leftGunView.frame.width,
                                gunHeight: mainView.leftGunView.frame.height) { [weak self] bullet in
            guard let self else { return }
            for gun in [self.mainView.leftGunView, self.mainView.rightGunView] {
                let bullet = self.mainView.addBulletFor(gun: gun,
                                                        bulletHeight: bullet.size.height,
                                                        bulletWidth: bullet.size.width)
                let dynamicBullet : DynamicItemWithTag = bullet
                dynamicBullet.tag = bullet.tag
                bulletsCollisionBehavior.addItem(dynamicBullet)
                bulletsVelocityBehavior.addItem(dynamicBullet)
            }
        }
        mainView.shotButton.layer.borderWidth = 12
        UIView.animate(withDuration: 0.2) {
            self.mainView.shotButton.layer.borderWidth = 6
        }
    }

    private func bindShotReserve() {
        viewModel.shotReserve.bind { [weak self] shotCount in
            DispatchQueue.main.async {
                self?.mainView.shotReserveLabel.text = String(shotCount)
                if shotCount < 1 {
                    self?.hideOrUnhideShotMenu(hide: true)
                    self?.hideOrUnhideGuns(hide: true)
                }
            }
        }
    }

    private func configureDynamicAnimator() {

        dynamicMainBall = mainView.mainBallView
        dynamicBoard = mainView.boardView

        attachBehavior = UIAttachmentBehavior(item: dynamicBoard,
                                              attachedTo: dynamicMainBall)

        velocityBehavior.addItem(dynamicMainBall)

        boardCollisionBehavior.addBoundary(withIdentifier: "boardTopBorder" as NSCopying,
                                           from: CGPoint(x: mainView.bounds.minX,
                                                         y: mainView.bounds.maxY - mainView.bottomSafeArea - mainView.boardView.frame.height),
                                           to: CGPoint(x: mainView.bounds.maxX,
                                                       y: mainView.bounds.maxY - mainView.bottomSafeArea - mainView.boardView.frame.height))

        boardCollisionBehavior.addBoundary(withIdentifier: "boardBottomBorder" as NSCopying,
                                           from: CGPoint(x: mainView.bounds.minX,
                                                         y: mainView.bounds.maxY - mainView.bottomSafeArea),
                                           to: CGPoint(x: mainView.bounds.maxX,
                                                       y: mainView.bounds.maxY - mainView.bottomSafeArea))

        boardCollisionBehavior.addItem(dynamicBoard)

        for (index, ball) in mainView.balls {
            let dynBall : DynamicItemWithTag = ball
            dynBall.tag = index
            let snapBehavior = UISnapBehavior(item: dynBall, snapTo: ball.center)
            snapBehavior.damping = 0
            snapBehaviors[index] = snapBehavior
            animator.addBehavior(snapBehavior)
            collisionBehavior.addItem(dynBall)
            bulletsCollisionBehavior.addItem(dynBall)
        }

        collisionBehavior.addItem(dynamicBoard)
        collisionBehavior.addItem(dynamicMainBall)

        collisionBehavior.addBoundary(withIdentifier: "leftBorder" as NSCopying,
                                      from: CGPoint(x: 0,
                                                    y: mainView.bounds.maxY),
                                      to: CGPoint(x: 0,
                                                  y: 0))
        collisionBehavior.addBoundary(withIdentifier: "rightBorder" as NSCopying,
                                      from: CGPoint(x: mainView.bounds.maxX,
                                                    y: 0),
                                      to: CGPoint(x: mainView.bounds.maxX,
                                                  y: mainView.bounds.maxY))
        collisionBehavior.addBoundary(withIdentifier: "topBorder" as NSCopying,
                                      from: CGPoint(x: 0,
                                                    y: 0),
                                      to: CGPoint(x: mainView.bounds.maxX,
                                                  y: 0))
        collisionBehavior.addBoundary(withIdentifier: "bottomBorder" as NSCopying,
                                      from: CGPoint(x: 0,
                                                    y: mainView.bounds.maxY + mainView.mainBallView.bounds.height * 2),
                                      to: CGPoint(x: mainView.bounds.maxX,
                                                  y: mainView.bounds.maxY + mainView.mainBallView.bounds.height * 2))

        bulletsCollisionBehavior.addBoundary(withIdentifier: "wallForBullets" as NSCopying,
                                             from: CGPoint(x: 0,
                                                           y: -50),
                                             to: CGPoint(x: mainView.bounds.maxX,
                                                         y: -50))

        bulletsCollisionBehavior.collisionDelegate = self

        boardVelocityBehavior.addItem(dynamicBoard)

        animator.addBehavior(attachBehavior)
        animator.addBehavior(collisionBehavior)
        animator.addBehavior(boardCollisionBehavior)
        animator.addBehavior(velocityBehavior)
        animator.addBehavior(boardVelocityBehavior)
        animator.addBehavior(bulletsVelocityBehavior)
        animator.addBehavior(bulletsCollisionBehavior)
    }
    
    private func removeBall(dynamicBall: DynamicItemWithTag) {
        self.collisionBehavior.removeItem(dynamicBall)
        self.bulletsCollisionBehavior.removeItem(dynamicBall)
        UIView.animate(withDuration: 0.2) {
            dynamicBall.transform = CGAffineTransform(scaleX: 1.2,
                                                           y: 1.2)
        } completion: { _ in
            guard let ballView = self.mainView.balls[dynamicBall.tag] else { return }
            ballView.removeFromSuperview()
            self.mainView.balls.removeValue(forKey: dynamicBall.tag)
            guard let snapBehavior = self.snapBehaviors[dynamicBall.tag] else { return }
            self.animator.removeBehavior(snapBehavior)
            self.snapBehaviors.removeValue(forKey: dynamicBall.tag)
            
            self.checkWin()
        }
    }
    
    private func checkWin() {
        if mainView.balls.count == 0 {
            DispatchQueue.main.async {
                self.stopGame(win: true)
            }
        }
    }

    private func runBonus(bonus: Bonus) {
        switch bonus {
        case .longBoard, .shortBoard:
            DispatchQueue.main.async {
                self.viewModel.getLenghtCoefficientForBoard(bonus: bonus,
                                                            viewWidth: self.mainView.bounds.width,
                                                            boardLenght: self.mainView.boardView.bounds.width) { [weak self] coefficient in
                    self?.changeBoardLenght(coefficient: coefficient)
                }
            }
        case .acceleration, .deceleration:
            viewModel.changeSpeed(bonus: bonus,
                                  dxNow: velocityBehavior.direction.dx,
                                  dyNow: velocityBehavior.direction.dy) { [weak self] vector in
                self?.velocityBehavior.direction = CGVector(dx: vector.dx,
                                                            dy: vector.dy)
            }
        case .shotgun:
            if viewModel.shotReserve.value < 1 {
                hideOrUnhideGuns(hide: false)
                hideOrUnhideShotMenu(hide: false)
            }
            viewModel.shotReserve.value += 5
        }
    }

    private func hideOrUnhideGuns(hide: Bool) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.viewModel.playSound(sound: .moveGuns)
        }
        DispatchQueue.main.async {
            self.viewModel.moveGuns(gunHeight: self.mainView.rightGunView.frame.height, isHidingNow: hide) { [weak self] shift in
                UIView.animate(withDuration: 1.5) {
                    self?.mainView.leftGunView.frame.origin.y += shift
                    self?.mainView.rightGunView.frame.origin.y += shift
                }
            }
        }
    }

    private func hideOrUnhideShotMenu(hide: Bool) {
        DispatchQueue.main.async {
            self.viewModel.moveShotMenu(menuWidth: self.mainView.shotMenuView.frame.width,
                                        isHidingNow: hide) { [weak self] shift in
                UIView.animate(withDuration: 1.5) {
                    self?.mainView.shotMenuView.frame.origin.x += shift
                }
            }
            self.mainView.shotButton.isUserInteractionEnabled = !hide
        }
    }

    private func changeBoardLenght(coefficient: Double) {
        collisionBehavior.removeItem(dynamicBoard)
        boardVelocityBehavior.removeItem(dynamicBoard)
        boardCollisionBehavior.removeItem(dynamicBoard)
        UIView.animate(withDuration: 0.3) {
            self.mainView.boardView.bounds.size = CGSize(width: self.mainView.boardView.bounds.width * coefficient,
                                                        height: self.mainView.boardView.bounds.height)
            self.boardVelocityBehavior.addItem(self.dynamicBoard)
            self.collisionBehavior.addItem(self.dynamicBoard)
            self.boardCollisionBehavior.addItem(self.dynamicBoard)
            self.mainView.coverView.frame = self.mainView.boardView.bounds
            self.mainView.leftGunView.center.x = self.mainView.boardView.bounds.minX + 10
            self.mainView.rightGunView.center.x = self.mainView.boardView.bounds.maxX - 10
        } completion: { _ in
            self.animator.updateItem(usingCurrentState: self.dynamicBoard)
        }
    }
    
    private func stopGame(win: Bool) {
        animator.removeAllBehaviors()
        mainView.shotButton.isUserInteractionEnabled = false
        switch win {
        case true:
            viewModel.createBalls(count: 55, viewWidth: mainView.bounds.width) { ball in
                mainView.addBall(diameter: ball.diameter,
                                 origin: CGPoint(x: ball.origin.x,
                                                 y: ball.origin.y),
                                 tag: ball.number)
            }
            for (index, ball) in mainView.balls {
                viewModel.getWinOrLosePoint(win: true,
                                            centerX: mainView.center.x,
                                            centerY: mainView.center.y,
                                            number: index + 1,
                                            diameter: mainView.mainBallView.bounds.width) { [weak self] point in
                    let snapBehavior = UISnapBehavior(item: ball, snapTo: CGPoint(x: point.x,
                                                                                  y: point.y))
                    snapBehavior.damping = 0
                    self?.animator.addBehavior(snapBehavior)
                }
            }
            DispatchQueue.global(qos: .userInteractive).async {
                self.viewModel.playSound(sound: .win)
            }
        case false:
            var array = [Int]()
            for index in 0...176 {
                if snapBehaviors[index] != nil {
                    array.insert(index, at: 0)
                }
            }
            if array.count < 58 {
                let newBallsCount = 58 - array.count
                let oldBallsCount = 177
                viewModel.createBalls(count: newBallsCount, viewWidth: mainView.bounds.width) { ball in
                    mainView.addBall(diameter: ball.diameter,
                                     origin: CGPoint(x: ball.origin.x,
                                                     y: ball.origin.y),
                                     tag: ball.number + oldBallsCount)
                    guard let ballView = mainView.balls[ball.number + oldBallsCount] else { return }
                    let snapBehavior = UISnapBehavior(item: ballView,
                                                      snapTo: ballView.center)
                    snapBehavior.damping = 0
                    snapBehaviors[ball.number + oldBallsCount] = snapBehavior
                    array.insert(ball.number + oldBallsCount, at: 0)
                }
            }
            for ballNumber in 1...58 {
                viewModel.getWinOrLosePoint(win: false,
                                            centerX: mainView.center.x,
                                            centerY: mainView.center.y,
                                            number: ballNumber,
                                            diameter: mainView.mainBallView.bounds.width) { [weak self] point in
                    guard let snapBehavior = self?.snapBehaviors[array[0]] else { return }
                    snapBehavior.snapPoint = CGPoint(x: point.x,
                                                     y: point.y)
                    self?.animator.addBehavior(snapBehavior)
                    array.removeFirst()
                }
            }
            DispatchQueue.global(qos: .userInteractive).async {
                self.viewModel.playSound(sound: .lose)
            }
        }
        mainView.addGestureRecognizer(restartTapRecognizer)
    }
    
    @objc private func restartGame() {
        animator.removeAllBehaviors()
        
        for (_, ball) in mainView.balls {
            ball.removeFromSuperview()
        }
        for bullet in mainView.bullets {
            bullet.removeFromSuperview()
        }
        for item in collisionBehavior.items {
            collisionBehavior.removeItem(item)
        }
        for item in bulletsCollisionBehavior.items {
            bulletsCollisionBehavior.removeItem(item)
        }
        
        mainView.balls.removeAll()
        mainView.bullets.removeAll()
        snapBehaviors.removeAll()
        viewModel.shotReserve.unbind()
        viewModel.shotReserve.value = 0
        bindShotReserve()
        
        viewModel.createShotMenu(viewWidth: mainView.bounds.width,
                                 viewHeight: mainView.bounds.height) { shotMenu in
            mainView.shotMenuView.frame.origin = CGPoint(x: shotMenu.origin.x,
                                                         y: shotMenu.origin.y)
        }
        
        createBalls(count: 177)
        viewModel.createBoard(viewWidth: mainView.bounds.width,
                              viewHeight: mainView.bounds.height) { [weak self] board in
            self?.mainView.boardView.frame.size = CGSize(width: board.size.width,
                                                         height: board.size.height)
            self?.mainView.coverView.frame.size = (self?.mainView.boardView.frame.size)!
        }
        mainView.mainBallView.center = mainView.boardView.center
        mainView.mainBallView.center.y -= mainView.mainBallView.bounds.height / 2 + mainView.boardView.bounds.height / 2
        
        viewModel.createGun(leftGun: true,
                            boardMinX: mainView.boardView.bounds.minX,
                            boardMaxX: mainView.boardView.bounds.maxX,
                            boardMidY: mainView.boardView.bounds.midY,
                            boardHeight: mainView.boardView.bounds.height) { [weak self] gun in
            self?.mainView.leftGunView.center = CGPoint(x: gun.center.x,
                                                        y: gun.center.y)
        }
        viewModel.createGun(leftGun: false,
                            boardMinX: mainView.boardView.bounds.minX,
                            boardMaxX: mainView.boardView.bounds.maxX,
                            boardMidY: mainView.boardView.bounds.midY,
                            boardHeight: mainView.boardView.bounds.height) { [weak self] gun in
            self?.mainView.rightGunView.center = CGPoint(x: gun.center.x,
                                                         y: gun.center.y)
        }
        
        
        collisionBehavior.collisionDelegate = nil
        
        for (index, ball) in mainView.balls {
            let dynBall : DynamicItemWithTag = ball
            dynBall.tag = index
            let snapBehavior = UISnapBehavior(item: dynBall, snapTo: ball.center)
            snapBehavior.damping = 0
            snapBehaviors[index] = snapBehavior
            animator.addBehavior(snapBehavior)
            collisionBehavior.addItem(dynBall)
            bulletsCollisionBehavior.addItem(dynBall)
        }
        collisionBehavior.addItem(dynamicBoard)
        collisionBehavior.addItem(dynamicMainBall)
        
        velocityBehavior.direction = CGVector(dx: 0,
                                              dy: 0)
        
        animator.addBehavior(attachBehavior)
        animator.addBehavior(boardVelocityBehavior)
        animator.addBehavior(boardCollisionBehavior)
        animator.addBehavior(collisionBehavior)
        animator.addBehavior(velocityBehavior)
        animator.addBehavior(bulletsVelocityBehavior)
        animator.addBehavior(bulletsCollisionBehavior)
        mainView.removeGestureRecognizer(restartTapRecognizer)
        mainView.addGestureRecognizer(startTapRecognizer)
    }
}

//MARK: - UICollisionBehaviorDelegate
extension ViewController: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        if behavior == collisionBehavior {
            guard item === dynamicMainBall else { return }
            switch identifier as? String {
            case "topBorder":
                DispatchQueue.global(qos: .userInteractive).async {
                    self.viewModel.playSound(sound: .bounce)
                }
                velocityBehavior.direction = CGVector(dx: velocityBehavior.direction.dx,
                                                      dy: -velocityBehavior.direction.dy)
            case "leftBorder", "rightBorder":
                DispatchQueue.global(qos: .userInteractive).async {
                    self.viewModel.playSound(sound: .bounce)
                }
                velocityBehavior.direction = CGVector(dx: -velocityBehavior.direction.dx,
                                                      dy: velocityBehavior.direction.dy)
            default:
                DispatchQueue.main.async {
                    self.stopGame(win: false)
                }
            }
        } else {
            guard let dynBullet = item as? DynamicItemWithTag else { return }
            self.mainView.bullets[dynBullet.tag].removeFromSuperview()
            self.bulletsCollisionBehavior.removeItem(dynBullet)
            self.bulletsVelocityBehavior.removeItem(dynBullet)
        }
    }

    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: UIDynamicItem, with item2: UIDynamicItem, at p: CGPoint) {

        if behavior == collisionBehavior {
            guard item2 === dynamicMainBall || item1 === dynamicMainBall else { return }
            if item1 is BallView || item2 is BallView {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.viewModel.playSound(sound: .bubble)
                }
                var dynBall : DynamicItemWithTag? = item1 as? DynamicItemWithTag
                var dynMainBall : UIDynamicItem? = item2 as UIDynamicItem
                if item1 === dynamicMainBall {
                    dynBall = item2 as? DynamicItemWithTag
                    dynMainBall = item1 as UIDynamicItem
                }
                if let bonusBall = dynBall as? BonusBallView {
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.viewModel.playSound(sound: .bonus)
                    }
                    mainView.updateBonusLabelFor(bonusBall.bonus)
                    DispatchQueue.global().async {
                        self.runBonus(bonus: bonusBall.bonus)
                    }
                }
                guard let dynBall, let dynMainBall else { return }
                self.removeBall(dynamicBall: dynBall)
                viewModel.calculateVectorFromBall(ballCenterX: dynBall.center.x,
                                                  ballCenterY: dynBall.center.y,
                                                  mainBallCenterX: dynMainBall.center.x,
                                                  mainBallCenterY: dynMainBall.center.y,
                                                  dXYBefore: abs(velocityBehavior.direction.dx) + abs(velocityBehavior.direction.dy)) { [weak self] vector in
                    self?.velocityBehavior.direction = CGVector(dx: vector.dx,
                                                                dy: vector.dy)
                }
            } else {
                if dynamicBoard.center.y > dynamicMainBall.center.y {
                    DispatchQueue.global(qos: .userInteractive).async {
                        self.viewModel.playSound(sound: .bounce)
                    }
                    guard let accelerationY = motionManager.accelerometerData?.acceleration.y else { return }
                    viewModel.calculateVectorFromBoard(boardStartX: mainView.boardView.frame.minX,
                                                       boardEndX: mainView.boardView.frame.maxX,
                                                       collisionPointX: p.x,
                                                       boardAcceleration: accelerationY,
                                                       dXYBefore: abs(velocityBehavior.direction.dx) + abs(velocityBehavior.direction.dy)) { [weak self] vector in
                        self?.velocityBehavior.direction = CGVector(dx: vector.dx,
                                                                    dy: vector.dy)
                    }
                }
            }
        } else {
            guard item2 is BulletView || item1 is BulletView else { return }
            DispatchQueue.global(qos: .userInteractive).async {
                self.viewModel.playSound(sound: .bubble)
            }
            if let ball = item1 as? BonusBallView {
                mainView.updateBonusLabelFor(ball.bonus)
                DispatchQueue.global().async {
                    self.runBonus(bonus: ball.bonus)
                }
            }

            var dynBullet : DynamicItemWithTag? = item2 as? DynamicItemWithTag
            var dynBall : DynamicItemWithTag? = item1 as? DynamicItemWithTag
            if item1 is BulletView {
                (dynBall, dynBullet) = (dynBullet, dynBall)
            }
            guard let dynBall, let dynBullet else { return }
            self.mainView.bullets[dynBullet.tag].removeFromSuperview()
            self.bulletsCollisionBehavior.removeItem(dynBullet)
            self.bulletsVelocityBehavior.removeItem(dynBullet)
            self.removeBall(dynamicBall: dynBall)
        }
    }
}








