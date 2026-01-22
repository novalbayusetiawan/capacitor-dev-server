package dev.novals.capacitor_dev_server;

import com.getcapacitor.Logger;

public class CapacitorDevServer {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}
