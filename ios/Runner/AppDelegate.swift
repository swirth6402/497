import UIKit
import Flutter
import FirebaseCore
import flutter_local_notifications
import UserNotifications


@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()  // Initialize Firebase
        GeneratedPluginRegistrant.register(with: self)
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        UNUserNotificationCenter.current().delegate = self
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
    }
}
