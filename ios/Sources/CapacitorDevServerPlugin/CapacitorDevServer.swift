import Foundation

@objc public class CapacitorDevServer: NSObject {
    @objc public static func capacitorOptions() -> [String: Any] {
        var options: [String: Any] = [:]
        if let url = UserDefaults.standard.string(forKey: "server_url") {
            // Infer cleartext and scheme
            let isHttp = url.lowercased().hasPrefix("http://")
            
            options["server"] = [
                "url": url,
                "cleartext": isHttp,
                "androidScheme": isHttp ? "http" : "https"
            ]
        }
        return options
    }
}
