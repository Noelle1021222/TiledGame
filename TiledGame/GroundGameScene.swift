//
//  GameScene.swift
//  TiledGame
//
//  Created by 許雅筑 on 2016/10/16.
//  Copyright (c) 2016年 hsu.ya.chu. All rights reserved.
//
import SpriteKit
import AVFoundation
import FBSDKLoginKit
import FBSDKCoreKit
struct PhysicsCatagory{ //交互影響，重力影響
    
    static let hero:UInt32 = 0x1 << 1
    static let Score:UInt32 = 0x1 << 2
    static let Enemy1:UInt32 = 0x1 << 3
    static let Enemy2:UInt32 = 0x1 << 4
    static let Enemy3:UInt32 = 0x1 << 5
    static let Enemy4:UInt32 = 0x1 << 6

    static let Finish:UInt32 = 0x1 << 10
    static let Pipe:UInt32 = 0x1 << 12
    static let Rectangle:UInt32 = 0x1 << 13

}

///////////////////////////
//joystick 2///////////////
///////////////////////////
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

infix operator ** { associativity left precedence 160 }
func ** (left: CGFloat, right: CGFloat) -> CGFloat! {
    return pow(left, right)
}
infix operator **= { associativity right precedence 90 }
func **= (inout left: CGFloat, right: CGFloat) {
    left = left ** right
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}
let Pi = CGFloat(M_PI)
let DegreesToRadians = Pi / 180
//////////////////////////////////

@available(iOS 9.0, *)
class GroundGameScene: SKScene, SKSceneDelegate, SKPhysicsContactDelegate {
//////////
    var joystick2:Joystick2?
    
    var coinPlayer:AVAudioPlayer!
    var villagePlayer:AVAudioPlayer!
    var jumpPlayer:AVAudioPlayer!
    var diedPlayer:AVAudioPlayer!
    var finishPlayer: AVAudioPlayer!
    
    //music
    let coinUrl = NSBundle.mainBundle().URLForResource("coin_music", withExtension: "mp3")
    let finishUrl = NSBundle.mainBundle().URLForResource("finish", withExtension: "mp3")
    let jumpUrl = NSBundle.mainBundle().URLForResource("jump", withExtension: "mp3")
    let diedUrl = NSBundle.mainBundle().URLForResource("died", withExtension: "mp3")
    let villageUrl = NSBundle.mainBundle().URLForResource("village", withExtension: "mp3")
//////////
    
    let map = JSTileMap(named: "level.tmx")
    var hero = SKSpriteNode(imageNamed: "flyman_6.png")
    var obstacles = SKNode()

    private var player = SKSpriteNode(imageNamed: "flyman_6.png")
    var score = Int()
    var EnemyOne = SKNode()
    var EnemyTwo = SKNode()
    var EnemyThree = SKNode()
    var EnemyFour = SKNode()
    var world = SKNode()
    var Coins = SKNode()
    var Pipes = SKNode()
    var Rectangles = SKNode()

    var pos:CGPoint?
    var initialPosition = CGPoint(x: 0,y: 0)
    let FinishLine = SKSpriteNode()
    var died = Bool()
    var cameraNode = SKCameraNode()
    let anothercameraNode:SKCameraNode = SKCameraNode()
    var onGround = Bool()
    
    var reverse1 : CGFloat = 1
    var reverse2 : CGFloat = 1
    var reverse3 : CGFloat = 1
    var reverse4 : CGFloat = 1
    
    var rectangle = SKNode()
    var groundScoreLbl = SKLabelNode() //生成score label
    var loseLabel = SKLabelNode()
    var winLabel = SKLabelNode()
    var rectangleChild = SKSpriteNode()
    var myLabel : SKLabelNode!
    //敵人用
    var moveAndRemoveEnemy = SKAction()

