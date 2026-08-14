import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        DeviceRegistration.store(token: token)
        Task { await DeviceRegistration.registerIfAvailable(quietStart: 22, quietEnd: 8) }
    }
}
