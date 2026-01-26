import Foundation
import SSZipArchive
import CommonCrypto

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

    func downloadAndExtract(url: String, overwrite: Bool, checksum: String?, completion: @escaping (Error?) -> Void) {
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
            
            // Checksum Verification
            if let checksum = checksum, !checksum.isEmpty {
                if let calculatedHash = self.sha256(url: localUrl) {
                    if calculatedHash.caseInsensitiveCompare(checksum) != .orderedSame {
                        completion(NSError(domain: "DevServer", code: 4, userInfo: [NSLocalizedDescriptionKey: "Checksum mismatch! Expected: \(checksum), Calculated: \(calculatedHash)"]))
                        return
                    }
                } else {
                     completion(NSError(domain: "DevServer", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate checksum"]))
                     return
                }
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
    
    // SHA-256 Helper
    private func sha256(url: URL) -> String? {
        do {
            let bufferSize = 1024 * 1024
            let file = try FileHandle(forReadingFrom: url)
            defer { file.closeFile() }
            
            var context = CC_SHA256_CTX()
            CC_SHA256_Init(&context)
            
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                        _ = CC_SHA256_Update(&context, bytes.baseAddress, CC_LONG(data.count))
                    }
                    return true
                } else {
                    return false
                }
            }) { }
            
            var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes { (bytes: UnsafeMutableRawBufferPointer) in
                _ = CC_SHA256_Final(bytes.bindMemory(to: UInt8.self).baseAddress, &context)
            }
            
            return digest.map { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
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
