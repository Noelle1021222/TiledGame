//
//  Joystick.swift
//  Battle Tanks
//
//  Created by Tudor on 13/12/2015.
//  Copyright © 2015 Nicholas Looney. All rights reserved.
//

import Foundation
import SpriteKit

enum Direction: String {

	case Left = "left"
	case Right = "right"
	case Down = "down"
	case Up = "up"
}

class Joystick2: SKNode {

	let buttonDown = ControllerButton(imageNamed: "button_dir_down_0")
	let buttonLeft = ControllerButton(imageNamed: "button_dir_left_0")
	let buttonRight = ControllerButton(imageNamed: "button_dir_right_0")
	let buttonUp = ControllerButton(imageNamed: "button_dir_up_0")
	var buttonPressed: (() -> Void)?
	var pressedButtons = [ControllerButton]()
	
	
	// MARK: Lifecycle
	
	init(position: CGPoint) {
		
		super.init()
		self.position = position
		setupChildren()
	}

	required init?(coder aDecoder: NSCoder) {
		
	    fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: Public
	
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		for touch: AnyObject in touches {
			
			let location = touch.locationInNode(self)
			for button in [buttonLeft, buttonRight, buttonUp, buttonDown] {
				
				if button.hitboxContainsPoint(location) && pressedButtons.indexOf(button) == nil {
					
					button.pressed = true
					pressedButtons.append(button)
					if let pressed = self.buttonPressed {
						
						pressed()
					}
				}
			}
		}

		updateHighlightedButtons()
	}
	
	override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		for touch: AnyObject in touches {
			
			let location = touch.locationInNode(self)
			let previousLocation = touch.previousLocationInNode(self)
			for button in [buttonLeft, buttonRight, buttonUp, buttonDown] {
				
				if button.hitboxContainsPoint(previousLocation) && !button.hitboxContainsPoint(location) {
					
					button.pressed = false
					let index = pressedButtons.indexOf(button)
					if index != nil {
						
						pressedButtons.removeAtIndex(index!)
					}
				} else if !button.hitboxContainsPoint(previousLocation) && button.hitboxContainsPoint(location) {
					
					// If you move from one button to another without lifting
					button.pressed = true
					pressedButtons.append(button)
					if let pressed = self.buttonPressed {
						
						pressed()
					}
				}
			}
		}
		updateHighlightedButtons()
	}
	
	override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		
		for button in pressedButtons {
			
			button.pressed = false
		}
		pressedButtons.removeAll()
		updateHighlightedButtons()
	}
	
	// MARK: Private
	
	private func setupChildren() {
		
		let distance:CGFloat = 60
		let x:CGFloat = self.position.x
		let y:CGFloat = self.position.y
		let l = 94.0 as CGFloat
		let angle = CGFloat(tan(M_PI / 3))
		
		buttonLeft.position = CGPoint(x: self.position.x - distance, y: self.position.y)
		buttonLeft.name = Direction.Left.rawValue
		buttonLeft.hitbox = { (location: CGPoint) -> Bool in
			
			let is_left_of_x = location.x - x < 0
			let is_within_angle = (abs(location.x - x) * angle >= abs(location.y - y))
			let is_within_radius = (location.x - x) ** 2 + (location.y - y) ** 2 <= l ** 2
			return is_left_of_x && is_within_angle && is_within_radius
		}
		self.addChild(buttonLeft)
		
		buttonRight.position = CGPoint(x: self.position.x + distance, y: self.position.y)
		buttonRight.name = Direction.Right.rawValue
		buttonRight.hitbox = { (location: CGPoint) -> Bool in
			
			let is_right_of_x = location.x - x > 0
			let is_within_angle = (abs(location.x - x) * angle >= abs(location.y - y))
			let is_within_radius = (location.x - x) ** 2 + (location.y - y) ** 2 <= l ** 2
			return is_right_of_x && is_within_angle && is_within_radius
            
            
		}
		self.addChild(buttonRight)
		
//		buttonDown.position = CGPoint(x: self.position.x, y: self.position.y - distance)
//		buttonDown.name = Direction.Down.rawValue
//		buttonDown.hitbox = { (location: CGPoint) -> Bool in
//			
//			let is_below_of_y = location.y - y < 0
//			let is_within_angle = (abs(location.x - x) <= abs(location.y - y) * angle)
//			let is_within_radius = (location.x - x) ** 2 + (location.y - y) ** 2 <= l ** 2
//			return is_below_of_y && is_within_angle && is_within_radius
//		}
//		self.addChild(buttonDown)
		
		buttonUp.position = CGPoint(x: self.position.x, y: self.position.y + distance)
		buttonUp.name = Direction.Up.rawValue
		buttonUp.hitbox = { (location: CGPoint) -> Bool in
			
			let is_above_y1 = location.y - y > 0
			let is_within_angle = (abs(location.x - x) <= abs(location.y - y) * angle)
			let is_within_radius = (location.x - x) ** 2 + (location.y - y) ** 2 <= l ** 2
			return is_above_y1 && is_within_angle && is_within_radius
		}
		self.addChild(buttonUp)
	}
	
	private func updateHighlightedButtons() {
		
		for button in [buttonLeft, buttonRight, buttonUp, buttonDown] {
			
			if pressedButtons.contains(button) {
				
				button.alpha = 0.8
			} else {
				
				button.alpha = 0.2
			}
		}
	}
}