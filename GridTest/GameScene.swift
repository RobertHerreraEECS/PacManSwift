//
//  GameScene.swift
//  GridTest
//
//  Created by Robert Herrera on 4/22/18.
//  Copyright © 2018 Robert Herrera. All rights reserved.
//


/*
 * BUGS:
 * - pacman movement somtimes negates tile detection and will "phase" throught the wall.
 * TODO:
 * - seperate sprites by classes
 * - sectorize ghosts when scattering
 * - config file to controll all settings
 * - cached movement
 */

import SpriteKit
import GameplayKit

// Globals
fileprivate let SCALE_FACTOR = 0.0325
fileprivate let VELOCITY = 300
fileprivate let GHOST_SPEED = 80
fileprivate let MOVEMENT_DURATION = 3
fileprivate let UP = 2
fileprivate let DOWN = 3
fileprivate let LEFT = 1
fileprivate let RIGHT = 0
fileprivate let IDLE = -1

let WALL = "0"
let GHOST_BARRIER = "#"
let PELLET = "+"
let POWER_PELLET = "p"

// Image globals
fileprivate let GAME_TILE_IMAGE = "blue"
fileprivate let GHOST_TILE_IMAGE = "pink"
fileprivate let PACMAN_IMAGE = "pacImage"
fileprivate let PELLET_IMAGE = "yellow-circle-md"
fileprivate let INKY_IMAGE = "inky"
fileprivate let PINKY_IMAGE = "pinky"
fileprivate let BLINKY_IMAGE = "blinky"
fileprivate let CLYDE_IMAGE = "clyde"
fileprivate let SCATTER_IMAGE = "ghost"
fileprivate let RETURN_HOME_IMAGE = "eyes"

// Sound globals
fileprivate let PACMAN_CHOMP = "pacman_chomp.wav"
fileprivate let PACMAN_POWER = "pacman_eatfruit.wav"
fileprivate let PACMAN_CHOMP_GHOST = "pacman_eatghost.wav"
fileprivate let PACMAN_INTRO = "pacman_beginning.wav"
let PACMAN_DEATH = "pacman_death.wav"
let PACMAN_WIN = "pacman_intermission.wav"

