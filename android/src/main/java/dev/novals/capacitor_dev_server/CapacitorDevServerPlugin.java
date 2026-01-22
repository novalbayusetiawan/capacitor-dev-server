package dev.novals.capacitor_dev_server;

import android.content.Context;
import android.content.SharedPreferences;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "CapacitorDevServer")
public class CapacitorDevServerPlugin extends Plugin {

    private static final String PREFS_NAME = "capacitor_dev_server_prefs";

    private CapacitorDevServer implementation = new CapacitorDevServer();

    private SharedPreferences getPrefs() {
        Context ctx = getContext();
        return ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    @PluginMethod
    public void setServerUrl(PluginCall call) {
        String url = call.getString("url");
        if (url == null) {
            call.reject("Must provide a url");
            return;
        }
        getPrefs().edit().putString("server_url", url).apply();
        JSObject ret = new JSObject();
        ret.put("url", url);
        call.resolve(ret);
    }

    @PluginMethod
    public void getServerUrl(PluginCall call) {
        String url = getPrefs().getString("server_url", "");
        JSObject ret = new JSObject();
        ret.put("url", url);
        call.resolve(ret);
    }

    @PluginMethod
    public void setCleartext(PluginCall call) {
        Boolean allow = call.getBoolean("allow");
        if (allow == null) {
            call.reject("Must provide allow boolean");
            return;
        }
        getPrefs().edit().putBoolean("cleartext", allow).apply();
        JSObject ret = new JSObject();
        ret.put("cleartext", allow);
        call.resolve(ret);
    }

    @PluginMethod
    public void getCleartext(PluginCall call) {
        boolean allow = getPrefs().getBoolean("cleartext", false);
        JSObject ret = new JSObject();
        ret.put("cleartext", allow);
        call.resolve(ret);
    }

    @PluginMethod
    public void setAndroidScheme(PluginCall call) {
        String scheme = call.getString("scheme");
        if (scheme == null) {
            call.reject("Must provide scheme");
            return;
        }
        getPrefs().edit().putString("android_scheme", scheme).apply();
        JSObject ret = new JSObject();
        ret.put("scheme", scheme);
        call.resolve(ret);
    }

    @PluginMethod
    public void getAndroidScheme(PluginCall call) {
        String scheme = getPrefs().getString("android_scheme", "");
        JSObject ret = new JSObject();
        ret.put("scheme", scheme);
        call.resolve(ret);
    }

    @PluginMethod
    public void enableDevMode(PluginCall call) {
        getPrefs().edit().putBoolean("dev_enabled", true).apply();
        JSObject ret = new JSObject();
        ret.put("enabled", true);
        call.resolve(ret);
    }

    @PluginMethod
    public void disableDevMode(PluginCall call) {
        getPrefs().edit().putBoolean("dev_enabled", false).apply();
        JSObject ret = new JSObject();
        ret.put("enabled", false);
        call.resolve(ret);
    }

    @PluginMethod
    public void isDevModeEnabled(PluginCall call) {
        boolean enabled = getPrefs().getBoolean("dev_enabled", false);
        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        call.resolve(ret);
    }
}
