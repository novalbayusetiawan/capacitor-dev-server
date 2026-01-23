import Capacitor
import Foundation
import UIKit

/// Please read the Capacitor iOS Plugin Development Guide
/// here: https://capacitorjs.com/docs/plugins/ios
@objc(DevServerPlugin)
public class DevServerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "DevServerPlugin"
    public let jsName = "DevServer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "applyServer", returnType: CAPPluginReturnPromise),
    ]
    private let implementation = DevServer()
    private let defaults = UserDefaults.standard

    @objc func setServer(_ call: CAPPluginCall) {
        let autoRestart = call.getBool("autoRestart") ?? true
        let persist = call.getBool("persist") ?? false
        
        if let url = call.getString("url") {
            if persist {
                defaults.set(url, forKey: "server_url")
                DevServer.sessionUrl = nil
            } else {
                DevServer.sessionUrl = url
                defaults.removeObject(forKey: "server_url")
            }
        }

        var result: [String: Any] = [:]
        result["url"] = DevServer.sessionUrl ?? defaults.string(forKey: "server_url")
        result["persist"] = persist

        if autoRestart {
            DispatchQueue.main.async {
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateInitialViewController() {
                        window.rootViewController = vc
                    } else {
                        self.bridge?.reload()
                    }
                } else {
                    self.bridge?.reload()
                }
            }
        }

        call.resolve(result)
    }

    @objc func getServer(_ call: CAPPluginCall) {
        let savedUrl = defaults.string(forKey: "server_url")
        var result: [String: Any] = [:]
        result["url"] = DevServer.sessionUrl ?? savedUrl ?? ""
        result["persist"] = DevServer.sessionUrl == nil && savedUrl != nil
        call.resolve(result)
    }

    @objc func clearServer(_ call: CAPPluginCall) {
        let autoRestart = call.getBool("autoRestart") ?? true
        
        DevServer.sessionUrl = nil
        defaults.removeObject(forKey: "server_url")

        let result: [String: Any] = ["cleared": true]
        
        if autoRestart {
            DispatchQueue.main.async {
                if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateInitialViewController() {
                        window.rootViewController = vc
                    } else {
                        self.bridge?.reload()
                    }
                } else {
                    self.bridge?.reload()
                }
            }
        }
        
        call.resolve(result)
    }

    @objc func applyServer(_ call: CAPPluginCall) {
        getServer(call)
    }
}
