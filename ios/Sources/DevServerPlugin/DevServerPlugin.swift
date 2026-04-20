import Capacitor
import Foundation
import UIKit
import GCDWebServer

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
        // Asset Management
        CAPPluginMethod(name: "downloadAsset", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getAssetList", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "applyAsset", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeAsset", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "restoreDefaultAsset", returnType: CAPPluginReturnPromise),
        // Automated Updates
        CAPPluginMethod(name: "checkForUpdate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "sync", returnType: CAPPluginReturnPromise),
    ]
    private let implementation = DevServer()
    private let defaults = UserDefaults.standard
    private let assetManager = AssetManager.shared
    private var webServer: GCDWebServer?
    private let LOCAL_PORT: UInt = 8080

    override public func load() {
        // Check for persisted asset
        if let assetName = defaults.string(forKey: "active_asset"),
           let assetPath = assetManager.getAssetPath(assetName: assetName) {
            
            // Smart Web Root Detection (reuse logic)
            let rootUrl = URL(fileURLWithPath: assetPath)
            let webRootPath = findWebRoot(dir: rootUrl)?.path ?? assetPath
            
            do {
                _ = try startLocalServer(webRootDir: webRootPath)
            } catch {
                print("DevServer: Failed to restore local server: \(error)")
            }
        }
    }

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
            // Clear active asset if manual server set
            defaults.removeObject(forKey: "active_asset")
        }

        var result: [String: Any] = [:]
        result["url"] = DevServer.sessionUrl ?? defaults.string(forKey: "server_url")
        result["persist"] = persist

        if autoRestart {
            DispatchQueue.main.async {
                self.reloadApp()
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
        defaults.removeObject(forKey: "active_asset")
        
        stopLocalServer()

        let result: [String: Any] = ["cleared": true]
        
        if autoRestart {
            DispatchQueue.main.async {
                self.reloadApp()
            }
        }
        
        call.resolve(result)
    }

    @objc func applyServer(_ call: CAPPluginCall) {
        getServer(call)
    }
    
    // MARK: - Asset Management
    
    @objc func downloadAsset(_ call: CAPPluginCall) {
        guard let url = call.getString("url") else {
            call.reject("URL is required")
            return 
        }
        let overwrite = call.getBool("overwrite") ?? false
        let checksum = call.getString("checksum")
        
        assetManager.downloadAndExtract(url: url, overwrite: overwrite, checksum: checksum) { error in
            if let error = error {
                call.reject("Download failed: \(error.localizedDescription)")
            } else {
                call.resolve()
            }
        }
    }
    
    @objc func getAssetList(_ call: CAPPluginCall) {
        let assets = assetManager.getAssetList()
        call.resolve(["assets": assets])
    }
    
    @objc func removeAsset(_ call: CAPPluginCall) {
        guard let assetName = call.getString("assetName") else {
            call.reject("Asset Name is required")
            return
        }
        assetManager.removeAsset(assetName: assetName)
        call.resolve()
    }
    
    @objc func applyAsset(_ call: CAPPluginCall) {
        guard let assetName = call.getString("assetName") else {
            call.reject("Asset Name is required")
            return
        }
        let persist = call.getBool("persist") ?? false
        
        self.applyBundleInternal(assetName: assetName, persist: persist, call: call)
    }

    private func applyBundleInternal(assetName: String, persist: Bool, call: CAPPluginCall?) {
        guard let assetPath = assetManager.getAssetPath(assetName: assetName) else {
            call?.reject("Asset not found")
            return
        }
        
        stopLocalServer()
        
        // Smart Web Root Detection
        let rootUrl = URL(fileURLWithPath: assetPath)
        let webRootPath = findWebRoot(dir: rootUrl)?.path ?? assetPath
        
        var actualPort = LOCAL_PORT
        do {
            actualPort = try startLocalServer(webRootDir: webRootPath)
        } catch {
             call?.reject("Failed to start local server: \(error.localizedDescription)")
             return
        }
        
        let localUrl = "http://localhost:\(actualPort)"
        
        if persist {
            defaults.set(localUrl, forKey: "server_url")
            defaults.set(assetName, forKey: "active_asset")
            DevServer.sessionUrl = nil
        } else {
            DevServer.sessionUrl = localUrl
            defaults.removeObject(forKey: "server_url")
            defaults.removeObject(forKey: "active_asset")
        }
        
        DispatchQueue.main.async {
            self.reloadApp()
        }
        
        call?.resolve()
    }
    
    // MARK: - Automated Updates

    @objc func checkForUpdate(_ call: CAPPluginCall) {
        performUpdateCheck(call: call) { data in
            call.resolve(data)
        }
    }

    @objc func sync(_ call: CAPPluginCall) {
        performUpdateCheck(call: call) { data in
            let isUpdateAvailable = data["isUpdateAvailable"] as? Bool ?? false
            guard isUpdateAvailable, let downloadUrl = data["downloadUrl"] as? String else {
                call.resolve(["updated": false])
                return
            }

            // Start Download
            self.assetManager.downloadAndExtract(url: downloadUrl, overwrite: true, checksum: nil) { error in
                if let error = error {
                    call.reject("Sync failed at download: \(error.localizedDescription)")
                    return
                }

                // Apply new asset
                if let latestBundle = data["latestBundle"] as? [String: Any],
                   let assetId = latestBundle["id"] {
                    self.applyBundleInternal(assetName: String(describing: assetId), persist: true, call: call)
                } else {
                    call.resolve(["updated": true, "note": "downloaded but could not auto-apply id mapping"])
                }
            }
        }
    }

    private func performUpdateCheck(call: CAPPluginCall, completion: @escaping ([String: Any]) -> Void) {
        guard let urlString = call.getString("url") else {
            call.reject("URL is required")
            return
        }
        let channel = call.getString("channel") ?? "production"
        
        guard let url = URL(string: urlString) else {
            call.reject("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Metadata Headers
        request.addValue(UIDevice.current.identifierForVendor?.uuidString ?? "unknown", forHTTPHeaderField: "X-Device-Identifier")
        request.addValue("ios", forHTTPHeaderField: "X-Platform")
        request.addValue(defaults.string(forKey: "active_asset") ?? "", forHTTPHeaderField: "X-Bundle-Id")
        request.addValue(channel, forHTTPHeaderField: "X-Channel")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                call.reject("Update check failed: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                call.reject("No data received from update server")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var result: [String: Any] = [:]
                    result["isUpdateAvailable"] = json["is_update_available"] ?? false
                    result["latestBundle"] = json["latest_bundle"]
                    result["currentBundle"] = json["current_bundle"]
                    result["downloadUrl"] = json["download_url"]
                    completion(result)
                } else {
                    call.reject("Invalid JSON response from update server")
                }
            } catch {
                call.reject("JSON parsing error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }

    // Recursive search for index.html
    private func findWebRoot(dir: URL) -> URL? {
        let fileManager = FileManager.default
        let indexUrl = dir.appendingPathComponent("index.html")
        if fileManager.fileExists(atPath: indexUrl.path) {
            return dir
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
            for url in contents {
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                    if let found = findWebRoot(dir: url) {
                        return found
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
    
    @objc func restoreDefaultAsset(_ call: CAPPluginCall) {
        stopLocalServer()
        DevServer.sessionUrl = nil
        defaults.removeObject(forKey: "server_url")
        defaults.removeObject(forKey: "active_asset")
        
        DispatchQueue.main.async {
            self.reloadApp()
        }
        call.resolve()
    }
    
    private func startLocalServer(webRootDir: String) throws -> UInt {
        // Stop any existing server
        if let server = webServer, server.isRunning {
             server.stop()
             webServer = nil
             // Brief pause to allow socket release (crucial for iOS sometimes)
             Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Re-init server
        webServer = GCDWebServer()
        webServer?.addGETHandler(forBasePath: "/", directoryPath: webRootDir, indexFilename: "index.html", cacheAge: 0, allowRangeRequests: true)
        
        // Strict single port
        let port = LOCAL_PORT
        
        do {
            try webServer?.start(options: [
                GCDWebServerOption_Port: port,
                GCDWebServerOption_BindToLocalhost: true
            ])
            return port
        } catch {
             // If failed, make one last desperate attempt after a slightly longer pause
             Thread.sleep(forTimeInterval: 0.2)
             try webServer?.start(options: [
                GCDWebServerOption_Port: port,
                GCDWebServerOption_BindToLocalhost: true
             ])
             return port
        }
    }

    private func stopLocalServer() {
        if let server = webServer, server.isRunning {
             server.stop()
        }
        webServer = nil
    }
    
    private func reloadApp() {
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let vc = storyboard.instantiateInitialViewController() {
                window.rootViewController = vc
            } else {
                self.webView?.reload()
            }
        } else {
            self.webView?.reload()
        }
    }
}
