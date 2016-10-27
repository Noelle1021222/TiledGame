//
//  ControllerButton.swift
//  Battle Tanks
//
//  Created by Nicholas Looney on 11/19/15.
//  Copyright © 2015 Nicholas Looney. All rights reserved.
//

import SpriteKit

class ControllerButton: SKSpriteNode {
	
    var hitbox: (CGPoint -> Bool)?
	var pressed = false
	
	convenience init(imageNamed: String) {
		
		let texture = SKTexture(imageNamed: imageNamed)
		self.init(texture: texture, color: UIColor.clearColor(), size: texture.size())
//		super.init(imageNamed: imageNamed)
		self.texture?.filteringMode = .Nearest
		self.setScale(2.0)
		self.alpha = 0.2
		
		hitbox = { (location: CGPoint) -> Bool in
			return self.containsPoint(location)
		}
	}

	
    func hitboxContainsPoint(location: CGPoint) -> Bool {
        return hitbox!(location)
    }
}