    var myCamera: SKCameraNode!
    var button = SKSpriteNode(imageNamed: "facebook.png")

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.commonShitInit()
        
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        self.commonShitInit()
    }
    
    func commonShitInit () -> () {
        
        // Setting Scene
        self.backgroundColor = UIColor(red: 104.0 / 255.0, green: 136.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0)
        //設同色
        self.addChild(self.map)
        
        //handle collision
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height))
        self.physicsBody?.friction = 0.0
        self.physicsWorld.contactDelegate = self
        //        self.physicsBody.collisionBitMask = 0
        //        self.physicsBody.contactTestBitMask = 0
        //        self.physicsWorld.gravity = CGVectorMake(0,0)
        //        self.physicsWorld.contactDelegate = self
        
        
        // Setting obstacles
        let collisionsGroup: TMXObjectGroup = self.map.groupNamed("Collisions")
        for(var i = 0; i < collisionsGroup.objects.count; i++) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as! NSDictionary
            
            print(collisionObject)
            
            let width = collisionObject.objectForKey("width") as! String
            let height = collisionObject.objectForKey("height") as! String
            let someObstacleSize = CGSize(width: Int(width)!, height: Int(height)!)
            print(someObstacleSize)
            let someObstacle = SKSpriteNode(color: UIColor.clearColor(), size: someObstacleSize)
            
            let y = collisionObject.objectForKey("y") as! Int
            let x = collisionObject.objectForKey("x") as! Int
            
            someObstacle.position = CGPoint(x: x + Int(collisionsGroup.positionOffset.x) + Int(width)!/2, y: y + Int(collisionsGroup.positionOffset.y) + Int(height)!/2)
            someObstacle.physicsBody = SKPhysicsBody(rectangleOfSize: someObstacleSize)
            someObstacle.physicsBody?.affectedByGravity = false
            someObstacle.physicsBody?.collisionBitMask = 0
            someObstacle.physicsBody?.friction = 0.4
            someObstacle.physicsBody?.restitution = 0.0  //反彈
            
            self.obstacles.addChild(someObstacle)
        }
        print(obstacles)
        self.addChild(self.obstacles)
        
        
        let PipeTileObjects: TMXObjectGroup = self.map.groupNamed("PipeLayer")
        for(var i = 0; i < PipeTileObjects.objects.count; i++) {
            let PipeObject = PipeTileObjects.objects.objectAtIndex(i) as! NSDictionary
            print("pipe: \(PipeObject)")
            
            let width = PipeObject.objectForKey("width") as! String
            let height = PipeObject.objectForKey("height") as! String
            let PiPeSize = CGSize(width: Int(width)!, height: Int(height)!)
            
            let somePipe = SKSpriteNode(color: UIColor.clearColor(), size: PiPeSize)
            
            let y = PipeObject.objectForKey("y") as! Int
            let x = PipeObject.objectForKey("x") as! Int
            print(x)
            print(y)
            
            
            somePipe.position = CGPoint(x: x + Int(PipeTileObjects.positionOffset.x) + Int(width)!/2, y: y + Int(PipeTileObjects.positionOffset.y) + Int(height)!/2)
            somePipe.physicsBody = SKPhysicsBody(rectangleOfSize: PiPeSize)
            somePipe.physicsBody?.affectedByGravity = false
            somePipe.physicsBody?.collisionBitMask = 0
            somePipe.physicsBody?.friction = 0.4
            somePipe.physicsBody?.restitution = 0.0
            //碰撞用
            somePipe.physicsBody?.categoryBitMask = PhysicsCatagory.Pipe
            somePipe.physicsBody?.contactTestBitMask = PhysicsCatagory.hero | PhysicsCatagory.Enemy1 | PhysicsCatagory.Enemy2 | PhysicsCatagory.Enemy3 | PhysicsCatagory.Enemy4
            
            self.Pipes.addChild(somePipe)
        }
        print(Pipes)
        self.addChild(self.Pipes)
        
        
        //forLayer3
        let ForEnemyLayerObjects: TMXObjectGroup = self.map.groupNamed("ForEnemyLayer3")
        for(var i = 0; i < ForEnemyLayerObjects.objects.count; i++) {
            let ForEnemyObject = ForEnemyLayerObjects.objects.objectAtIndex(i) as! NSDictionary
            
            let width = ForEnemyObject.objectForKey("width") as! String
            let height = ForEnemyObject.objectForKey("height") as! String
            let RectangleSize = CGSize(width: Int(width)!, height: Int(height)!)
            
            let someRectangle = SKSpriteNode(color: UIColor.clearColor(), size: RectangleSize)
            
            let y = ForEnemyObject.objectForKey("y") as! Int
            let x = ForEnemyObject.objectForKey("x") as! Int
            print(x)
            print(y)
            
            someRectangle.position = CGPoint(x: x + Int(ForEnemyLayerObjects.positionOffset.x) + Int(width)!/2, y: y + Int(ForEnemyLayerObjects.positionOffset.y) + Int(height)!/2)
            someRectangle.physicsBody = SKPhysicsBody(rectangleOfSize: RectangleSize)
            someRectangle.physicsBody?.affectedByGravity = false
            someRectangle.physicsBody?.collisionBitMask = 0
            someRectangle.physicsBody?.friction = 0.4
            someRectangle.physicsBody?.restitution = 0.0
            //碰撞用
            someRectangle.physicsBody?.categoryBitMask = PhysicsCatagory.Rectangle
            someRectangle.physicsBody?.contactTestBitMask = PhysicsCatagory.Enemy3
            self.Rectangles.addChild(someRectangle)
        }
        self.addChild(self.Rectangles)
        

            

