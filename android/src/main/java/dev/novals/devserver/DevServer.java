package dev.novals.devserver;

import android.content.Context;
import android.content.SharedPreferences;
import com.getcapacitor.CapConfig;
import com.getcapacitor.Logger;

public class DevServer {
    public static String sessionUrl = null;

    public static CapConfig getCapacitorConfig(Context context) {
        SharedPreferences prefs = context.getSharedPreferences("capacitor_dev_server_prefs", Context.MODE_PRIVATE);
        String savedUrl = prefs.getString("server_url", null);
        String serverUrl = sessionUrl != null ? sessionUrl : savedUrl;

        try {
            CapConfig config = CapConfig.loadDefault(context);
            
            if (serverUrl != null) {
                // Patch the server URL
                java.lang.reflect.Field urlField = CapConfig.class.getDeclaredField("serverUrl");
                urlField.setAccessible(true);
                urlField.set(config, serverUrl);

                // Infer scheme and cleartext (allowMixedContent)
                String androidScheme = serverUrl.startsWith("http://") ? "http" : "https";
                boolean allowMixed = serverUrl.startsWith("http://");

                java.lang.reflect.Field schemeField = CapConfig.class.getDeclaredField("androidScheme");
                schemeField.setAccessible(true);
                schemeField.set(config, androidScheme);

                java.lang.reflect.Field mixedField = CapConfig.class.getDeclaredField("allowMixedContent");
                mixedField.setAccessible(true);
                mixedField.set(config, allowMixed);
            }

            return config;
        } catch (Exception e) {
            Logger.error("Failed to patch Capacitor Config", e);
            return CapConfig.loadDefault(context);
        }
    }
}
