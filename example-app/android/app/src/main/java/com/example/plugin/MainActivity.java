package com.example.plugin;

import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
import dev.novals.devserver.DevServer;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void load() {
        this.config = DevServer.getCapacitorConfig(this);
        super.load();
    }
}
