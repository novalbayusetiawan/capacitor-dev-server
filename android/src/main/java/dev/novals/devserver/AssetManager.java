package dev.novals.devserver;

import android.content.Context;
import com.getcapacitor.Logger;
import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class AssetManager {

    private static final String ASSET_DIR_NAME = "capacitor_dev_server_assets";
    private final Context context;

    public AssetManager(Context context) {
        this.context = context;
    }

    public File getAssetsDir() {
        File dir = new File(context.getFilesDir(), ASSET_DIR_NAME);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        return dir;
    }

    public void downloadAndExtract(String urlString, boolean overwrite) throws Exception {
        URL url = new URL(urlString);
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.connect();

        if (connection.getResponseCode() != HttpURLConnection.HTTP_OK) {
            throw new Exception("Server returned HTTP " + connection.getResponseCode() + " " + connection.getResponseMessage());
        }

        File tempZip = new File(context.getCacheDir(), "update.zip");
        try (InputStream input = new BufferedInputStream(connection.getInputStream());
             FileOutputStream output = new FileOutputStream(tempZip)) {

            byte[] data = new byte[4096];
            int count;
            while ((count = input.read(data)) != -1) {
                output.write(data, 0, count);
            }
        }

        File assetsDir = getAssetsDir();
        String assetName = getAssetNameFromUrl(urlString);
        File targetDir = new File(assetsDir, assetName);

        if (targetDir.exists()) {
            if (overwrite) {
                deleteRecursive(targetDir);
            } else {
                // If not overwriting and exists, maybe we just return? 
                // Or maybe we treat it as already downloaded. 
                // For now let's assume we proceed to extract if overwrite is technically "update"
                // But user requested: "overwrite: boolean // if true, it will overwrite the existing asset or just keep one version of the asset beside the default asset"
                // If overwrite is false, we should probably append a version or just fail if exists?
                // Simpler for now: if exists and !overwrite, we just return (cached).
                // Actually, let's extract to a temp folder first then move? 
                // Let's stick to simple: if exists & !overwrite, return.
                return;
            }
        }
        
        targetDir.mkdirs();
        unzip(tempZip, targetDir);
        tempZip.delete();
    }

    private String getAssetNameFromUrl(String url) {
        // Simple hash or name from last segment
        // Ideally we might want a manifest, but for now simple:
        // url: http://host.com/ver1.zip -> assetName: ver1
        String filename = url.substring(url.lastIndexOf('/') + 1);
        if (filename.endsWith(".zip")) {
            return filename.substring(0, filename.length() - 4);
        }
        return filename.replaceAll("[^a-zA-Z0-9.-]", "_");
    }

    private void unzip(File zipFile, File targetDir) throws IOException {
        try (ZipInputStream zis = new ZipInputStream(new BufferedInputStream(new java.io.FileInputStream(zipFile)))) {
            ZipEntry ze;
            while ((ze = zis.getNextEntry()) != null) {
                File file = new File(targetDir, ze.getName());
                File dir = ze.isDirectory() ? file : file.getParentFile();
                
                if (!dir.isDirectory() && !dir.mkdirs())
                    throw new IOException("Failed to create directory " + dir);
                    
                if (ze.isDirectory())
                    continue;

                try (FileOutputStream fos = new FileOutputStream(file)) {
                    byte[] buffer = new byte[4096];
                    int count;
                    while ((count = zis.read(buffer)) != -1) {
                        fos.write(buffer, 0, count);
                    }
                }
            }
        }
    }

    public List<String> getAssetList() {
        List<String> list = new ArrayList<>();
        File[] files = getAssetsDir().listFiles();
        if (files != null) {
            for (File f : files) {
                if (f.isDirectory()) {
                    list.add(f.getName());
                }
            }
        }
        return list;
    }

    public void removeAsset(String assetName) {
        File targetDir = new File(getAssetsDir(), assetName);
        if (targetDir.exists()) {
            deleteRecursive(targetDir);
        }
    }

    private void deleteRecursive(File fileOrDirectory) {
        if (fileOrDirectory.isDirectory()) {
            for (File child : fileOrDirectory.listFiles()) {
                deleteRecursive(child);
            }
        }
        fileOrDirectory.delete();
    }

    public String getAssetPath(String assetName) {
        File targetDir = new File(getAssetsDir(), assetName);
        if (targetDir.exists()) {
            return targetDir.getAbsolutePath();
        }
        return null;
    }
}
