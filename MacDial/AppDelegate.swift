
import Cocoa
import ServiceManagement
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusBarController: StatusBarController?
    let dial = Dial()
    var dialSettings: DialSettings?

    func requestPermissions() {
        if !AXIsProcessTrusted() {
            let alert = NSAlert()
            alert.messageText = "App permissions"
            alert.alertStyle = NSAlert.Style.informational
            alert.informativeText = "Mac Dial needs Accessibility permissions to work. In the next dialog you will be asked to open the Settings app to enable the permissions.\nIMPORTANT! Due to an issue in macOS, if you're upgrading from an earlier version of Mac Dial you might have to remove Mac Dial from the accessibility permissions and then restart the app to re-add the permissions."
            alert.runModal()
        }

        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        AXIsProcessTrustedWithOptions(options)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        requestPermissions()
        dial.start()
        let settings = DialSettings(dial: dial)
        dialSettings = settings
        let sbc = StatusBarController(dial, settings: settings)
        statusBarController = sbc
        appSwitcher = AppSwitcher(statusBarController: sbc)
    }

    var appSwitcher: AppSwitcher?

    func applicationWillTerminate(_ aNotification: Notification) {
        dial.stop()
    }
}