//init your categoryBitMask :
let pacManCategory:UInt32 = 0x1 << 0
let GhostCategory:UInt32 = 0x1 << 1

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var gameOver: Bool = false
    private let  grid = Grid(blockSize: 15.0, rows:29, cols:28)
    var direction: Int = IDLE
    var totalSeconds:Int = 0
    var ghostTotalSeconds:Int = 0
    var isInPowerMode: Bool = false

    // game characters
    let PacMan = SKSpriteNode(imageNamed: PACMAN_IMAGE)
    let inky = SKSpriteNode(imageNamed: INKY_IMAGE)
    let pinky = SKSpriteNode(imageNamed: PINKY_IMAGE)
    let clyde = SKSpriteNode(imageNamed: CLYDE_IMAGE)
    let blinky = SKSpriteNode(imageNamed: BLINKY_IMAGE)
    
    // list of pellet loctations
    private var Pellets: [(Int,Int)] = []
    // ghost list for easy access
    private var Ghosts: [SKSpriteNode] = [SKSpriteNode]()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        self.isUserInteractionEnabled = true
    }
    
    deinit{}

    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        MapManager.generateMapFromText(file: "map")
        initializeSwipeDirections()
        grid?.position = CGPoint (x:frame.midX, y:frame.midY)
        addChild(grid!)
        
        // add tiles and pellets
        self.populateGrid()
        
        // PacMan params
        PacMan.setScale(CGFloat(SCALE_FACTOR * 0.20))
        PacMan.position = (grid?.gridPosition(row: 16, col: 13))!
 
        // register all ghost sprites
        inky.name = "inky"
        pinky.name = "pinky"
        clyde.name = "clyde"
        blinky.name = "blinky"
        Ghosts.append(inky)
        Ghosts.append(pinky)
        Ghosts.append(clyde)
        Ghosts.append(blinky)
        
        // set sprite physics for collision detection
        self.initPhysics()
        view.showsPhysics = true
        
        // set ghosts params
        for (i,g) in Array(Ghosts).enumerated() {
            g.setScale(CGFloat(SCALE_FACTOR))
            g.position = (grid?.gridPosition(row: 14, col: 11 + i))!
            grid?.addChild(g)
        }
    }
    
    override func sceneDidLoad() {
        // intro
        let sound = SKAction.playSoundFileNamed(PACMAN_INTRO, waitForCompletion: true)
        self.run(sound, completion: {() -> Void in
            // add sprites to grid
            self.grid?.addChild(self.PacMan)
            // show usage
            self.usage()
            // start looking for pacman
            self.searchSchedule()
        })
    }

    
    override func update(_ currentTime: TimeInterval) {
        if self.gameOver == false {
            // update pellet count
            self.checkForPellet()
            // check if pac-man has eaten all pellets
            self.checkWin()
        }
    }
    
    // MARK: Game Logic
    override func didFinishUpdate() {
        let currentPosition = grid?.sendPosition(position: PacMan.position)
        // check for legal moves
        if direction == RIGHT && gridFile[(currentPosition?.0)!][(currentPosition?.1)! + 1] == WALL{
            self.cancelMovement()
        } else if direction == LEFT && gridFile[(currentPosition?.0)!][(currentPosition?.1)! - 1] == WALL{
            self.cancelMovement()
        } else if direction == UP && gridFile[(currentPosition?.0)! - 1][(currentPosition?.1)!] == WALL{
            self.cancelMovement()
        } else if direction == DOWN && (gridFile[(currentPosition?.0)! + 1][(currentPosition?.1)!] == WALL){
            self.cancelMovement()
        }
        
        if direction == RIGHT && gridFile[(currentPosition?.0)!][(currentPosition?.1)! + 1] == GHOST_BARRIER{
            self.cancelMovement()
        } else if direction == LEFT && gridFile[(currentPosition?.0)!][(currentPosition?.1)! - 1] == GHOST_BARRIER{
            self.cancelMovement()
        } else if direction == UP && gridFile[(currentPosition?.0)! - 1][(currentPosition?.1)!] == GHOST_BARRIER{
            self.cancelMovement()
        } else if direction == DOWN && (gridFile[(currentPosition?.0)! + 1][(currentPosition?.1)!] == GHOST_BARRIER){
            self.cancelMovement()
        }

        // check for coordinate wrapping
        if (currentPosition?.0)! == 13 && (currentPosition?.1)! == 27 {
            PacMan.position = (grid?.gridPosition(row: 13, col: 2))!
        } else if (currentPosition?.0)! == 13 && (currentPosition?.1)! == 1 {
            PacMan.position = (grid?.gridPosition(row: 13, col: 26))!
        }
        
        for g in self.Ghosts {
            // check for coordinate wrapping
            let currentPosition = grid?.sendPosition(position: g.position)
            if (currentPosition?.0)! == 13 && (currentPosition?.1)! == 27 {
                g.position = (grid?.gridPosition(row: 13, col: 2))!
            } else if (currentPosition?.0)! == 13 && (currentPosition?.1)! == 1 {
                g.position = (grid?.gridPosition(row: 13, col: 26))!
            }
        }
    }
    
    
    func checkWin() {
        if Pellets.count == 0 {
            let sound = SKAction.playSoundFileNamed(PACMAN_WIN, waitForCompletion: true)
            playSound(sound: sound)
            restart(msg:"win")
        }
    }
    
    func triggerLoss() {
        self.grid?.isPaused = true
        //self.scene?.view?.isPaused = true
        restart(msg:"loss")
    }
    
    func restart(msg: String) {
        Pellets.removeAll(keepingCapacity: false)
        ObjectArray.removeAll(keepingCapacity: false)
        self.gameOver = true
        goToGameScene(msg: msg)
    }
    
    func goToGameScene(msg: String){
        if msg == "loss" {
            let gameOverScene = GameOverScene(size: size)
            gameOverScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(gameOverScene, transition: reveal)
        } else {
            let victoryScene = VictoryScene(size: size)
            victoryScene.scaleMode = scaleMode
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            view?.presentScene(victoryScene, transition: reveal)
        }
    }
    
    
    func checkForPellet() {
        let currentPosition = self.grid?.sendPosition(position: self.PacMan.position)
        for (index,p) in Array(Pellets).enumerated() {
            if currentPosition! == p {
                let sprites = self.grid?.nodes(at: self.PacMan.position)
                for _ in sprites! {
                    if let child = self.grid?.childNode(withName: "pellet_\(currentPosition!.0)_\(currentPosition!.1)") as? SKSpriteNode {
                        child.removeFromParent()
                        Pellets.remove(at: index)
                        
                        // check for Power pellet
                        if gridFile[(currentPosition?.0)!][(currentPosition?.1)!] == "p" {
                            let sound = SKAction.playSoundFileNamed(PACMAN_POWER, waitForCompletion: true)
                            playSound(sound: sound)
                            // trigger blue ghosts and scatter
                            for g in Ghosts {
                                g.texture = SKTexture(imageNamed: SCATTER_IMAGE)
                                self.removeAction(forKey: "search_mode")
                                g.removeAllActions()
                            }
                            self.totalSeconds = 0
                            self.isInPowerMode = true
                            self.scatterSchedule()
                            
                        } else {
                            let sound = SKAction.playSoundFileNamed(PACMAN_CHOMP, waitForCompletion: true)
                            playSound(sound: sound)
                        }
                    }
                }
                break
            }
        }
    }
    
    func initPhysics() {
        let pacSize = CGSize(width: (PacMan.texture?.size().width)! * CGFloat(SCALE_FACTOR * 0.2), height: (PacMan.texture?.size().height)! * CGFloat(SCALE_FACTOR * 0.2))
        PacMan.physicsBody = SKPhysicsBody(texture: PacMan.texture!, size: pacSize)
        PacMan.physicsBody!.categoryBitMask = pacManCategory
        PacMan.physicsBody!.contactTestBitMask = PacMan.physicsBody!.collisionBitMask
        PacMan.physicsBody?.isDynamic = false
        PacMan.physicsBody?.affectedByGravity = false
        PacMan.physicsBody?.allowsRotation = false
        
        for g in self.Ghosts {
            let size = CGSize(width: (g.texture?.size().width)! * CGFloat(SCALE_FACTOR), height: (g.texture?.size().height)! * CGFloat(SCALE_FACTOR))
            g.physicsBody = SKPhysicsBody(texture: g.texture!, size: size)
            g.physicsBody!.categoryBitMask = GhostCategory
            g.physicsBody!.contactTestBitMask = g.physicsBody!.collisionBitMask
            g.physicsBody?.isDynamic = true
            g.physicsBody?.affectedByGravity = false
            g.physicsBody?.allowsRotation = false
        }
    }
    
    func searchSchedule(){
        // Search for pacman every few seconds
        let wait:SKAction = SKAction.wait(forDuration: 0)
        let finishTimer:SKAction = SKAction.run {
            self.totalSeconds += 1
            if self.totalSeconds == 4 {
                for ghost in self.Ghosts { self.search(ghost: ghost, target: self.PacMan) }
            } else if self.totalSeconds == 10{
                // reset timer
                self.totalSeconds = 0
            }
            self.searchSchedule()
        }
        let seq:SKAction = SKAction.sequence([wait, finishTimer])
        self.run(seq, withKey: "search_mode")
    }
    
    
    func scatterSchedule() {
        // Search for pacman every few seconds
        let wait:SKAction = SKAction.wait(forDuration: 1)
        let finishTimer:SKAction = SKAction.run {
            self.totalSeconds += 1
            if self.totalSeconds == 1 {
                // check to see if pacman has eaten ghost first
                for ghost in self.Ghosts {
                    if ghost.texture?.name != RETURN_HOME_IMAGE { self.knownSearch(ghost: ghost, target: MapManager.getOpenCoodinate()) }
                }
            } else if self.totalSeconds == 10{
                // reset timer
                self.totalSeconds = 0
                self.removeAction(forKey: "scatter_mode")
                for g in self.Ghosts {
                    // check to see if pacman has eaten ghost first
                    if g.texture?.name != RETURN_HOME_IMAGE {
                        g.removeAllActions()
                        g.texture = SKTexture(imageNamed: g.name!)
                    }
                }
                self.searchSchedule()
                self.isInPowerMode = false
            }
            self.scatterSchedule()
        }
        
        let seq:SKAction = SKAction.sequence([wait, finishTimer])
        self.run(seq, withKey: "scatter_mode")
    }
    
    func returnHome(ghost: SKSpriteNode, target: (Int, Int)){
        // Search for pacman every few seconds
        let wait:SKAction = SKAction.wait(forDuration: 0)
        
        let currentPosition = self.grid?.sendPosition(position: ghost.position)
        let path = PathFinder(from:currentPosition!, to: target).search()
        if path.count > 0 {
            let Path = UIBezierPath()
            Path.move(to: (self.grid?.gridPosition(row: (currentPosition?.0)!, col: (currentPosition?.1)!))!)
            for coordinate in path {
                Path.addLine(to: (self.grid?.gridPosition(row: coordinate.0, col: coordinate.1))!)
            }
            let move = SKAction.follow(Path.cgPath, asOffset: false, orientToPath: false, speed: CGFloat(GHOST_SPEED))
            let seq:SKAction = SKAction.sequence([move,wait])
            ghost.run(seq, withKey: "return_mode")
        }
    }
    
    func search(ghost: SKSpriteNode, target: SKSpriteNode) {
        let currentPosition = self.grid?.sendPosition(position: ghost.position)
        let enemyPosition = self.grid?.sendPosition(position: target.position)
        let path = PathFinder(from: currentPosition!, to: enemyPosition!).search()

        if path.count > 0 {
            let Path = UIBezierPath()
            Path.move(to: (self.grid?.gridPosition(row: (currentPosition?.0)!, col: (currentPosition?.1)!))!)
            for coordinate in path {
                Path.addLine(to: (self.grid?.gridPosition(row: coordinate.0, col: coordinate.1))!)
            }
            let move = SKAction.follow(Path.cgPath, asOffset: false, orientToPath: false, speed: CGFloat(GHOST_SPEED))
            ghost.run(move)
        }
    }
    
    func knownSearch(ghost: SKSpriteNode, target: (Int,Int)) {
        let currentPosition = self.grid?.sendPosition(position: ghost.position)
        let path = PathFinder(from: currentPosition!, to: target).search()
        print(path)
        if path.count > 0 {
            let Path = UIBezierPath()
            Path.move(to: (self.grid?.gridPosition(row: (currentPosition?.0)!, col: (currentPosition?.1)!))!)
            for coordinate in path {
                Path.addLine(to: (self.grid?.gridPosition(row: coordinate.0, col: coordinate.1))!)
            }
            let move = SKAction.follow(Path.cgPath, asOffset: false, orientToPath: false, speed: CGFloat(GHOST_SPEED))
            ghost.run(move)
        }
    }
    
    // MARK: Game Initialization and Movement
    func playSound(sound : SKAction)
    {
        run(sound)
    }
    
    func usage() {
        // SKLabelNode
        let labelNode = SKLabelNode(fontNamed: "Helvetica")
        labelNode.text = "Swipe any direction..."
        labelNode.fontSize = 30
        labelNode.fontColor = SKColor.white
        labelNode.position = CGPoint(x: self.frame.size.width / 2, y: 10)
        labelNode.zPosition = 1
        self.addChild(labelNode)
    }
    
    func cancelMovement() {
        let Path = UIBezierPath()
        let currentPosition = grid?.sendPosition(position: PacMan.position)
        Path.move(to: (grid?.gridPosition(row: (currentPosition?.0)!, col: (currentPosition?.1)!))!)
        Path.addLine(to: (grid?.gridPosition(row: (currentPosition?.0)!, col: (currentPosition?.1)!))!)
        let move = SKAction.follow(Path.cgPath, asOffset: false, orientToPath: false, speed: 70)
        PacMan.run(move)
    }
    
    func populateGrid() {

        for object in ObjectArray {
            if object.NodeData == WALL {
                let gameTile = SKSpriteNode(imageNamed: GAME_TILE_IMAGE)
                gameTile.setScale(CGFloat(SCALE_FACTOR))
                gameTile.position = (grid?.gridPosition(row: object.coordinate.0, col: object.coordinate.1))!
                grid?.addChild(gameTile)
            } else if object.NodeData == GHOST_BARRIER {
                let gameTile = SKSpriteNode(imageNamed: GHOST_TILE_IMAGE)
                gameTile.setScale(CGFloat(SCALE_FACTOR))
                gameTile.position = (grid?.gridPosition(row: object.coordinate.0, col: object.coordinate.1))!
                grid?.addChild(gameTile)
            } else if object.NodeData == PELLET {
                let pellet = SKSpriteNode(imageNamed: PELLET_IMAGE)
                pellet.setScale(CGFloat(SCALE_FACTOR * 0.40))
                pellet.position = (grid?.gridPosition(row: object.coordinate.0, col: object.coordinate.1))!
                pellet.name = "pellet_\(object.coordinate.0)_\(object.coordinate.1)"
                Pellets.append(object.coordinate)
                grid?.addChild(pellet)
            } else if object.NodeData == POWER_PELLET {
                let pellet = SKSpriteNode(imageNamed: PELLET_IMAGE)
                pellet.setScale(CGFloat(SCALE_FACTOR))
                pellet.position = (grid?.gridPosition(row: object.coordinate.0, col: object.coordinate.1))!
                pellet.name = "pellet_\(object.coordinate.0)_\(object.coordinate.1)"
                Pellets.append(object.coordinate)
                grid?.addChild(pellet)
            }
        }
        
    }
    
    
    func initializeSwipeDirections(){
        
        let swipeRight:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedRight(_:)))
        swipeRight.direction = .right
        view!.addGestureRecognizer(swipeRight)
        
        
        let swipeLeft:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedLeft(_:)))
        swipeLeft.direction = .left
        view!.addGestureRecognizer(swipeLeft)
        
        
        let swipeUp:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedUp(_:)))
        swipeUp.direction = .up
        view!.addGestureRecognizer(swipeUp)
        
        
        let swipeDown:UISwipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(GameScene.swipedDown(_:)))
        swipeDown.direction = .down
        view!.addGestureRecognizer(swipeDown)
    }
    
    
    
    @objc func swipedRight(_ sender:UISwipeGestureRecognizer){
        let currentPosition = grid?.sendPosition(position: PacMan.position)
        if (direction == UP || direction == DOWN || direction == IDLE) && gridFile[(currentPosition?.0)!][(currentPosition?.1)! + 1] != "0" {
            let moveRight = SKAction.moveBy(x: CGFloat(VELOCITY), y: 0, duration: TimeInterval(MOVEMENT_DURATION))
            direction = RIGHT
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveRight))
        } else if direction == LEFT {
            let moveRight = SKAction.moveBy(x: CGFloat(VELOCITY), y: 0, duration: TimeInterval(MOVEMENT_DURATION))
            direction = RIGHT
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveRight))
        }
    }
    
    @objc func swipedLeft(_ sender:UISwipeGestureRecognizer){
        let currentPosition = grid?.sendPosition(position: PacMan.position)
        if (direction == UP || direction == DOWN || direction == IDLE) && gridFile[(currentPosition?.0)!][(currentPosition?.1)! - 1] != WALL {
            let moveLeft = SKAction.moveBy(x: -(CGFloat)(VELOCITY), y: 0, duration: TimeInterval(MOVEMENT_DURATION))
            direction = LEFT
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveLeft))
        } else if direction == RIGHT {
            let moveLeft = SKAction.moveBy(x: -(CGFloat)(VELOCITY), y: 0, duration: TimeInterval(MOVEMENT_DURATION))
            direction = LEFT
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveLeft))
        }
    }
    
    @objc func swipedUp(_ sender:UISwipeGestureRecognizer){
        let currentPosition = grid?.sendPosition(position: PacMan.position)
        if (direction == RIGHT || direction == LEFT || direction == IDLE) && gridFile[(currentPosition?.0)! - 1][(currentPosition?.1)!] != WALL {
            direction = UP
            let moveUp = SKAction.moveBy(x: 0, y: CGFloat(VELOCITY), duration: TimeInterval(MOVEMENT_DURATION))
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveUp))
        } else if direction == DOWN {
            direction = UP
            let moveUp = SKAction.moveBy(x: 0, y: CGFloat(VELOCITY), duration: TimeInterval(MOVEMENT_DURATION))
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveUp))
        }
    }
    
    @objc func swipedDown(_ sender:UISwipeGestureRecognizer){
        let currentPosition = grid?.sendPosition(position: PacMan.position)
        
         if (direction == RIGHT || direction == LEFT || direction == IDLE) && gridFile[(currentPosition?.0)! + 1][(currentPosition?.1)!] != WALL  {
            if gridFile[(currentPosition?.0)! + 1][(currentPosition?.1)!] != GHOST_BARRIER {
                direction = DOWN
                let moveDown = SKAction.moveBy(x: 0, y: -(CGFloat)(VELOCITY), duration: TimeInterval(MOVEMENT_DURATION))
                PacMan.removeAllActions()
                PacMan.run(SKAction.repeatForever(moveDown))
            }
        } else if direction == UP {
            direction = DOWN
            let moveDown = SKAction.moveBy(x: 0, y: -(CGFloat)(VELOCITY), duration: TimeInterval(MOVEMENT_DURATION))
            PacMan.removeAllActions()
            PacMan.run(SKAction.repeatForever(moveDown))
        }
        
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody

        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
        {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else
        {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if ((firstBody.categoryBitMask & pacManCategory) != 0 && (secondBody.categoryBitMask & GhostCategory) != 0)
        {
            if !self.isInPowerMode {
                self.triggerLoss()
            } else {
                for g in self.Ghosts {
                    if g.name == secondBody.node?.name {
                        g.texture = SKTexture(imageNamed: RETURN_HOME_IMAGE)
                        g.removeAllActions()
                        self.knownSearch(ghost: g, target: (14,12))
                        break
                    }
                }
            }
        }
    }
    
}

extension SKTexture {
    var name:String? {
        let comps = description.components(separatedBy: "'")
        return comps.count > 1 ? comps[1] : nil
    }
}

