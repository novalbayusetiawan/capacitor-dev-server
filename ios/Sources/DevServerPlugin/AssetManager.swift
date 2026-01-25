import Foundation
import SSZipArchive

class AssetManager {
    static let shared = AssetManager()
    private let fileManager = FileManager.default
    private let ASSET_DIR_NAME = "capacitor_dev_server_assets"

    private init() {}

    func getAssetsDir() -> URL? {
        guard let libraryDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = libraryDir.appendingPathComponent(ASSET_DIR_NAME)
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating assets dir: \(error)")
                return nil
            }
        }
        return dir
    }

    func downloadAndExtract(url: String, overwrite: Bool, completion: @escaping (Error?) -> Void) {
        guard let downloadUrl = URL(string: url) else {
            completion(NSError(domain: "DevServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        let task = URLSession.shared.downloadTask(with: downloadUrl) { localUrl, response, error in
            if let error = error {
                completion(error)
                return
            }

            guard let localUrl = localUrl, let assetsDir = self.getAssetsDir() else {
                completion(NSError(domain: "DevServer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Download failed"]))
                return
            }

            let assetName = self.getAssetNameFromUrl(url: url)
            let targetDir = assetsDir.appendingPathComponent(assetName)

            if self.fileManager.fileExists(atPath: targetDir.path) {
                if overwrite {
                    try? self.fileManager.removeItem(at: targetDir)
                } else {
                    completion(nil)
                    return
                }
            }

            // Unzip
            // SSZipArchive doesn't unzip directly from temp file sometimes, better safe
            let tempZip = assetsDir.appendingPathComponent("temp_update.zip")
            try? self.fileManager.removeItem(at: tempZip)
            
            do {
                try self.fileManager.moveItem(at: localUrl, to: tempZip)
                
                // Create target dir
                try self.fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)

                let success = SSZipArchive.unzipFile(atPath: tempZip.path, toDestination: targetDir.path)
                try? self.fileManager.removeItem(at: tempZip)
                
                if success {
                    completion(nil)
                } else {
                    completion(NSError(domain: "DevServer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unzip failed"]))
                }
            } catch {
                completion(error)
            }
        }
        task.resume()
    }

    func getAssetNameFromUrl(url: String) -> String {
        guard let u = URL(string: url) else { return "unknown" }
        let filename = u.lastPathComponent
        if filename.hasSuffix(".zip") {
            return String(filename.dropLast(4))
        }
        return filename
    }

    func getAssetList() -> [String] {
        guard let dir = getAssetsDir() else { return [] }
        do {
            let files = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            return files.filter { $0.hasDirectoryPath }.map { $0.lastPathComponent }
        } catch {
            return []
        }
    }
    
    func removeAsset(assetName: String) {
        guard let dir = getAssetsDir() else { return }
        let target = dir.appendingPathComponent(assetName)
        try? fileManager.removeItem(at: target)
    }

    func getAssetPath(assetName: String) -> String? {
        guard let dir = getAssetsDir() else { return nil }
        let target = dir.appendingPathComponent(assetName)
        if fileManager.fileExists(atPath: target.path) {
            return target.path
        }
        return nil
    }
}