//////////////////////////////////////////////////////////////////////

        // Setup Mario
        let startLocation = CGPoint(x: 400, y: 80)
        self.hero.position = startLocation
        initialPosition = hero.position

        self.hero.size = CGSize(width: 50, height: 50)
        died = false
        // Make 'im jumpy
        self.hero.physicsBody = SKPhysicsBody(circleOfRadius: self.hero.frame.size.width/2)
        
        self.hero.physicsBody?.friction = 0.2
        self.hero.physicsBody?.restitution = 0
        self.hero.physicsBody?.linearDamping = 0.0 //模擬阻力
        self.hero.physicsBody?.allowsRotation = false
        self.hero.physicsBody?.dynamic = true
        self.hero.physicsBody?.categoryBitMask = PhysicsCatagory.hero
        self.hero.physicsBody?.contactTestBitMask = PhysicsCatagory.Score | PhysicsCatagory.Finish | PhysicsCatagory.Enemy1 | PhysicsCatagory.Enemy2 | PhysicsCatagory.Enemy3 | PhysicsCatagory.Enemy4 

//        self.hero.physicsBody?.affectedByGravity = false
        
        //將hero定位
//        self.hero.anchorPoint=CGPointMake(0.5,0.5)

        // Animate running
        var heroRunning = [SKTexture]()
        for i in 0...2 {
            heroRunning.append( SKTexture(imageNamed: "flyman_\(i+4).png") )
        }
        let runningAction = SKAction.animateWithTextures(heroRunning, timePerFrame: 0.1)
        self.hero.runAction(SKAction.repeatActionForever(runningAction))
        
        self.addChild(hero)
        
        
        
        /////////////////////////////////////////////////////////
        
        let EnemyTileObjectsOne: TMXObjectGroup = self.map.groupNamed("EnemyLayer1")
        for(var i = 0; i < EnemyTileObjectsOne.objects.count; i++) {
            let EnemyObject = EnemyTileObjectsOne.objects.objectAtIndex(i) as! NSDictionary
            
            let width = EnemyObject.objectForKey("width") as! String
            let height = EnemyObject.objectForKey("height") as! String
            let EnemySize = CGSize(width: Int(width)! , height: Int(height)!)
            let someEnemy = SKSpriteNode(imageNamed: "enemy1_1.png")
            
            let y = EnemyObject.objectForKey("y") as! Int
            let x = EnemyObject.objectForKey("x") as! Int

            pos = CGPoint(x: x,y: y)
            
            someEnemy.position = CGPoint(x: x + Int(EnemyTileObjectsOne.positionOffset.x) + Int(width)!/2, y: y + Int(EnemyTileObjectsOne.positionOffset.y) + Int(height)!/2)
            print(someEnemy.position)
            someEnemy.physicsBody = SKPhysicsBody(circleOfRadius: someEnemy.frame.size.width/4)
            someEnemy.physicsBody?.affectedByGravity = false
            someEnemy.physicsBody?.collisionBitMask = 0
            someEnemy.physicsBody?.friction = 0.2
            someEnemy.physicsBody?.restitution = 0.0
            //碰撞用
            someEnemy.physicsBody?.categoryBitMask = PhysicsCatagory.Enemy1
            someEnemy.physicsBody?.contactTestBitMask = PhysicsCatagory.hero | PhysicsCatagory.Pipe
            self.EnemyOne.addChild(someEnemy)

            var enemyRunning = [SKTexture]()
            for i in 0...3 {
                enemyRunning.append( SKTexture(imageNamed: "enemy1_\(i+1).png") )
            }
            let EnemyRunningAction = SKAction.animateWithTextures(enemyRunning, timePerFrame: 0.2)
            someEnemy.runAction(SKAction.repeatActionForever(EnemyRunningAction))


        }

        
        self.addChild(self.EnemyOne)
