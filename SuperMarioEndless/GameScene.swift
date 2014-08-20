//
//  GameScene.swift
//  SuperMarioEndless
//
//  Created by Yoshi Sugawara on 8/17/14.
//  Copyright (c) 2014 Yoshi Sugawara. All rights reserved.
//

import SpriteKit
import AVFoundation

enum PlayerAction: String {
    case RUNNING = "running"
    case JUMPING = "jumping"
    case DYING = "die"
}

enum ColliderType: UInt32 {
    case Mario = 1
    case Enemy = 2
    case Ground = 4
    case Nothing = 8
}

class Player: SKSpriteNode {
    var runningAction: SKAction
    var jumpingAction: SKAction

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    init(textureFilenames: [String]) {
        // setup textures
        let marioTextures: [SKTexture] = textureFilenames.map({
            (textureName: String) -> SKTexture in
                let texture = SKTexture(imageNamed: textureName)
                texture.filteringMode = SKTextureFilteringMode.Linear
                return texture
        })
        

        runningAction = SKAction.repeatActionForever(
            SKAction.animateWithTextures(Array(marioTextures[1...3]), timePerFrame: 0.1)
        )
        
        jumpingAction = SKAction.repeatActionForever(
            SKAction.animateWithTextures([SKTexture(imageNamed: "mario-jump")], timePerFrame: 0.1)
        )

        super.init(texture: marioTextures[0], color: nil, size: marioTextures[0].size())
        
        setScale(2.0)

        physicsBody = SKPhysicsBody(circleOfRadius: self.size.height / 2)
        physicsBody.dynamic = true
        physicsBody.angularDamping = 0.0

        physicsBody.categoryBitMask = ColliderType.Mario.toRaw()
        physicsBody.collisionBitMask = ColliderType.Ground.toRaw() | ColliderType.Enemy.toRaw()
        physicsBody.contactTestBitMask = ColliderType.Enemy.toRaw()
        
        self.runAction(runningAction, withKey: PlayerAction.RUNNING.toRaw())

        println("mario size = \(self.size) , position = \(self.position.x),\(self.position.y)")
    }
    
    
    func jump() {
        if !isJumping() {
            let jumpSound = SKAction.playSoundFileNamed("jump.wav", waitForCompletion: true)
            self.runAction(jumpSound)
            self.runAction(jumpingAction, withKey: PlayerAction.JUMPING.toRaw())
            self.physicsBody.applyImpulse(CGVectorMake(0,16))
        }
    }
    
    func die() {
        removeActionForKey(PlayerAction.DYING.toRaw())
        let moveUp = SKAction.moveByX(0, y: 40.0, duration: 0.2)
        let fallDown = SKAction.moveToY(-20, duration: 0.8)
        // play death animation
        runAction(
            SKAction.repeatActionForever(
                SKAction.animateWithTextures([SKTexture(imageNamed: "death")], timePerFrame: 0.1)
            ),
            withKey: PlayerAction.DYING.toRaw())
        // play sound
        runAction(SKAction.playSoundFileNamed("die.wav", waitForCompletion: false))
        
        runAction(SKAction.sequence([SKAction.waitForDuration(1.0),
            moveUp, fallDown]))
    }
    
    func resetStatus() {
        removeActionForKey(PlayerAction.DYING.toRaw())
        removeActionForKey(PlayerAction.JUMPING.toRaw())
        physicsBody.collisionBitMask = ColliderType.Ground.toRaw() | ColliderType.Enemy.toRaw()
        runAction(runningAction, withKey: PlayerAction.RUNNING.toRaw())
    }
    
    func isJumping() -> Bool {
        return physicsBody.velocity.dy != 0.0
    }
    
    func updateAnimation() {
        if !isJumping() {
            self.removeActionForKey(PlayerAction.JUMPING.toRaw())
        }
    }
}

class Enemy: SKSpriteNode {
    
    var moveAndRemoveAction: SKAction!
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    init(textureFilename: String, screenWidth: Float, speedMultiplier: Float = 0.01) {
        println("speed multiplier = \(speedMultiplier)")
        let texture = SKTexture(imageNamed: "bullet")
        texture.filteringMode = SKTextureFilteringMode.Linear
        super.init(texture: texture, color: nil, size: texture.size())
        setScale(2.0)
        let moveDistance = CGFloat(screenWidth) + (2 * texture.size().width);
        let move = SKAction.moveByX(-moveDistance, y: 0, duration: NSTimeInterval(CGFloat(speedMultiplier) * moveDistance))
        let remove = SKAction.removeFromParent()
        moveAndRemoveAction = SKAction.sequence([move, remove])

        physicsBody = SKPhysicsBody(rectangleOfSize: self.size)
        physicsBody.dynamic = false
        physicsBody.categoryBitMask = ColliderType.Enemy.toRaw()
        physicsBody.collisionBitMask = ColliderType.Mario.toRaw()
        physicsBody.contactTestBitMask = ColliderType.Mario.toRaw()
    }
    
    func move() {
        runAction(SKAction.playSoundFileNamed("fire.wav", waitForCompletion: true))
        self.runAction(moveAndRemoveAction)
    }
    
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var mario: Player!
    
    var audioPlayer: AVAudioPlayer!
    
    let skyColor = UIColor(red: 107.0 / 255.0, green: 140.0 / 255.0, blue: 1.0, alpha: 1.0)
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.physicsWorld.gravity = CGVectorMake(0, -5)
        self.backgroundColor = skyColor
        
