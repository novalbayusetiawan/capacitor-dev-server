import Foundation

@objc public class DevServer: NSObject {
    @objc public static var sessionUrl: String? = nil

    @objc public static func capacitorOptions() -> [String: Any] {
        var options: [String: Any] = [:]
        let savedUrl = UserDefaults.standard.string(forKey: "server_url")
        if let url = sessionUrl ?? savedUrl {
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