////////////////////////////////////////////////////////////////////////
        let EnemyTileObjectsTwo: TMXObjectGroup = self.map.groupNamed("EnemyLayer2")
        for(var i = 0; i < EnemyTileObjectsTwo.objects.count; i++) {
            let EnemyObject = EnemyTileObjectsTwo.objects.objectAtIndex(i) as! NSDictionary
            
            let width = EnemyObject.objectForKey("width") as! String
            let height = EnemyObject.objectForKey("height") as! String
            let EnemySize = CGSize(width: Int(width)!, height: Int(height)!)
            let someEnemy = SKSpriteNode(imageNamed: "enemy1_1.png")

            
            let y = EnemyObject.objectForKey("y") as! Int
            let x = EnemyObject.objectForKey("x") as! Int
 
            pos = CGPoint(x: x,y: y)
            
            someEnemy.position = CGPoint(x: x + Int(EnemyTileObjectsTwo.positionOffset.x) + Int(width)!/2, y: y + Int(EnemyTileObjectsTwo.positionOffset.y) + Int(height)!/2)
            someEnemy.physicsBody = SKPhysicsBody(circleOfRadius: someEnemy.frame.size.width/4)
            someEnemy.physicsBody?.affectedByGravity = false
            someEnemy.physicsBody?.collisionBitMask = 0
            someEnemy.physicsBody?.friction = 0.2
            someEnemy.physicsBody?.restitution = 0.0
            //碰撞用
            someEnemy.physicsBody?.categoryBitMask = PhysicsCatagory.Enemy2
            someEnemy.physicsBody?.contactTestBitMask = PhysicsCatagory.hero | PhysicsCatagory.Pipe
            self.EnemyTwo.addChild(someEnemy)
            
            var enemyRunning = [SKTexture]()
            for i in 0...3 {
                enemyRunning.append( SKTexture(imageNamed: "enemy1_\(i+1).png") )
            }
            let EnemyRunningAction = SKAction.animateWithTextures(enemyRunning, timePerFrame: 0.2)
            someEnemy.runAction(SKAction.repeatActionForever(EnemyRunningAction))
        }

            self.addChild(self.EnemyTwo)
//////////////////////////////////////////////////////////////////////////
        let EnemyTileObjectsThree: TMXObjectGroup = self.map.groupNamed("EnemyLayer3")
        for(var i = 0; i < EnemyTileObjectsThree.objects.count; i++) {
            let EnemyObject = EnemyTileObjectsThree.objects.objectAtIndex(i) as! NSDictionary
            
            let width = EnemyObject.objectForKey("width") as! String
            let height = EnemyObject.objectForKey("height") as! String
            let EnemySize = CGSize(width: Int(width)!, height: Int(height)!)
            let someEnemy = SKSpriteNode(imageNamed: "enemy1_1.png")
            
            let y = EnemyObject.objectForKey("y") as! Int
            let x = EnemyObject.objectForKey("x") as! Int

            pos = CGPoint(x: x,y: y)
            
            someEnemy.position = CGPoint(x: x + Int(EnemyTileObjectsThree.positionOffset.x) + Int(width)!/2, y: y + Int(EnemyTileObjectsThree.positionOffset.y) + Int(height)!/2)
            someEnemy.physicsBody = SKPhysicsBody(circleOfRadius: someEnemy.frame.size.width/4)
            someEnemy.physicsBody?.affectedByGravity = false
            someEnemy.physicsBody?.collisionBitMask = 0
            someEnemy.physicsBody?.friction = 0.2
            someEnemy.physicsBody?.restitution = 0.0
            //碰撞用
            someEnemy.physicsBody?.categoryBitMask = PhysicsCatagory.Enemy3
            someEnemy.physicsBody?.contactTestBitMask = PhysicsCatagory.hero | PhysicsCatagory.Pipe | PhysicsCatagory.Rectangle
            self.EnemyThree.addChild(someEnemy)
            
            var enemyRunning = [SKTexture]()
            for i in 0...3 {
                enemyRunning.append( SKTexture(imageNamed: "enemy1_\(i+1).png") )
            }
            let EnemyRunningAction = SKAction.animateWithTextures(enemyRunning, timePerFrame: 0.2)
            someEnemy.runAction(SKAction.repeatActionForever(EnemyRunningAction))
        }
        self.addChild(self.EnemyThree)
        
