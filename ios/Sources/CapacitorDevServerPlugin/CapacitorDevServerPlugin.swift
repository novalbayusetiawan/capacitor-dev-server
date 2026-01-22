import Capacitor
import Foundation

/// Please read the Capacitor iOS Plugin Development Guide
/// here: https://capacitorjs.com/docs/plugins/ios
@objc(CapacitorDevServerPlugin)
public class CapacitorDevServerPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "CapacitorDevServerPlugin"
    public let jsName = "CapacitorDevServer"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "echo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "applyServer", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setServerUrl", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getServerUrl", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setCleartext", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getCleartext", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setAndroidScheme", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getAndroidScheme", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "enableDevMode", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "disableDevMode", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isDevModeEnabled", returnType: CAPPluginReturnPromise),
    ]
    private let implementation = CapacitorDevServer()
    private let defaults = UserDefaults.standard

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.resolve([
            "value": implementation.echo(value)
        ])
    }

    // Store multiple server-related options at once (url, cleartext, scheme)
    // Any provided field will be persisted.
    @objc func setServer(_ call: CAPPluginCall) {
        if let url = call.getString("url") {
            defaults.set(url, forKey: "server_url")
        }
        if let cleartext = call.getBool("cleartext") {
            defaults.set(cleartext, forKey: "server_cleartext")
        }
        if let scheme = call.getString("scheme") {
            defaults.set(scheme, forKey: "server_scheme")
        }

        var result: [String: Any] = [:]
        if let url = defaults.string(forKey: "server_url") { result["url"] = url }
        result["cleartext"] = defaults.bool(forKey: "server_cleartext")
        if let scheme = defaults.string(forKey: "server_scheme") { result["scheme"] = scheme }

        // Notify the web layer or app that server settings changed
        notifyListeners("serverChanged", data: result)

        call.resolve(result)
    }

    @objc func getServer(_ call: CAPPluginCall) {
        var result: [String: Any] = [:]
        result["url"] = defaults.string(forKey: "server_url") ?? ""
        result["cleartext"] = defaults.bool(forKey: "server_cleartext")
        result["scheme"] = defaults.string(forKey: "server_scheme") ?? ""
        call.resolve(result)
    }

    @objc func clearServer(_ call: CAPPluginCall) {
        defaults.removeObject(forKey: "server_url")
        defaults.removeObject(forKey: "server_cleartext")
        defaults.removeObject(forKey: "server_scheme")
        defaults.removeObject(forKey: "dev_enabled")

        let result: [String: Any] = ["cleared": true]
        notifyListeners("serverChanged", data: result)
        call.resolve(result)
    }

    // Signal that the saved server should be applied now. The app/web layer is expected to handle reloading.
    @objc func applyServer(_ call: CAPPluginCall) {
        var result: [String: Any] = [:]
        result["url"] = defaults.string(forKey: "server_url") ?? ""
        result["cleartext"] = defaults.bool(forKey: "server_cleartext")
        result["scheme"] = defaults.string(forKey: "server_scheme") ?? ""

        notifyListeners("serverApply", data: result)
        call.resolve(result)
    }

    // Convenience single-field setters/getters
    @objc func setServerUrl(_ call: CAPPluginCall) {
        guard let url = call.getString("url") else {
            call.reject("Must provide a url")
            return
        }
        defaults.set(url, forKey: "server_url")
        let result: [String: Any] = ["url": url]
        call.resolve(result)
    }

    @objc func getServerUrl(_ call: CAPPluginCall) {
        let url = defaults.string(forKey: "server_url") ?? ""
        call.resolve(["url": url])
    }

    @objc func setCleartext(_ call: CAPPluginCall) {
        guard let allow = call.getBool("allow") else {
            call.reject("Must provide allow boolean")
            return
        }
        defaults.set(allow, forKey: "server_cleartext")
        call.resolve(["cleartext": allow])
    }

    @objc func getCleartext(_ call: CAPPluginCall) {
        let allow = defaults.bool(forKey: "server_cleartext")
        call.resolve(["cleartext": allow])
    }

    // Keep naming aligned with Android API even though this is iOS; stores a generic scheme value.
    @objc func setAndroidScheme(_ call: CAPPluginCall) {
        guard let scheme = call.getString("scheme") else {
            call.reject("Must provide scheme")
            return
        }
        defaults.set(scheme, forKey: "server_scheme")
        call.resolve(["scheme": scheme])
    }

    @objc func getAndroidScheme(_ call: CAPPluginCall) {
        let scheme = defaults.string(forKey: "server_scheme") ?? ""
        call.resolve(["scheme": scheme])
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
