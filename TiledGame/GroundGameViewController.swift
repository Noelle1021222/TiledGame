//
//  GameViewController.swift
//  TiledGame
//
//  Created by 許雅筑 on 2016/10/16.
//  Copyright (c) 2016年 hsu.ya.chu. All rights reserved.
//

import UIKit
import SpriteKit
//extension SKNode {
//    class func unarchiveFromFile(file : NSString) -> SKNode? {
//        
//        let path = NSBundle.mainBundle().pathForResource(file as String, ofType: "sks")
//        
//        let sceneData = NSData.dataWithContentsOfMappedFile(path!) as! NSData
//        //        var sceneData = NSData.dataWithContentsOfFile(path, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
//        
//        let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
//        
//        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
//        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GroundGameScene
//        archiver.finishDecoding()
//        return scene
//    }
//}

//usage: if let scene = GameScene.unarchiveFromFile("Level1Scene") as? GameScene {


@available(iOS 9.0, *)
class GroundGameViewController: UIViewController {
    
    override func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews();
        
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        
        skView.ignoresSiblingOrder = true
        
        let scene = GroundGameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        skView.presentScene(scene)
        
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    


    
    
    
}
