package com.example.plugin;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
import dev.novals.capacitor_dev_server.CapacitorDevServer;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void load() {
        this.config = CapacitorDevServer.getCapacitorConfig(this);
        super.load();
    }
}