        self.physicsWorld.contactDelegate = self
        
        mario = Player(textureFilenames: ["mario-stand","mario-run1","mario-run2","mario-run3"])
        mario.position = CGPointMake(self.frame.size.width / 3, CGRectGetMidY(self.frame))
        self.addChild(mario)
        
        // ground
        let groundTex = SKTexture(imageNamed: "ground")
        groundTex.filteringMode = SKTextureFilteringMode.Linear

        let groundMove = SKAction.moveByX(
            -groundTex.size().width * 2.0,
            y: 0,
            duration: NSTimeInterval(0.02 * groundTex.size().width * 2))
        
        let groundReset = SKAction.moveByX(groundTex.size().width * 2.0, y: 0, duration: 0.0)
        let groundScroll = SKAction.repeatActionForever(
            SKAction.sequence([groundMove, groundReset])
        )

        let numGroundTexturesToFillScreen = Int(self.frame.size.width / (groundTex.size().width * 2.0))
        for var i = 0; i < numGroundTexturesToFillScreen + 3; ++i {
            let sprite = SKSpriteNode(texture: groundTex)
            sprite.setScale(2.0)
            sprite.position = CGPointMake(CGFloat(i) * sprite.size.width, sprite.size.height / 2)
            sprite.runAction(groundScroll)
            self.addChild(sprite)
        }
        
        // ground physics
        let groundPhysicsContainer = SKNode()
        groundPhysicsContainer.position = CGPointMake(0, groundTex.size().height)
        groundPhysicsContainer.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width * 2, groundTex.size().height * 2))
        groundPhysicsContainer.physicsBody.dynamic = false
        groundPhysicsContainer.physicsBody.categoryBitMask = ColliderType.Ground.toRaw()
        self.addChild(groundPhysicsContainer)

        // background
        let backgroundTex = SKTexture(imageNamed: "background")
        backgroundTex.filteringMode = SKTextureFilteringMode.Linear
        
        let backgroundMove = SKAction.moveByX(-backgroundTex.size().width * 2.0, y: 0, duration: NSTimeInterval(0.06 * backgroundTex.size().width * 2))
        let backgroundReset = SKAction.moveByX(backgroundTex.size().width * 2.0, y: 0, duration: 0.0)
        let backgroundScroll = SKAction.repeatActionForever(
            SKAction.sequence([backgroundMove, backgroundReset])
        )
        
        let numBackgroundTexturesToFillScreen = Int(self.frame.size.width / (backgroundTex.size().width * 2.0))
        for var i = 0; i < numGroundTexturesToFillScreen + 3; ++i {
            let sprite = SKSpriteNode(texture: backgroundTex)
            sprite.setScale(2.0)
            sprite.zPosition = -20
            sprite.position = CGPointMake(CGFloat(i) * sprite.size.width, sprite.size.height - 95)
            sprite.runAction(backgroundScroll)
            self.addChild(sprite)
        }

        // enemy
        let spawnEnemy = SKAction.runBlock(self.spawnEnemy)
        let delay = SKAction.waitForDuration(2.0)
        let spawnThenDelay = SKAction.sequence([spawnEnemy, delay])
        let spawnThenDelayForeva = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForeva)
        
        let music = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("maintheme", ofType: "mp3"))
        println(music)
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
        var error:NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: music, error: &error)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        mario.jump()
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        mario.updateAnimation()
    }
    
    override func didSimulatePhysics() {
        // he shouldn't rotate
        mario.zRotation = 0
        // pin his x-position
        mario.position = CGPointMake(self.frame.size.width / 3, mario.position.y)
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        println("collision!")
        removeActionForKey("flash")
        runAction(
            SKAction.sequence(
                [SKAction.repeatAction(
                    SKAction.sequence(
                        [SKAction.runBlock({
                            self.backgroundColor = SKColor.redColor()
                         }),
                         SKAction.waitForDuration(0.05),
                         SKAction.runBlock({
                            self.backgroundColor = self.skyColor
                         }),
                         SKAction.waitForDuration(0.05)
                        ]
                    ), count: 4)
                 ]
            ), withKey: "flash"
        )
        playerDeath()
    }
    
    func spawnEnemy() {
        // make the moving speed random
        let moveSpeedMultiplier = Float(Int(arc4random_uniform(5)) + 5) / 1000.0
        let enemy = Enemy(textureFilename: "bullet", screenWidth: Float(self.frame.size.width), speedMultiplier: moveSpeedMultiplier)
        // make it appear in a random height above the ground
        let randomY = (Int(rand()) % (Int(self.frame.size.height / 3))) + 70
        println("block Y position = \(randomY)")
        // put it off screen
        enemy.position = CGPointMake(self.frame.width + enemy.size.width * 2, CGFloat(randomY))
        self.addChild(enemy)
        enemy.move()
    }
    
    func playerDeath() {
        let modifyPhysics = {
            () -> () in
            // disable physics
            self.physicsWorld.gravity = CGVectorMake(0,0)
            // don't collide and detect collisions anymore
            self.mario.physicsBody.collisionBitMask = ColliderType.Nothing.toRaw()
            self.mario.physicsBody.contactTestBitMask = ColliderType.Nothing.toRaw()
        }
        let modAction = SKAction.runBlock(modifyPhysics)
        let playerDie = SKAction.runBlock(mario.die)
        audioPlayer.stop()
        runAction(SKAction.sequence([modAction, playerDie]))
    }
    
}
