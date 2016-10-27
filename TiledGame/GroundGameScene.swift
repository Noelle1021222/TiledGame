//
//  GameScene.swift
//  TiledGame
//
//  Created by 許雅筑 on 2016/10/16.
//  Copyright (c) 2016年 hsu.ya.chu. All rights reserved.
//
import SpriteKit

enum MoveDirection: Int {
    case None, Forward, Backward
}

struct PhysicsCatagory{ //交互影響，重力影響
    
    static let hero:UInt32 = 0x1 << 1
    
    static let Score:UInt32 = 0x1 << 5
    static let enemy:UInt32 = 0x1 << 6
    static let Heart:UInt32 = 0x1 << 8
    
    
}
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


class GroundGameScene: SKScene, UIGestureRecognizerDelegate, SKSceneDelegate, SKPhysicsContactDelegate {
    var joystick: Joystick!
//////////
    var joystick2:Joystick2?
//////////
    let map = JSTileMap(named: "level.tmx");
    var hero = SKSpriteNode(imageNamed: "flyman_6.png");
    var obstacles = SKNode();
    var swipeJumpGesture: UISwipeGestureRecognizer = UISwipeGestureRecognizer();
    static let jumpForce = CGPoint(x:0.0, y:400)
    static let jumpCutoff : CGFloat = 150.0
    var move: MoveDirection = .None;
    var isJumping: Bool = false;
    private var player = SKSpriteNode(imageNamed: "flyman_6.png")
    var score = Int()

    private var enemy = SKSpriteNode(imageNamed: "enemy1_1.png")
    private var myNode = SKSpriteNode(imageNamed: "enemy1_1.png")
    private var floorObjects : NSArray = []
    var Enemys = SKNode()
    var Coins = SKNode()
    var pos:CGPoint?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.commonShitInit();
        
    }
    
    override init(size: CGSize) {
        super.init(size: size);
        self.commonShitInit();
    }
    
    func commonShitInit () -> () {
        joystick = Joystick()
        joystick.zPosition = 3.0
        joystick.position = CGPointMake(joystick.backdropNode.size.width / 2, joystick.backdropNode.size.height / 2)
        joystick.shouldFadeOut = true
        self.addChild(joystick)
        
        // Setting Scene
        self.backgroundColor = UIColor(red: 104.0 / 255.0, green: 136.0 / 255.0, blue: 255.0 / 255.0, alpha: 1.0);
        self.addChild(self.map);
        
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: self.frame.origin.x, y: self.frame.origin.y - 36.0, width: self.frame.size.width, height: self.frame.size.height));
        self.physicsBody?.friction = 0.0;
        self.physicsWorld.contactDelegate = self;
        //        self.physicsBody.collisionBitMask = 0;
        //        self.physicsBody.contactTestBitMask = 0;
        //        self.physicsWorld.gravity = CGVectorMake(0,0);
        //        self.physicsWorld.contactDelegate = self;
        
        
        // Setting obstacles
        let collisionsGroup: TMXObjectGroup = self.map.groupNamed("Collisions");
        for(var i = 0; i < collisionsGroup.objects.count; i++) {
            let collisionObject = collisionsGroup.objects.objectAtIndex(i) as! NSDictionary;
            
            print(collisionObject);
            
            let width = collisionObject.objectForKey("width") as! String;
            let height = collisionObject.objectForKey("height") as! String;
            let someObstacleSize = CGSize(width: Int(width)!, height: Int(height)!);
            print(someObstacleSize)
            let someObstacle = SKSpriteNode(color: UIColor.clearColor(), size: someObstacleSize);
            
            let y = collisionObject.objectForKey("y") as! Int;
            let x = collisionObject.objectForKey("x") as! Int;
            
            someObstacle.position = CGPoint(x: x + Int(collisionsGroup.positionOffset.x) + Int(width)!/2, y: y + Int(collisionsGroup.positionOffset.y) + Int(height)!/2);
            someObstacle.physicsBody = SKPhysicsBody(rectangleOfSize: someObstacleSize);
            someObstacle.physicsBody?.affectedByGravity = false;
            someObstacle.physicsBody?.collisionBitMask = 0;
            someObstacle.physicsBody?.friction = 0.2;
            someObstacle.physicsBody?.restitution = 0.0;
            
            self.obstacles.addChild(someObstacle)
        }
        print(obstacles)
        self.addChild(self.obstacles)
        
        // Setup Mario
        let startLocation = CGPoint(x: 64, y: 80);
        
        self.hero.position = startLocation;
        self.hero.size = CGSize(width: 50, height: 50);
        
        // Make 'im jumpy
        self.hero.physicsBody = SKPhysicsBody(circleOfRadius: self.hero.frame.size.width/2);
        self.hero.physicsBody?.friction = 0.2;
        self.hero.physicsBody?.restitution = 0;
        self.hero.physicsBody?.linearDamping = 0.0;
        self.hero.physicsBody?.allowsRotation = false;
        self.hero.physicsBody?.dynamic = true;
        self.hero.physicsBody?.categoryBitMask = PhysicsCatagory.hero
        self.hero.physicsBody?.contactTestBitMask = PhysicsCatagory.Score

        
        // Animate running
        var marioSmall_running = [SKTexture]();
        for i in 0...2 {
            marioSmall_running.append( SKTexture(imageNamed: "flyman_\(i+4).png") );
        }
        let runningAction = SKAction.animateWithTextures(marioSmall_running, timePerFrame: 0.1);
        self.hero.runAction(SKAction.repeatActionForever(runningAction))
        
        self.addChild(self.hero)
        
        
        
        
        /////////////////////////////////////////////////////////
        //加入出生點player
        let playerTileObjects: TMXObjectGroup = self.map.groupNamed("PlayerObjects")
