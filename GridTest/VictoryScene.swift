//
//  VictoryScene.swift
//  GridTest
//
//  Created by Robert Herrera on 4/26/18.
//  Copyright © 2018 Robert Herrera. All rights reserved.
//


import Foundation
import UIKit
import SpriteKit

class VictoryScene: SKScene {
    
    var notificationLabel = SKLabelNode(text: "You Win!\n Touch anywhere to restart.")
    override init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = SKColor.blue
        
        addChild(notificationLabel)
        notificationLabel.fontSize = 16.0
        notificationLabel.color = SKColor.white
        notificationLabel.fontName = "Thonburi-Bold"
        notificationLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        view?.presentScene(gameScene, transition: reveal)
    }
}
