//
//  AppDelegate.swift
//  Pods
//
//  Created by Nguyen Truc on 1/9/23.
//

import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
  internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    FirebaseApp.configure()
    
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {success, _ in guard success else {return}
      print("Success in APNS Registry")
    }
    
    application.registerForRemoteNotifications()
    
    return true
  }
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    messaging.token {token, _ in
      guard let token = token else {
        return
      }
      
      print("Token: \(token)")
    }
  }
}
