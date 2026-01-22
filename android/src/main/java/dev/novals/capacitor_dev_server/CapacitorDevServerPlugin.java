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
    public void setServer(PluginCall call) {
        String url = call.getString("url");
        Boolean autoRestart = call.getBoolean("autoRestart", true);

        SharedPreferences.Editor editor = getPrefs().edit();
        if (url != null) editor.putString("server_url", url);
        editor.apply();

        JSObject ret = new JSObject();
        ret.put("url", getPrefs().getString("server_url", null));
        
        if (autoRestart) {
            getBridge().executeOnMainThread(() -> {
                getActivity().recreate();
            });
        }
        
        call.resolve(ret);
    }

    @PluginMethod
    public void getServer(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("url", getPrefs().getString("server_url", null));
        call.resolve(ret);
    }

    @PluginMethod
    public void clearServer(PluginCall call) {
        Boolean autoRestart = call.getBoolean("autoRestart", true);
        
        getPrefs().edit()
            .remove("server_url")
            .apply();
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
}
