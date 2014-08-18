//
//  GameScene.swift
//  SuperMarioEndless
//
//  Created by Yoshi Sugawara on 8/17/14.
//  Copyright (c) 2014 Yoshi Sugawara. All rights reserved.
//

import SpriteKit

enum PlayerAction: String {
    case RUNNING = "running"
    case JUMPING = "jumping"
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
    
    func isJumping() -> Bool {
        return physicsBody.velocity.dy != 0.0
    }
    
    func updateAnimation() {
        if !isJumping() {
            self.removeActionForKey(PlayerAction.JUMPING.toRaw())
        }
    }
}

class GameScene: SKScene {
    
    var mario: Player!
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        self.physicsWorld.gravity = CGVectorMake(0, -5)
        self.backgroundColor = UIColor(red: 107.0 / 255.0, green: 140.0 / 255.0, blue: 1.0, alpha: 1.0)
        
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
        groundPhysicsContainer.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTex.size().height * 2))
        groundPhysicsContainer.physicsBody.dynamic = false
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

        self.runAction(SKAction.repeatActionForever(SKAction.playSoundFileNamed("maintheme.mp3", waitForCompletion: true)))
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        mario.jump()
        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        mario.updateAnimation()
    }
}
