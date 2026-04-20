package dev.novals.devserver;

import android.content.Context;
import android.content.SharedPreferences;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import java.io.File;
import java.io.IOException;
import java.util.List;

@CapacitorPlugin(name = "DevServer")
public class DevServerPlugin extends Plugin {

    private static final String PREFS_NAME = "capacitor_dev_server_prefs";
    private AssetManager assetManager;
    private static LocalServer localServer;
    private static final int LOCAL_PORT = 8080; // Could be dynamic

    @Override
    public void load() {
        super.load();
        assetManager = new AssetManager(getContext());
        
        // Check for persisted asset
        String persistedAsset = getPrefs().getString("active_asset", null);
        if (persistedAsset != null) {
            String assetPath = assetManager.getAssetPath(persistedAsset);
            if (assetPath != null) {
                File rootDir = new java.io.File(assetPath);
                File webRootDir = findWebRoot(rootDir);
                if (webRootDir == null) webRootDir = rootDir;
                
                try {
                    startLocalServer(webRootDir);
                    // Note: We don't need to patch CapConfig here because DevServer.java logic handled the `server_url` preference which was set in applyAsset.
                    // We just need to make sure the server IS RUNNING so when WebView calls, it works.
                } catch (IOException e) {
                   // Log error
                   e.printStackTrace();
                }
            }
        }
    }

