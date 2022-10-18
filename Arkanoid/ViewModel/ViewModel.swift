//
//  ViewModel.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 01.10.2022.
//

import Foundation

class ViewModel {
    
    let soundManager = SoundManager()
    var shotReserve = Dynamic(0)
    
    func createBoard(viewWidth: Double, viewHeight: Double, completion: @escaping (ObjectModel) -> Void) {
        let boardWidth = viewWidth / 6
        let boardHeight = viewHeight / 20
        let board = ObjectModel(size: SizeModel(width: boardWidth,
                                                height: boardHeight))
        completion(board)
    }
    
    func createBalls(count: Int, viewWidth: Double, completion: (BallModel) -> Void) {
        var arraysWithBalls = [[BallModel]()]
        var ballIndex = 0
        var arrayIndex = 0
        var coefficient = 1
        var maxBallsInLine = 30
        let ballDiameter = (viewWidth - Double((maxBallsInLine - 1) * 2)) / Double(maxBallsInLine)
        for number in 0...(count - 1) {
            arraysWithBalls[arrayIndex].append(BallModel(diameter: ballDiameter,
                                                         origin: PointModel(x: 0,
                                                                            y: 0),
                                                         number: number))
            ballIndex += 1
            if ballIndex == maxBallsInLine {
                ballIndex = 0
                arrayIndex += 1
                maxBallsInLine -= coefficient
                coefficient *= -1
                arraysWithBalls.append([BallModel]())
            }
        }
        
        for (arrayIndex, array) in arraysWithBalls.enumerated() {
            for (index, var ball) in array.enumerated() {
                var x = ballDiameter * Double(index) + Double(2 * index)
                if !arrayIndex.isMultiple(of: 2) {
                    x += (ballDiameter / 2) + 1
                }
                let y = ballDiameter * Double(arrayIndex)
                ball.origin.x = x
                ball.origin.y = y
                completion(ball)
            }
        }
    }
    
    func createShotMenu(viewWidth: Double, viewHeight: Double, completion: (ShotMenuModel) -> Void) {
        let menuWidth = viewWidth / 5
        let menuHeight = menuWidth / 2
        let menuOriginX = viewWidth
        let menuOriginY = viewHeight - menuHeight - 10
        completion(ShotMenuModel(height: menuHeight,
                                 width: menuWidth,
                                 origin: PointModel(x: menuOriginX,
                                                    y: menuOriginY)))
    }
    
    func createGun(leftGun: Bool, boardMinX: Double, boardMaxX: Double, boardMidY: Double, boardHeight: Double, completion: (GunModel) -> Void ) {
        let gunHeight = boardHeight * 0.7
        let gunWidth = gunHeight / 2
        let gunCenterY = boardMidY + (-boardHeight * 0.15) + 1
        var gunCenterX : Double
        switch leftGun {
        case true:
            gunCenterX = boardMinX + 10
        case false:
            gunCenterX = boardMaxX - 10
        }
        completion(GunModel(size: SizeModel(width: gunWidth,
                                            height: gunHeight),
                            center: PointModel(x: gunCenterX,
                                               y: gunCenterY)))
    }
    
    func calculateVectorFromBoard(boardStartX: Double, boardEndX: Double, collisionPointX: Double, boardAcceleration: Double, dXYBefore: Double, completion: (VectorModel) -> Void) {
        var multiplierX : Double = 1
        var maxDxy = dXYBefore
        if dXYBefore > 3 {
            maxDxy = 3
        } else if dXYBefore < 1 {
            maxDxy = 1
        }
        let maxDx = maxDxy * 0.9
        let maxDy = -maxDxy * 1.1
        let boardCenterX = (boardStartX + boardEndX) / 2
        var dx = (collisionPointX - boardCenterX) * maxDx / (boardCenterX - boardStartX)
        var dy = maxDy + abs(dx)
        if dx < 0 {
            multiplierX = -1
        }
        dx = (abs(dx) + abs(boardAcceleration) * 0.2) * multiplierX
        dy = (abs(dy) + abs(boardAcceleration) * 0.2) * -1

        completion(VectorModel(dx: dx,
                               dy: dy))
    }
    
    func getRandomVector(comletion: (VectorModel) -> Void) {
        guard let random = (-18...18).randomElement() else { return }
        let dx = Double(random) * 0.1
        let dy = -2 + abs(dx)
        comletion(VectorModel(dx: dx,
                              dy: dy))
    }
    
    func calculateVectorFromBall(ballCenterX: Double, ballCenterY: Double, mainBallCenterX: Double, mainBallCenterY: Double, dXYBefore: Double, completion: (VectorModel) -> Void) {
        let maxDxy = dXYBefore
        var dx = atan(mainBallCenterX - ballCenterX)
        var dy = atan(mainBallCenterY - ballCenterY)
        if abs(dx) + abs(dy) > maxDxy {
            while abs(dx) + abs(dy) > maxDxy {
                dx = dx - (dx * 0.1)
                dy = dy - (dy * 0.1)
            }
        } else if abs(dx) + abs(dy) < maxDxy {
            while abs(dx) + abs(dy) < maxDxy {
                dx = dx + (dx * 0.1)
                dy = dy + (dy * 0.1)
            }
        }
        completion(VectorModel(dx: dx,
                               dy: dy))
    }
    
    func getLenghtCoefficientForBoard(bonus: Bonus, viewWidth: Double, boardLenght: Double, completion: (Double) -> Void) {
        switch bonus {
        case .longBoard:
            if viewWidth * 0.5 > boardLenght {
                completion(1.2)
            } else {
                break
            }
        case .shortBoard:
            if boardLenght > viewWidth / 10 {
                completion(0.8)
            } else {
                break
            }
        default: break
        }
    }
    
