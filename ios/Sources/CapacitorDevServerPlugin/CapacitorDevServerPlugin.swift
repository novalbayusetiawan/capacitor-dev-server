import Capacitor
import Foundation
import UIKit

/// Please read the Capacitor iOS Plugin Development Guide
/// here: https://capacitorjs.com/docs/plugins/ios
@objc(CapacitorDevServerPlugin)
public class CapacitorDevServerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorDevServerPlugin"
    public let jsName = "CapacitorDevServer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "applyServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "enableDevMode", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disableDevMode", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isDevModeEnabled", returnType: CAPPluginReturnPromise),
    ]
    private let implementation = CapacitorDevServer()
    private let defaults = UserDefaults.standard

    @objc func setServer(_ call: CAPPluginCall) {
        let autoRestart = call.getBool("autoRestart") ?? true
        
        if let url = call.getString("url") {
            defaults.set(url, forKey: "server_url")
        }

        var result: [String: Any] = [:]
        if let url = defaults.string(forKey: "server_url") { result["url"] = url }

        notifyListeners("serverChanged", data: result)

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
        var result: [String: Any] = [:]
        result["url"] = defaults.string(forKey: "server_url") ?? ""
        call.resolve(result)
    }

    @objc func clearServer(_ call: CAPPluginCall) {
        let autoRestart = call.getBool("autoRestart") ?? true
        
        defaults.removeObject(forKey: "server_url")
        defaults.removeObject(forKey: "dev_enabled")

        let result: [String: Any] = ["cleared": true]
        notifyListeners("serverChanged", data: result)
        
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
        var result: [String: Any] = [:]
        result["url"] = defaults.string(forKey: "server_url") ?? ""

        notifyListeners("serverApply", data: result)
        call.resolve(result)
    }

    @objc func enableDevMode(_ call: CAPPluginCall) {
        defaults.set(true, forKey: "dev_enabled")
        call.resolve(["enabled": true])
    }

    @objc func disableDevMode(_ call: CAPPluginCall) {
        defaults.set(false, forKey: "dev_enabled")
        call.resolve(["enabled": false])
    }

    @objc func isDevModeEnabled(_ call: CAPPluginCall) {
        let enabled = defaults.bool(forKey: "dev_enabled")
        call.resolve(["enabled": enabled])
    }
}