    private SharedPreferences getPrefs() {
        Context ctx = getContext();
        return ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    @PluginMethod
    public void setServer(PluginCall call) {
        String url = call.getString("url");
        Boolean autoRestart = call.getBoolean("autoRestart", true);
        Boolean persist = call.getBoolean("persist", false);

        if (url != null) {
            if (persist) {
                getPrefs().edit().putString("server_url", url).apply();
                DevServer.sessionUrl = null;
            } else {
                DevServer.sessionUrl = url;
                getPrefs().edit().remove("server_url").apply();
            }
            // If setting manual server, clear active asset persistence
            getPrefs().edit().remove("active_asset").apply();
        }

        JSObject ret = new JSObject();
        ret.put("url", DevServer.sessionUrl != null ? DevServer.sessionUrl : getPrefs().getString("server_url", null));
        ret.put("persist", persist);
        
        if (autoRestart) {
            getBridge().executeOnMainThread(() -> {
                getActivity().recreate();
            });
        }
        
        call.resolve(ret);
    }

    @PluginMethod
    public void getServer(PluginCall call) {
        String savedUrl = getPrefs().getString("server_url", null);
        JSObject ret = new JSObject();
        ret.put("url", DevServer.sessionUrl != null ? DevServer.sessionUrl : savedUrl);
        ret.put("persist", DevServer.sessionUrl == null && savedUrl != null);
        call.resolve(ret);
    }

    @PluginMethod
    public void clearServer(PluginCall call) {
        Boolean autoRestart = call.getBoolean("autoRestart", true);
        
        DevServer.sessionUrl = null;
        getPrefs().edit()
            .remove("server_url")
            .remove("active_asset")
            .apply();
        
        // Also stop local server if running
        stopLocalServer();

        JSObject ret = new JSObject();
        ret.put("cleared", true);
        
        if (autoRestart) {
            getBridge().executeOnMainThread(() -> {
                getActivity().recreate();
            });
        }
        
        call.resolve(ret);
    }

    @PluginMethod
    public void applyServer(PluginCall call) {
        getServer(call);
    }

    // Asset Management

    @PluginMethod
    public void downloadAsset(PluginCall call) {
        String url = call.getString("url");
        Boolean overwrite = call.getBoolean("overwrite", false);
        String checksum = call.getString("checksum");

        if (url == null) {
            call.reject("URL is required");
            return;
        }

        // Run in background
        new Thread(() -> {
            try {
                assetManager.downloadAndExtract(url, overwrite, checksum);
                call.resolve();
            } catch (Exception e) {
                call.reject("Download failed: " + e.getMessage());
            }
        }).start();
    }

    @PluginMethod
    public void getAssetList(PluginCall call) {
        List<String> assets = assetManager.getAssetList();
        
        JSObject ret = new JSObject();
        com.getcapacitor.JSArray array = new com.getcapacitor.JSArray();
        for(String s : assets) {
            array.put(s);
        }
        ret.put("assets", array);
        call.resolve(ret);
    }

    @PluginMethod
    public void removeAsset(PluginCall call) {
        String assetName = call.getString("assetName");
        if (assetName == null) {
            call.reject("Asset Name is required");
            return;
        }
        assetManager.removeAsset(assetName);
        call.resolve();
    }

    @PluginMethod
    public void checkForUpdate(PluginCall call) {
        performUpdateCheck(call, (data) -> {
            call.resolve(data);
        });
    }

    @PluginMethod
    public void sync(PluginCall call) {
        performUpdateCheck(call, (data) -> {
            boolean isUpdateAvailable = data.getBool("isUpdateAvailable", false);
            String downloadUrl = data.getString("downloadUrl");

            if (!isUpdateAvailable || downloadUrl == null) {
                JSObject ret = new JSObject();
                ret.put("updated", false);
                call.resolve(ret);
                return;
            }

            // Start Download
            new Thread(() -> {
                try {
                    assetManager.downloadAndExtract(downloadUrl, true, null);
                    
                    // Apply new asset
                    JSObject latestBundle = data.getJSObject("latestBundle");
                    if (latestBundle != null && latestBundle.has("id")) {
                        Object assetId = latestBundle.get("id");
                        applyBundleInternal(String.valueOf(assetId), true, call);
                    } else {
                        JSObject ret = new JSObject();
                        ret.put("updated", true);
                        ret.put("note", "downloaded but could not auto-apply id mapping");
                        call.resolve(ret);
                    }
                } catch (Exception e) {
                    call.reject("Sync failed at download: " + e.getMessage());
                }
            }).start();
        });
    }

    private interface UpdateCheckCallback {
        void onResult(JSObject data);
    }

    private void performUpdateCheck(PluginCall call, UpdateCheckCallback callback) {
        String urlString = call.getString("url");
        String channel = call.getString("channel", "production");

        if (urlString == null) {
            call.reject("URL is required");
            return;
        }

        new Thread(() -> {
            try {
                java.net.URL url = new java.net.URL(urlString);
                java.net.HttpURLConnection conn = (java.net.HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                
                // Metadata Headers
                String deviceId = android.provider.Settings.Secure.getString(getContext().getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);
                conn.setRequestProperty("X-Device-Identifier", deviceId);
                conn.setRequestProperty("X-Platform", "android");
                conn.setRequestProperty("X-Bundle-Id", getPrefs().getString("active_asset", ""));
                conn.setRequestProperty("X-Channel", channel);

                int responseCode = conn.getResponseCode();
                if (responseCode == 200) {
                    java.io.BufferedReader in = new java.io.BufferedReader(new java.io.InputStreamReader(conn.getInputStream()));
                    StringBuilder response = new StringBuilder();
                    String inputLine;
                    while ((inputLine = in.readLine()) != null) {
                        response.append(inputLine);
                    }
                    in.close();

                    org.json.JSONObject json = new org.json.JSONObject(response.toString());
                    JSObject result = new JSObject();
                    result.put("isUpdateAvailable", json.optBoolean("is_update_available", false));
                    result.put("latestBundle", JSObject.fromJSONObject(json.optJSONObject("latest_bundle")));
                    result.put("currentBundle", JSObject.fromJSONObject(json.optJSONObject("current_bundle")));
                    result.put("downloadUrl", json.optString("download_url", null));

                    callback.onResult(result);
                } else {
                    call.reject("Update check failed with HTTP " + responseCode);
                }
            } catch (Exception e) {
                call.reject("Update check error: " + e.getMessage());
            }
        }).start();
    }

    @PluginMethod
    public void applyAsset(PluginCall call) {
        String assetName = call.getString("assetName");
        Boolean persist = call.getBoolean("persist", false);
        
        if (assetName == null) {
            call.reject("Asset Name is required");
            return;
        }

        applyBundleInternal(assetName, persist, call);
    }

    private void applyBundleInternal(String assetName, boolean persist, PluginCall call) {
        String assetPath = assetManager.getAssetPath(assetName);
        if (assetPath == null) {
            if (call != null) call.reject("Asset not found");
            return;
        }

        // Smart Web Root Detection
        File rootDir = new java.io.File(assetPath);
        File webRootDir = findWebRoot(rootDir);
        
        if (webRootDir == null) {
             webRootDir = rootDir;
        }

        // Start Local Server
        try {
            startLocalServer(webRootDir);
        } catch (IOException e) {
            if (call != null) call.reject("Failed to start local server: " + e.getMessage());
            return;
        }

        String localUrl = "http://localhost:" + LOCAL_PORT;
        
        if (persist) {
            getPrefs().edit()
                .putString("server_url", localUrl)
                .putString("active_asset", assetName)
                .commit();
            DevServer.sessionUrl = null;
        } else {
            DevServer.sessionUrl = localUrl;
            getPrefs().edit()
                .remove("server_url")
                .remove("active_asset")
                .commit();
        }
        
        // Reload
        getBridge().executeOnMainThread(() -> {
            getActivity().recreate();
        });
        
        if (call != null) call.resolve();
    }
    
    private java.io.File findWebRoot(java.io.File dir) {
        if (new java.io.File(dir, "index.html").exists()) {
            return dir;
        }
        
        java.io.File[] files = dir.listFiles();
        if (files != null) {
            for (java.io.File f : files) {
                if (f.isDirectory()) {
                    java.io.File found = findWebRoot(f);
                    if (found != null) return found;
                }
            }
        }
        return null;
    }

    @PluginMethod
    public void restoreDefaultAsset(PluginCall call) {
        stopLocalServer();
        DevServer.sessionUrl = null;
        getPrefs().edit()
            .remove("server_url")
            .remove("active_asset")
            .commit();
        
        getBridge().executeOnMainThread(() -> {
            getActivity().recreate();
        });
        call.resolve();
    }
    
    private synchronized void startLocalServer(File webRootDir) throws IOException {
        if (localServer != null && localServer.isAlive()) {
             // Server is already running, just swap the root!
             localServer.setRootDir(webRootDir);
             return;
        }
        
        // If dead or null, cleanup just in case
        if (localServer != null) {
            localServer.stop();
            localServer = null;
        }

        // Start fresh on strict port 8080 (as requested by user)
        // We no longer increment ports.
        try {
            localServer = new LocalServer(LOCAL_PORT, webRootDir);
            localServer.start();
        } catch (IOException e) {
            throw new IOException("Failed to start server on port " + LOCAL_PORT + ". " + e.getMessage());
        }
    }

    private void stopLocalServer() {
        if (localServer != null) {
            localServer.stop();
            localServer = null;
        }
    }
}
