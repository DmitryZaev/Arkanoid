//
//  SoundManager.swift
//  Arkanoid
//
//  Created by Dmitry Victorovich on 13.10.2022.
//

import Foundation
import AVFoundation

enum Sounds: String {
    case bubble = "bubble"
    case bounce = "bounce"
    case shot = "shot"
    case moveGuns = "moveGuns"
    case bonus = "bonus"
    case win = "win"
    case lose = "lose"
}

var bubblePlayer = AVPlayer()
var bouncePlayer = AVPlayer()
var shotPlayer = AVPlayer()
var moveGunsPlayer = AVPlayer()
var bonusPlayer = AVPlayer()
var gameOverPlayer = AVPlayer()

final class SoundManager {
    
    func play(sound: Sounds) {
        let ext = "mp3"
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: ext) else { return }
        switch sound {
        case .bubble:
            bubblePlayer = AVPlayer(url: url)
            bubblePlayer.play()
        case .bounce:
            bouncePlayer = AVPlayer(url: url)
            bouncePlayer.play()
        case .shot:
            shotPlayer = AVPlayer(url: url)
            shotPlayer.play()
        case .moveGuns:
            moveGunsPlayer = AVPlayer(url: url)
            moveGunsPlayer.play()
        case .bonus:
            bonusPlayer = AVPlayer(url: url)
            bonusPlayer.play()
        case .win, .lose:
            gameOverPlayer = AVPlayer(url: url)
            gameOverPlayer.play()
        }
    }
}