//////////////////////////////////////////////////////////////////
        let EnemyTileObjectsFour: TMXObjectGroup = self.map.groupNamed("EnemyLayer4")
        for(var i = 0; i < EnemyTileObjectsFour.objects.count; i++) {
            let EnemyObject = EnemyTileObjectsFour.objects.objectAtIndex(i) as! NSDictionary
            
            let width = EnemyObject.objectForKey("width") as! String
            let height = EnemyObject.objectForKey("height") as! String
            let EnemySize = CGSize(width: Int(width)!, height: Int(height)!)
            let someEnemy = SKSpriteNode(imageNamed: "enemy1_1.png")
            
            let y = EnemyObject.objectForKey("y") as! Int
            let x = EnemyObject.objectForKey("x") as! Int

            pos = CGPoint(x: x,y: y)
            
            someEnemy.position = CGPoint(x: x + Int(EnemyTileObjectsFour.positionOffset.x) + Int(width)!/2, y: y + Int(EnemyTileObjectsFour.positionOffset.y) + Int(height)!/2)
            someEnemy.physicsBody = SKPhysicsBody(circleOfRadius: someEnemy.frame.size.width/4)
            someEnemy.physicsBody?.affectedByGravity = false
            someEnemy.physicsBody?.collisionBitMask = 0
            someEnemy.physicsBody?.friction = 0.2
            someEnemy.physicsBody?.restitution = 0.0
            //碰撞用
            someEnemy.physicsBody?.categoryBitMask = PhysicsCatagory.Enemy4
            someEnemy.physicsBody?.contactTestBitMask = PhysicsCatagory.hero | PhysicsCatagory.Pipe
            self.EnemyFour.addChild(someEnemy)
            
            var enemyRunning = [SKTexture]()
            for i in 0...3 {
                enemyRunning.append( SKTexture(imageNamed: "enemy1_\(i+1).png") )
            }
            let EnemyRunningAction = SKAction.animateWithTextures(enemyRunning, timePerFrame: 0.2)
            someEnemy.runAction(SKAction.repeatActionForever(EnemyRunningAction))
        }
        self.addChild(self.EnemyFour)
        

        

        let CoinTileObjects: TMXObjectGroup = self.map.groupNamed("CoinLayer")
        for(var i = 0; i < CoinTileObjects.objects.count; i++) {
            let CoinObject = CoinTileObjects.objects.objectAtIndex(i) as! NSDictionary
            
            let width = CoinObject.objectForKey("width") as! String
            let height = CoinObject.objectForKey("height") as! String
            let CoinSize = CGSize(width: Int(width)!, height: Int(height)!)
            
            let someCoin = SKSpriteNode(color: UIColor.clearColor(), size: CoinSize)
            
            let y = CoinObject.objectForKey("y") as! Int
            let x = CoinObject.objectForKey("x") as! Int

            
            
            someCoin.position = CGPoint(x: x + Int(CoinTileObjects.positionOffset.x) + Int(width)!/2, y: y + Int(CoinTileObjects.positionOffset.y) + Int(height)!/2)
            print(someCoin.position)
            someCoin.physicsBody = SKPhysicsBody(rectangleOfSize: CoinSize)
            someCoin.physicsBody?.affectedByGravity = false
            someCoin.physicsBody?.collisionBitMask = 0
            someCoin.physicsBody?.friction = 0.2  //光滑
            someCoin.physicsBody?.restitution = 0.0
            //碰撞用
            someCoin.physicsBody?.categoryBitMask = PhysicsCatagory.Score
            someCoin.physicsBody?.contactTestBitMask = PhysicsCatagory.hero

            self.Coins.addChild(someCoin)
        }
        print(Coins)
        self.addChild(self.Coins)
        
        //終點
        
        let FinishTileObjects: TMXObjectGroup = self.map.groupNamed("FinishLayer")
        for(var i = 0; i < FinishTileObjects.objects.count; i++) {
            let FinishObject = FinishTileObjects.objects.objectAtIndex(i) as! NSDictionary
            print(FinishObject)

            let width = FinishObject.objectForKey("width") as! String
            let height = FinishObject.objectForKey("height") as! String
            let finishLineSize = CGSize(width: Int(width)!, height: Int(height)!)
            
            let finishlineNode = SKSpriteNode(color: UIColor.clearColor(), size: finishLineSize)
            
            let y = FinishObject.objectForKey("y") as! Int
            let x = FinishObject.objectForKey("x") as! Int
            print(x)
            print(y)
            
            
            finishlineNode.position = CGPoint(x: x + Int(FinishTileObjects.positionOffset.x) + Int(width)!/2, y: y + Int(FinishTileObjects.positionOffset.y) + Int(height)!/2)
            print(finishlineNode.position)
            finishlineNode.physicsBody = SKPhysicsBody(rectangleOfSize: finishLineSize)
            finishlineNode.physicsBody?.affectedByGravity = false
            finishlineNode.physicsBody?.collisionBitMask = 0
            finishlineNode.physicsBody?.friction = 0.2
            finishlineNode.physicsBody?.restitution = 0.0
            //碰撞用
            finishlineNode.physicsBody?.categoryBitMask = PhysicsCatagory.Finish
            finishlineNode.physicsBody?.contactTestBitMask = PhysicsCatagory.hero
            
            self.Coins.addChild(finishlineNode)
        }

    
    }
    
    
    override func didMoveToView(view: SKView) {

        super.didMoveToView(view)
        myCamera = SKCameraNode()
        
        self.camera = myCamera  // Maybe you missed this?
        addChild(myCamera)
        myCamera.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "score:\(score)"
        myLabel.fontSize = 45
        myLabel.position = CGPointMake(0, 150)
        myLabel.fontColor = UIColor.blackColor()
        myLabel.zPosition = 100
        self.camera!.addChild(myLabel)
        print("my Label:\(myLabel.position)")
        
        self.camera!.addChild(button)
        button.position = CGPointMake(-250, 150)
        button.size = CGSize(width: 50, height: 50)
        button.zPosition = 100
        
        let joystick2 = Joystick2(position: CGPoint(x: 50, y: 50))
        joystick2.position = CGPoint(x: -self.size.width / 2 + 75, y: -self.size.height / 2)
        print("joystick:\(joystick2.position)")
   
        
        joystick2.zPosition = 3.0
        self.myCamera.addChild(joystick2)
        
        self.joystick2 = joystick2

        guard let newURL = villageUrl else {
            print("Could not find file")
            return
        }
        do {
            villagePlayer = try AVAudioPlayer(contentsOfURL: newURL)
            villagePlayer.volume = 0.5
            villagePlayer.prepareToPlay()
            villagePlayer.play()
            
        } catch let error as NSError {
            print(error.description)
        }


    }
    
    func marioJump() {
        self.hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 30), atPoint: CGPoint(x: self.hero.frame.width/2, y: 0))
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
        
        if let joystick = self.joystick2 {
            
            joystick.touchesBegan(touches, withEvent: event)
            
        }
            var speed2: CGFloat = 3.0
            if let joystick2 = joystick2 {
                if joystick2.pressedButtons.count == 2 {
                    speed2 = speed2 / sqrt(2.0)
                }
                if joystick2.buttonUp.pressed {

                    if onGround == true{
                        self.hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 60), atPoint: CGPoint(x: self.hero.frame.width/2, y: 0))
                        guard let newURL = jumpUrl else {
                            print("Could not find file")
                            return
                        }
                        do {
                            jumpPlayer = try AVAudioPlayer(contentsOfURL: newURL)
                            jumpPlayer.volume = 0.5
                            jumpPlayer.prepareToPlay()
                            jumpPlayer.play()
                            
                        } catch let error as NSError {
                            print(error.description)
                        }
                        onGround = false
                    }

                }
            }

    }
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//觸碰
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
        if button.containsPoint(location){
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
            
        }
        }
        if let joystick = self.joystick2 {
            joystick.touchesEnded(touches, withEvent: event)
            
        }
    }
