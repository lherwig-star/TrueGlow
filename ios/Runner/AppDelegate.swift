import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Pflichtschritt aus der Anleitung von flutter_local_notifications
    // ("iOS setup / General setup"). Ohne diese Zuweisung blendet iOS eine
    // faellige Erinnerung nicht ein, solange die App im Vordergrund steht -
    // die Tageserinnerung verhielte sich auf dem iPhone anders als auf
    // Android, ohne dass ein Bau oder ein Test das meldet (DECISIONS 100).
    //
    // `as?` und nicht `as`: Sollte FlutterAppDelegate das Protokoll in einer
    // kuenftigen Flutter-Fassung nicht mehr erfuellen, bleibt die Zuweisung
    // wirkungslos statt beim Start abzustuerzen.
    UNUserNotificationCenter.current().delegate =
      self as? UNUserNotificationCenterDelegate

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Der zweite Schritt der Anleitung - FlutterLocalNotificationsPlugin
  // .setPluginRegistrantCallback - fehlt hier bewusst. Er wird nur fuer den
  // Hintergrund-Isolate von Benachrichtigungs-Aktionen gebraucht, und die App
  // hat keine: Sie plant Erinnerungen, wertet aber weder Schaltflaechen darin
  // noch das Antippen aus (kein onDidReceiveNotificationResponse im Code).
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