////        let spawnPoint=playerTileObjects.objectNamed("SpawnPoint") //获取spawnPoint
//        let spawnPoint=playerTileObjects.objectNamed("SpawnPoint") //获取spawnPoint
//
//        let x = spawnPoint["x"] as! CGFloat //获取spawnPoint的x,y坐标
//        let y = spawnPoint["y"] as! CGFloat
////        player.anchorPoint=CGPointMake(0.5,0.0)
//        player.position=CGPointMake(x,y)
//        self.addChild(player)
//        
//        //////////////////////////////////////////////////////////
//        
        //        let spawnPoint=playerTileObjects.objectNamed("SpawnPoint") //获取spawnPoint
        let spawnEnemyPoint = playerTileObjects.objectNamed("enemySpawn") //获取spawnPoint
        
        let ax = spawnEnemyPoint["x"] as! CGFloat //获取spawnPoint的x,y坐标
        let ay = spawnEnemyPoint["y"] as! CGFloat
        enemy.anchorPoint=CGPointMake(0.5,0.0)
        enemy.position=CGPointMake(ax,ay)
        self.addChild(enemy)
        
//        let EnemyTileObjects: TMXObjectGroup = self.map.groupNamed("ObjectLayer")
//
//        floorObjects = EnemyTileObjects.objectsNamed("enemy")
//        print(floorObjects)
//        for floorObj in floorObjects{
////            let x = floorObj["x"] as! CGFloat
////            let y = floorObj["y"] as! CGFloat
//////            let width = floorObj.width
//////            let height :  = floorObj.height
////            myNode.position = CGPointMake(x, y)
////            self.addChild(myNode)
//        }
        
        let EnemyTileObjects: TMXObjectGroup = self.map.groupNamed("ObjectLayer");
        for(var i = 0; i < EnemyTileObjects.objects.count; i++) {
            let EnemyObject = EnemyTileObjects.objects.objectAtIndex(i) as! NSDictionary;
            
                        print(EnemyObject)
            
            let width = EnemyObject.objectForKey("width") as! String;
            let height = EnemyObject.objectForKey("height") as! String;
            let EnemySize = CGSize(width: Int(width)!+10, height: Int(height)!+10);
            
            let someEnemy = SKSpriteNode(imageNamed: "enemy1_1.png")
            
            let y = EnemyObject.objectForKey("y") as! Int;
            let x = EnemyObject.objectForKey("x") as! Int;
            print(x)
            print(y)
            pos = CGPoint(x: x,y: y)
        
            someEnemy.position = CGPoint(x: x + Int(EnemyTileObjects.positionOffset.x) + Int(width)!/2, y: y + Int(EnemyTileObjects.positionOffset.y) + Int(height)!/2);
            print(someEnemy.position)
            someEnemy.physicsBody = SKPhysicsBody(rectangleOfSize: EnemySize);
            someEnemy.physicsBody?.affectedByGravity = false
            someEnemy.physicsBody?.collisionBitMask = 0
            someEnemy.physicsBody?.friction = 0.2
            someEnemy.physicsBody?.restitution = 0.0
            
            self.Enemys.addChild(someEnemy)
        }
        print(Enemys)
        self.addChild(self.Enemys)
////////////////////////////////////////////////////////////////////////