//觸碰

    
    func didBeginContact(contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody  = contact.bodyA
        let secondBody: SKPhysicsBody = contact.bodyB

//觸碰

        if firstBody.categoryBitMask == PhysicsCatagory.Score && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Score{

            score += 200
            print(score)
            self.groundScoreLbl.text = "score: \(score)"
            self.myLabel.text = "score: \(score)"

            guard let newURL = coinUrl else {
                print("Could not find file")
                return
            }
            do {
                coinPlayer = try AVAudioPlayer(contentsOfURL: newURL)
                coinPlayer.volume = 0.5
                coinPlayer.prepareToPlay()
                coinPlayer.play()
                
            } catch let error as NSError {
                print(error.description)
            }
            
            //錢幣消失
            let layer : TMXLayer = map.layerNamed("Coin")
            let node = layer.tileAt((firstBody.node?.position)!)
            node.removeFromParent()
            firstBody.node?.removeFromParent() //coin 消失
        }
        
        
        //碰到終點
        if firstBody.categoryBitMask == PhysicsCatagory.Finish && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Finish{

            
            gameOver(true)

        }
        //碰到敵人
        if firstBody.categoryBitMask == PhysicsCatagory.Enemy1 && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Enemy1{
            //        if (firstBody.node == self.Coins && secondBody.node == self.hero) || (firstBody.node == self.hero && secondBody.node == self.Coins){
            died = true

            gameOver(false)
            

        }
        if firstBody.categoryBitMask == PhysicsCatagory.Enemy2 && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Enemy2{

            died = true

            gameOver(false)
            

        }
        
        if firstBody.categoryBitMask == PhysicsCatagory.Enemy3 && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Enemy3{

            died = true
            
            gameOver(false)
            

        }
        
        if firstBody.categoryBitMask == PhysicsCatagory.Enemy4 && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Enemy4{

            died = true
            
            gameOver(false)
            

        }
        
        
        //碰到終點
        if firstBody.categoryBitMask == PhysicsCatagory.Finish && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Finish{
            
            gameOver(true)

        }
        //敵人碰到水管回程
        if firstBody.categoryBitMask == PhysicsCatagory.Pipe && secondBody.categoryBitMask == PhysicsCatagory.Enemy1 || firstBody.categoryBitMask == PhysicsCatagory.Enemy1 && secondBody.categoryBitMask == PhysicsCatagory.Pipe{
            //        if (firstBody.node == self.Coins && secondBody.node == self.hero) || (firstBody.node == self.hero && secondBody.node == self.Coins){
            
//            let x = -1
            reverse1 = -reverse1
            

        }
        if firstBody.categoryBitMask == PhysicsCatagory.Pipe && secondBody.categoryBitMask == PhysicsCatagory.Enemy2 || firstBody.categoryBitMask == PhysicsCatagory.Enemy2 && secondBody.categoryBitMask == PhysicsCatagory.Pipe{

            reverse2 = -reverse2

            

        }
        if firstBody.categoryBitMask == PhysicsCatagory.Pipe && secondBody.categoryBitMask == PhysicsCatagory.Enemy3 || firstBody.categoryBitMask == PhysicsCatagory.Enemy3 && secondBody.categoryBitMask == PhysicsCatagory.Pipe{

            reverse3 = -reverse3
            
            print("my bump\(firstBody.node?.position)")
            print("my bump\(firstBody.node?.position)")
            

        }
        
        if firstBody.categoryBitMask == PhysicsCatagory.Rectangle && secondBody.categoryBitMask == PhysicsCatagory.Enemy3 || firstBody.categoryBitMask == PhysicsCatagory.Enemy3 && secondBody.categoryBitMask == PhysicsCatagory.Rectangle{

            reverse3 = -reverse3
            

        }
        
        
        if firstBody.categoryBitMask == PhysicsCatagory.Pipe && secondBody.categoryBitMask == PhysicsCatagory.Enemy4 || firstBody.categoryBitMask == PhysicsCatagory.Enemy4 && secondBody.categoryBitMask == PhysicsCatagory.Pipe{

            reverse4 = -reverse4

            
        }
        
        
    }
    
    func goToGameScene() {
        let gameScene = GroundGameScene(size: self.view!.bounds.size) // create your new scene
        let transition = SKTransition.fadeWithDuration(5) // create type of transition (you can check in documentation for more transtions)
        gameScene.scaleMode = SKSceneScaleMode.Fill
        self.view!.presentScene(gameScene, transition: transition)
    }
    

    func gameOver(won:Bool){
        print("in")
        if won {

            villagePlayer.stop()
            print("You won,game over")// to do
            
            hero.removeAllActions()
            EnemyOne.removeAllActions()
            EnemyTwo.removeAllActions()
            EnemyThree.removeAllActions()
            EnemyFour.removeAllActions()
            joystick2?.removeFromParent()
            
            winLabel.position = CGPoint(x: self.frame.width / 2 , y: self.frame.height / 2)
            winLabel = SKLabelNode(fontNamed:"Chalkduster")
            winLabel.text = "You win,Congratulations"

            winLabel.zPosition = 200
            winLabel.fontSize = 40
            
            self.myCamera.addChild(winLabel)
            
            guard let newURL = finishUrl else {
                print("Could not find file")
                return
            }
            do {
                finishPlayer = try AVAudioPlayer(contentsOfURL: newURL)
                finishPlayer.volume = 0.5
                finishPlayer.prepareToPlay()
                finishPlayer.play()
                
            } catch let error as NSError {
                print(error.description)
            }
            

        }
        else{
            villagePlayer.stop()

            print("You lose,game over")// to do
//            hero.removeFromParent()   //人消失
//            self.map.position.x = 0   //遊戲重新使用
            hero.removeAllActions()
            EnemyOne.removeAllActions()
            EnemyTwo.removeAllActions()
            EnemyThree.removeAllActions()
            EnemyFour.removeAllActions()

            joystick2?.removeFromParent()
//
            loseLabel.position = CGPoint(x: self.frame.width / 2 , y: self.frame.height / 2)
            loseLabel = SKLabelNode(fontNamed:"Chalkduster")
            loseLabel.text = "You lose,game over"
            loseLabel.zPosition = 200
            loseLabel.fontSize = 40

            self.myCamera.addChild(loseLabel)
            
            guard let newURL = diedUrl else {
                print("Could not find file")
                return
            }
            do {
                diedPlayer = try AVAudioPlayer(contentsOfURL: newURL)
                diedPlayer.volume = 0.5
                diedPlayer.prepareToPlay()
                diedPlayer.play()
                
            } catch let error as NSError {
                print(error.description)
            }
            

            goToGameScene()
            
        }
        return

    }
    override func update(currentTime: CFTimeInterval) {

        for children in [EnemyOne]{
            children.position.x += reverse1
        }
        for children in [EnemyTwo]{
            children.position.x += reverse2
        }
        for children in [EnemyThree]{
            children.position.x += reverse3
        }
        for children in [EnemyFour]{
            children.position.x += reverse4
        }
        
        

        //掉到洞死亡
        if self.hero.position.y < self.frame.origin.y{
            print("you lose")
            hero.hidden = true
            gameOver(false)
            goToGameScene()
        }

        myCamera.position.x = hero.position.x
//        myCamera.position.y = hero.position.y

        if self.hero.physicsBody?.velocity.dy == 0{
            onGround = true
        }
        var speed2: CGFloat = 5.0
        if let joystick2 = joystick2 {

        if joystick2.buttonLeft.pressed {
            
            //判斷一開始不能倒退
            speed2 = self.map.position.x + speed2 > 0 ? 0 : speed2
            self.obstacles.position.x += speed2
            self.Pipes.position.x += speed2
            self.Rectangles.position.x += speed2
            
            self.EnemyOne.position.x += speed2
            self.EnemyTwo.position.x += speed2
            self.EnemyThree.position.x += speed2
            self.EnemyFour.position.x += speed2
            self.Coins.position.x += speed2
            
            
            self.map.position.x += speed2
            }
        if joystick2.buttonRight.pressed {
            
            let s = (self.map.position.x - speed2 - self.frame.width) * -1.0
            let w = self.map.mapSize.width * self.map.tileSize.width
            speed2 = s > w ? 0 : speed2
            
            self.Rectangles.position.x -= speed2
            self.obstacles.position.x -= speed2
            self.Pipes.position.x -= speed2

            self.EnemyOne.position.x -= speed2
            self.EnemyTwo.position.x -= speed2
            self.EnemyThree.position.x -= speed2
            self.EnemyFour.position.x -= speed2

            self.Coins.position.x -= speed2
            
            self.map.position.x -= speed2
            
            }
            
        }

    }

    
}
