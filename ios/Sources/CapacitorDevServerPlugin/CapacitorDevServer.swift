import Foundation

@objc public class CapacitorDevServer: NSObject {
    @objc public static func capacitorOptions() -> [String: Any] {
        var options: [String: Any] = [:]
        if let url = UserDefaults.standard.string(forKey: "server_url") {
            options["server"] = [
                "url": url,
                "cleartext": UserDefaults.standard.bool(forKey: "server_cleartext"),
                "androidScheme": UserDefaults.standard.string(forKey: "server_scheme") ?? "https"
            ]
        }
        return options
    }
}
