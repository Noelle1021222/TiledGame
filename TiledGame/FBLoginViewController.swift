//
//  FBLoginViewController.swift
//  TiledGame
//
//  Created by 許雅筑 on 2016/11/4.
//  Copyright © 2016年 hsu.ya.chu. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import FirebaseAuth
class FBLoginViewController: UIViewController,FBSDKLoginButtonDelegate{

    
    var userName: String = ""
    var userEmail: String = ""
    var userLink: String = ""
    var userID: String = ""
    var userPictureURL: String = ""
    var userDefault = NSUserDefaults.standardUserDefaults()
    var fireBaseHighScore = Int()
    var user = FIRAuth.auth()?.currentUser
//    var delegate:ScoreDataEnteredDelegate? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageView = UIImageView(frame: self.view.bounds)
        imageView.image = UIImage(named: "gameBackground")//if its in images.xcassets
        self.view.addSubview(imageView)

        let loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile","email","user_friends",]
        loginButton.delegate = self
        loginButton.hidden = false
        view.addSubview(loginButton)
        loginButton.frame = CGRect(x: 16, y: 250, width: view.frame.width - 32, height: 50)
        
        let dyLabel: UILabel = UILabel(frame: CGRectMake(0,0,200,70))
        
        dyLabel.backgroundColor = UIColor(red: 239/255, green: 80/255, blue: 62/255, alpha: 1)
        
        dyLabel.layer.masksToBounds = true
        dyLabel.font = UIFont(name:"Chalkduster", size: 30)
        
        // 遮罩功能開啟後指定圓角大小
        dyLabel.layer.cornerRadius = 5.0
        dyLabel.text = "Tile Game"
        dyLabel.shadowColor = UIColor.blackColor()
        dyLabel.textColor = UIColor(red: 255/255, green: 239/255, blue: 214/255, alpha: 1)
        // 文字對齊方式為：中央對齊
        dyLabel.textAlignment = NSTextAlignment.Center
        dyLabel.layer.position = CGPoint(x: self.view.bounds.width/2,y: 150)
        self.view.backgroundColor = UIColor.blackColor()
        dyLabel.layer.borderColor = UIColor.blackColor().CGColor
        dyLabel.layer.borderWidth = 3
        self.view.addSubview(dyLabel)

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        if (error != nil)
        {
            print(error.localizedDescription)
           return
        }
        else if result.isCancelled {

        }
        showEmaillAddress()

    
    }
            
    func showEmaillAddress(){
        let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
        FIRAuth.auth()?.signInWithCredential(credential, completion: { (user,error) in
            if error != nil{
                print(error!.localizedDescription)
                return
            }
            
            print(user ?? "")
            
            
        })
        
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, email"])
        graphRequest.startWithCompletionHandler{ (connection, result, error) -> Void in
            if ((error) != nil)
            {
                
                print("Error: \(error)")
            }
            print(result)
        
        }
        
        let protectedPage = self.storyboard?.instantiateViewControllerWithIdentifier("GroundGameViewController") as! GroundGameViewController
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.rootViewController = protectedPage
        
        
    }


    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!){

        print("Did log out of facebook")
    }


}