    func changeSpeed(bonus: Bonus, dxNow: Double, dyNow: Double, completion: (VectorModel) -> Void) {
        var dx = dxNow
        var dy = dyNow
        switch bonus {
        case .acceleration:
            if abs(dx) + abs(dy) < 3 {
                if dx > 0 {
                    dx += 0.2
                    dy -= 0.2
                } else if dx < 0 {
                    dx -= 0.2
                    dy -= 0.2
                } else {
                    dy -= 0.4
                }
            }
        case .deceleration:
            if abs(dx) + abs(dy) > 1.4 {
                if dx > 0 {
                    dx -= 0.2
                    dy += 0.2
                } else if dx < 0 {
                    dx += 0.2
                    dy += 0.2
                } else {
                    dy += 0.4
                }
            }
        default: break
        }
        completion(VectorModel(dx: dx,
                               dy: dy))
    }
    
    func createBullets(gunWidth: Double, gunHeight: Double, completion: (ObjectModel) -> Void) {
        let bulletHeight = gunHeight * 0.8
        let bulletWidth = gunWidth * 0.8
        completion(ObjectModel(size: SizeModel(width: bulletWidth,
                                               height: bulletHeight)))
    }
    
    func moveShotMenu(menuWidth: Double, isHidingNow: Bool, completion: (Double) -> Void) {
        switch isHidingNow {
        case true:
            completion(menuWidth + 10)
        case false:
            completion(-(menuWidth + 10))
        }
    }
    
    func moveGuns(gunHeight: Double, isHidingNow: Bool, completion: (Double) -> Void) {
        switch isHidingNow {
        case true:
            completion (gunHeight)
        case false:
            completion (-gunHeight)
        }
    }
    
    func playSound(sound: Sounds) {
        soundManager.play(sound: sound)
    }
    
    func getWinOrLosePoint(win: Bool, centerX: Double, centerY: Double, number: Int, diameter: Double, completion: (PointModel) -> Void) {
        var shift = (x: 1, y: 1)
        if (1...27).contains(number) {
            switch number {
            case 1: shift = (-14, -2)
            case 2: shift = (-14, -1)
            case 3: shift = (-14, 0)
            case 4: shift = (-13, 1)
            case 5: shift = (-13, 2)
            case 6: shift = (-12, -2)
            case 7: shift = (-12, -1)
            case 8: shift = (-12, 0)
            case 9: shift = (-10, -1)
            case 10: shift = (-10, 0)
            case 11: shift = (-10, 1)
            case 12: shift = (-9, 2)
            case 13: shift = (-9, -2)
            case 14: shift = (-8, -1)
            case 15: shift = (-8, 0)
            case 16: shift = (-8, 1)
            case 17: shift = (-6, -2)
            case 18: shift = (-6, -1)
            case 19: shift = (-6, 0)
            case 20: shift = (-6, 1)
            case 21: shift = (-5, 2)
            case 22: shift = (-4, -2)
            case 23: shift = (-4, -1)
            case 24: shift = (-4, 0)
            case 25: shift = (-4, 1)
            case 26: shift = (0, -2)
            case 27: shift = (0, -1)
            default: break
            }
        } else if !win {
            switch number {
            case 28: shift = (0, 0)
            case 29: shift = (0, 1)
            case 30: shift = (0, 2)
            case 31: shift = (1, 2)
            case 32: shift = (2, 2)
            case 33: shift = (5, -2)
            case 34: shift = (4, -1)
            case 35: shift = (4, 0)
            case 36: shift = (4, 1)
            case 37: shift = (5, 2)
            case 38: shift = (6, -1)
            case 39: shift = (6, 0)
            case 40: shift = (6, 1)
            case 41: shift = (9, -2)
            case 42: shift = (10, -2)
            case 43: shift = (8, -1)
            case 44: shift = (9, 0)
            case 45: shift = (10, 1)
            case 46: shift = (8, 2)
            case 47: shift = (9, 2)
            case 48: shift = (12, -2)
            case 49: shift = (12, -1)
            case 50: shift = (12, 0)
            case 51: shift = (12, 1)
            case 52: shift = (12, 2)
            case 53: shift = (13, -2)
            case 54: shift = (14, -2)
            case 55: shift = (13, 0)
            case 56: shift = (14, 0)
            case 57: shift = (13, 2)
            case 58: shift = (14, 2)
            default: break
            }
        } else {
            switch number {
            case 28: shift = (1, 0)
            case 29: shift = (1, 1)
            case 30: shift = (2, 2)
            case 31: shift = (3, 0)
            case 32: shift = (3, 1)
            case 33: shift = (4, 2)
            case 34: shift = (5, 0)
            case 35: shift = (5, 1)
            case 36: shift = (6, -2)
            case 37: shift = (6, -1)
            case 38: shift = (8, -2)
            case 39: shift = (8, -1)
            case 40: shift = (8, 0)
            case 41: shift = (8, 1)
            case 42: shift = (8, 2)
            case 43: shift = (10, -2)
            case 44: shift = (10, -1)
            case 45: shift = (10, 0)
            case 46: shift = (10, 1)
            case 47: shift = (10, 2)
            case 48: shift = (11, -1)
            case 49: shift = (12, 0)
            case 50: shift = (13, 1)
            case 51: shift = (14, -2)
            case 52: shift = (14, -1)
            case 53: shift = (14, 0)
            case 54: shift = (14, 1)
            case 55: shift = (14, 2)
            default: break
            }
        }
        let point = PointModel(x: centerX + Double(shift.x) * diameter,
                               y: centerY + Double(shift.y) * diameter)
        completion(point)
        }
}