//        let enemyTileObjects: TMXObjectGroup = self.map.groupNamed("EnemyObjects")
////        let enemySpawn = playerTileObjects.objectNamed("enemySpawn") //获取spawnPoint
//
//        let enemySpawn = enemyTileObjects.objectNamed("EnemySpawn") //获取spawnPoint
//         let ax = enemySpawn["x"] as! CGFloat //获取spawnPoint的x,y坐标
//         let ay = enemySpawn["y"] as! CGFloat
//        enemy.anchorPoint = CGPointMake(0.5,0.0)
//        enemy.position = CGPointMake(ax,ay)
//        self.addChild(enemy)
        
        //        var swipeJumpGesture: UISwipeGestureRecognizer = UISwipeGestureRecognizer();
        //        self.swipeJumpGesture.addTarget(self, action: Selector("handleJumpSwipe:"));
        //        self.swipeJumpGesture.direction = .Up;
        //        self.swipeJumpGesture.numberOfTouchesRequired = 1;
        //        if let shit = self.view {
        //            shit.addGestureRecognizer(self.swipeJumpGesture);
        //        }
        
        //        self.view.addGestureRecognizer(swipeJumpGesture);
        //        if let shit = self.view {
        //            shit.addGestureRecognizer(swipeJumpGesture);
        //        }
        let CoinTileObjects: TMXObjectGroup = self.map.groupNamed("CoinLayer")
        for(var i = 0; i < CoinTileObjects.objects.count; i++) {
            let CoinObject = CoinTileObjects.objects.objectAtIndex(i) as! NSDictionary;
            
            print(CoinObject)
            
            let width = CoinObject.objectForKey("width") as! String;
            let height = CoinObject.objectForKey("height") as! String;
            let CoinSize = CGSize(width: Int(width)!+10, height: Int(height)!+10);
            
            let someCoin = SKSpriteNode(color: UIColor.clearColor(), size: CoinSize);
            
            let y = CoinObject.objectForKey("y") as! Int
            let x = CoinObject.objectForKey("x") as! Int
            print(x)
            print(y)
            
            
            someCoin.position = CGPoint(x: x + Int(CoinTileObjects.positionOffset.x) + Int(width)!/2, y: y + Int(CoinTileObjects.positionOffset.y) + Int(height)!/2);
            print(someCoin.position)
            someCoin.physicsBody = SKPhysicsBody(rectangleOfSize: CoinSize);
            someCoin.physicsBody?.affectedByGravity = false
            someCoin.physicsBody?.collisionBitMask = 0
            someCoin.physicsBody?.friction = 0.2
            someCoin.physicsBody?.restitution = 0.0
            //碰撞用
            someCoin.physicsBody?.categoryBitMask = PhysicsCatagory.Score
            someCoin.physicsBody?.contactTestBitMask = PhysicsCatagory.hero

            self.Coins.addChild(someCoin)
        }
        print(Coins)
        self.addChild(self.Coins)
    }
    
    ////coin

    
    
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view);
        
        self.swipeJumpGesture.addTarget(self, action: Selector("handleJumpSwipe:"));
        self.swipeJumpGesture.direction = .Up;
        self.swipeJumpGesture.numberOfTouchesRequired = 1;
        self.view?.addGestureRecognizer(self.swipeJumpGesture);
        
     /////////////
        let joystick2 = Joystick2(position: CGPoint(x: 250, y: 50))
        self.addChild(joystick2)
        self.joystick2 = joystick2

        //////////////////
    }
    
    func handleJumpSwipe(sender: UIGestureRecognizer) {
        if !self.isJumping {
            self.marioJump();
            self.isJumping = true;
        }
        else if sender.state == UIGestureRecognizerState.Ended {
            self.move = .None;
            self.isJumping = false;
        }
    }
    
    func marioJump() {
        self.hero.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 50), atPoint: CGPoint(x: self.hero.frame.width/2, y: 0));
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            
            var touchMe: UITouch = touch as! UITouch;
            
            //            if find(touchMe.gestureRecognizers, self.swipeJumpGesture) { continue; }
            
            //            if event.touchesForGestureRecognizer(self.swipeJumpGesture).count > 0 {
            //                continue;
            //            }
            //            if touch as UIGestureRecognizer == self.swipeJumpGesture {
            //                continue;
            //            }
            
            let location = touch.locationInNode(self);
            if location.x > self.hero.position.x {
                self.move = .Forward;
            }
            else {
                self.move = .Backward;
            }
        }
        
        ////
        
        if let joystick = self.joystick2 {
            
            joystick.touchesBegan(touches, withEvent: event)
        }
        /////
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.move = .None;
        /////
        if let joystick = self.joystick2 {
            
            joystick.touchesEnded(touches, withEvent: event)
            
        }
        //////
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        self.move = .None;
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        let firstBody: SKPhysicsBody  = contact.bodyA;
        let secondBody: SKPhysicsBody = contact.bodyB;
        
        if(self.isJumping == true && (firstBody.node == self.hero || secondBody.node == self.hero)) {
            self.isJumping = false;
            self.move = .None;
        }
        if firstBody.categoryBitMask == PhysicsCatagory.Score && secondBody.categoryBitMask == PhysicsCatagory.hero || firstBody.categoryBitMask == PhysicsCatagory.hero && secondBody.categoryBitMask == PhysicsCatagory.Score{
//        if (firstBody.node == self.Coins && secondBody.node == self.hero) || (firstBody.node == self.hero && secondBody.node == self.Coins){
            score += 1
            print(score)
//            scoreLbl.text = ": \(score)"
            
//            guard let newURL = coinUrl else {
//                print("Could not find file")
//                return
//            }
//            do {
//                coinPlayer = try AVAudioPlayer(contentsOfURL: newURL)
//                coinPlayer.volume = 0.5
//                coinPlayer.prepareToPlay()
//                coinPlayer.play()
//                
//            } catch let error as NSError {
//                print(error.description)
//            }
            
            //錢幣消失
            let layer : TMXLayer = map.layerNamed("Coin")
            let node = layer.tileAt((firstBody.node?.position)!)
            node.removeFromParent()
            firstBody.node?.removeFromParent() //coin 消失
        }
        
        
    }
