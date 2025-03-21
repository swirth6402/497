import UIKit
import Flutter
import FirebaseCore
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FlutterLocalNotificationsPlufin.setPluinRegistrantCallback {(registry) in 
        GeneratedPluginRegistrant.register(with: registry)}

        FirebaseApp.configure()  // Initialize Firebase
        GeneratedPluginRegistrant.register(with: self)

        if available(iOS 10.0, *){
            UNUserNotificationsCenter.current().delegate = self as? UNUserNotificationsCenter
        }






        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
