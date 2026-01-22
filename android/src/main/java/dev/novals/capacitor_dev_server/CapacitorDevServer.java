package dev.novals.capacitor_dev_server;

import android.content.Context;
import android.content.SharedPreferences;
import com.getcapacitor.CapConfig;
import com.getcapacitor.Logger;

public class CapacitorDevServer {

    public static CapConfig getCapacitorConfig(Context context) {
        SharedPreferences prefs = context.getSharedPreferences("capacitor_dev_server_prefs", Context.MODE_PRIVATE);
        String serverUrl = prefs.getString("server_url", null);
        String androidScheme = prefs.getString("android_scheme", null);
        boolean cleartext = prefs.getBoolean("cleartext", false);

        CapConfig.Builder builder = new CapConfig.Builder(context);
        
        // Load default config from capacitor.config.json or similar
         CapConfig defaultConfig = CapConfig.loadDefault(context);
        
        // We can't easily clone the existing one, so we just use the Builder.
        // BUT, CapConfig.Builder doesn't take an existing config as a base.
        // We have to rely on the fact that we are returning a NEW config.
        // However, this might lose other settings from capacitor.config.json if we don't be careful.
        
        // Ideally we wrap the loading logic.
        // Let's inspect CapConfig.java again. Step 57 showed loadDefault returns a CapConfig.
        // But to modify it, we either need setters (which don't exist, fields are private) or use the Builder (which starts fresh).
        
        // Wait, CapConfig fields are private and no setters. 
        // But wait, the user's `MainActivity` uses `this.config = ...`.
        // If we return a fresh config from Builder, it might miss other plugins' config.
        
        // Actually, we can just use the Builder and set the values we want?
        // But what about the *rest* of the config?
        // Step 57: `CapConfig` has `loadDefault(Context context)`.
        
        // Let's look at `CapConfig` again.
        // It has `pluginsConfiguration` map.
        
        // If we cannot modify the `CapConfig` object after creation, we are in trouble if we want to "extend" it.
        // However, `BridgeActivity.load()` does: `bridge = bridgeBuilder.addPlugins(initialPlugins).setConfig(config).create();`
        
        // If we provide a `config` that only has our server stuff, the Bridge might be missing other stuff.
        // BUT `CapConfig.Builder` constructor takes `Context` and likely doesn't load defaults?
        // Checked Step 57: `CapConfig.Builder(Context context)` initializes defaults.
        // It does NOT load from assets.
        // `loadConfigFromAssets` is private.
        
        // This is tricky. We need to create a config that matches what `loadDefault` would return, BUT with our overrides.
        // `CapConfig.loadDefault` calls `loadConfigFromAssets` then `deserializeConfig`.
        
        // We can't access `loadConfigFromAssets`.
        
        // ALTERNATIVE:
        // We can assume user is using `capacitor.config.json`.
        // We can try to use reflection to modify the fields? No, that's brittle.
        
        // Wait, `loadDefault` returns a `CapConfig`. 
        // Can we subclass `CapConfig`? No, constructor is private? 
        // Step 57: `private CapConfig()` and `private CapConfig(Builder builder)`.
        // So we can't subclass it.
        
        // We MUST use `CapConfig.Builder`.
        // But `CapConfig.Builder` doesn't load the JSON.
        
        // Is there a `loadFromAssets` public method?
        // Yes: `public static CapConfig loadFromAssets(Context context, String path)`.
        // And `public static CapConfig loadDefault(Context context)`.
        
        // But these return `CapConfig` instances that we can't modify (no setters).
        
        // Wait! `CapConfig` does NOT have setters?
        // Step 57 shows only getters.
        
        // So we are stuck with `Builder`.
        // Does `Builder` have a way to load from JSON?
        // `Builder` has `setPluginsConfiguration(JSONObject)`.
        
        // This seems to be a limitation of the Capacitor API for this use case if we want to *preserve* existing config.
        
        // UNLESS, we read the JSON ourselves and feed it to the Builder?
        // That's duplicating logic.
        
        // Let's look at `MainActivity` in `example-app`.
        // It extends `BridgeActivity`.
        // `BridgeActivity` has `protected CapConfig config;`.
        // and `onCreate` calls `this.load()`.
        
        // If we override `load()`, we can do:
        // config = CapConfig.loadDefault(this);
        // exclude server url? No.
        
        // Maybe we can use reflection? It's Java.
        // `Field f = CapConfig.class.getDeclaredField("serverUrl"); f.setAccessible(true); f.set(config, newValue);`
        // It's hacking, but might be the only way if there are no setters.
        
        // Let's verify if there are really no setters.
        // Step 57: I see only Getters.
        
        // So Reflection is the way to go for the "helper".
        
        try {
            CapConfig config = CapConfig.loadDefault(context);
            
            if (serverUrl != null) {
                java.lang.reflect.Field urlField = CapConfig.class.getDeclaredField("serverUrl");
                urlField.setAccessible(true);
                urlField.set(config, serverUrl);
            }
            
            if (androidScheme != null) {
                java.lang.reflect.Field schemeField = CapConfig.class.getDeclaredField("androidScheme");
                schemeField.setAccessible(true);
                schemeField.set(config, androidScheme);
            }
            
            if (cleartext) {
                 java.lang.reflect.Field mixedField = CapConfig.class.getDeclaredField("allowMixedContent");
                 mixedField.setAccessible(true);
                 mixedField.set(config, true);
                 
                 // Also android:usesCleartextTraffic is manifest-level, but `allowMixedContent` is WebView level.
                 // Capacitor's config `server.cleartext` usually implies http support.
            }

            return config;
        } catch (Exception e) {
            Logger.error("Failed to patch Capacitor Config", e);
            return CapConfig.loadDefault(context);
        }
    }
}