//    func removeTile(pos : CGPoint) {
//        let layer : TMXLayer = map.layerNamed("Coin")
//        let node = layer.tileAt(firstBody.node?.position)
//        node.removeFromParent()
//    }
    
    
    override func update(currentTime: CFTimeInterval) {
/////////////  joystick 搖桿
        if joystick.velocity.x != 0 || joystick.velocity.y != 0 {
            hero.position = CGPointMake(hero.position.x + 0.15 * joystick.velocity.x, hero.position.y + 0.15 * joystick.velocity.y)
        }
    
//////
        var speed2: CGFloat = 3.0

        if let joystick2 = joystick2 {
            
            if joystick2.pressedButtons.count == 2 {
                
                speed2 = speed2 / sqrt(2.0)
            }
            
            if joystick2.buttonUp.pressed {
                marioJump()

            //                hero.position.y += speed2
                
            }
            
            if joystick2.buttonDown.pressed {
                
                hero.position.y -= speed2
            }
            if joystick2.buttonLeft.pressed {
                
                hero.position.x -= speed2
            }
            if joystick2.buttonRight.pressed {
                
                hero.position.x += speed2
            }
        }
        
//////
        //搖桿的
        var speed: CGFloat = 5;
        
        if self.move == .Forward {
            let s = (self.map.position.x - speed - self.frame.width) * -1.0
            let w = self.map.mapSize.width * self.map.tileSize.width
            speed = s > w ? 0 : speed;
            
            self.obstacles.position.x -= speed
            self.Enemys.position.x -= speed
            self.Coins.position.x -= speed

            self.enemy.position.x -= speed

            self.map.position.x -= speed
            //            self.physicsWorld.gravity = CGVector(-2,-9.8);
            //            self.hero.physicsBody.applyForce(CGVector(5,0), atPoint: CGPoint(x: 0, y: self.hero.frame.size.height/2))
        }
        else if self.move == .Backward {
            speed = self.map.position.x + speed > 0 ? 0 : speed;
            
            self.obstacles.position.x += speed
            self.Enemys.position.x += speed
            self.enemy.position.x += speed
            self.Coins.position.x -= speed

            self.map.position.x += speed
            //            self.physicsWorld.gravity = CGVector(2,-9.8);
            //            self.hero.physicsBody.applyForce(CGVector(-5,0), atPoint: CGPoint(x: self.hero.frame.size.width, y: self.hero.frame.size.height/2))
        }
        //        else {
        //            self.physicsWorld.gravity = CGVector(0.0,-9.8);
        //        }
        
        
        //        self.map.position.x = -self.hero.position.x  // - self.frame.size.width / 2 + self.hero.frame.width / 2;
        //        self.obstacles.position.x = -self.hero.position.x*0.5
    }
}