package dev.novals.devserver;

import android.content.Context;
import android.content.SharedPreferences;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "DevServer")
public class DevServerPlugin extends Plugin {

    private static final String PREFS_NAME = "capacitor_dev_server_prefs";

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
