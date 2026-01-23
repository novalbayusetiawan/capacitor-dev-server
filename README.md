# capacitor-dev-server

A Capacitor plugin to dynamically load the development server URL at runtime. This allows you to switch between different development servers (or between local dev and production) without rebuilding the native app.

## Install

```bash
npm install capacitor-dev-server
npx cap sync
```

## Android Setup

To enable dynamic loading on Android, you must modify your `MainActivity.java` to inject the configuration before the Bridge initializes.

Open `android/app/src/main/java/.../MainActivity.java` and override the `load()` method:

```java
package com.example.app;

import com.getcapacitor.BridgeActivity;
// Import the plugin
import dev.novals.devserver.DevServer;

public class MainActivity extends BridgeActivity {

    @Override
    protected void load() {
        // Inject the dynamic config
        this.config = DevServer.getCapacitorConfig(this);
        super.load();
    }
}
```

> [!IMPORTANT]
> **Android Cleartext Traffic**
>
> By default, Android blocks non-HTTPS traffic. To load `http://` dev servers, you have two options:
>
> **Option 1: Main Manifest (Simple)**
> Add `android:usesCleartextTraffic="true"` to your `<application>` tag in `android/app/src/main/AndroidManifest.xml`.
>
> **Option 2: Debug Manifest (Recommended)**
> Create a debug-specific manifest at `android/app/src/debug/AndroidManifest.xml` to enable it only for development:
>
> ```xml
> <?xml version="1.0" encoding="utf-8"?>
> <manifest xmlns:android="http://schemas.android.com/apk/res/android">
>     <application android:usesCleartextTraffic="true" />
> </manifest>
> ```

## iOS Setup

To enable dynamic loading on iOS, you must modify (or create) your `ViewController.swift` to merge the saved options with the default Capacitor options.

Open `ios/App/App/ViewController.swift`. If it doesn't exist, create it.

```swift
import UIKit
import Capacitor
// Import the plugin
import DevServerPlugin

class ViewController: CAPBridgeViewController {

    override func capacitorOptions() -> [String : Any]! {
        var options = super.capacitorOptions() ?? [:]

        // Merge with our dev server options
        let devOptions = DevServer.capacitorOptions()
        for (key, value) in devOptions {
            options[key] = value
        }

        return options
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
```

> **Note:** If you just created `ViewController.swift`, make sure your Main.storyboard points to this class for the initial view controller.

## Usage

The primary use case for this plugin is to allow your Capacitor app to connect to a development server running on your local machine without having to rebuild the native application.

### Basic Usage

Simply provide the URL of your development server. The plugin will automatically infer whether cleartext (HTTP) or specific schemes are needed based on the provided URL.

```typescript
import { DevServer } from 'capacitor-dev-server';

async function connectToDevServer() {
  await DevServer.setServer({
    url: 'http://192.168.1.5:3000',
    autoRestart: true, // Restarts the app to apply changes immediately
  });
}
```

---

## API

### setServer(...)

Updates the server configuration.

```typescript
setServer(options: ServerOptions) => Promise<ServerOptions>
```

| Param         | Type                                                    | Description                        |
| ------------- | ------------------------------------------------------- | ---------------------------------- |
| **`options`** | <code><a href="#serveroptions">ServerOptions</a></code> | The server configuration to apply. |

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### getServer()

Retrieves the currently saved server configuration.

```typescript
getServer() => Promise<ServerOptions>
```

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### clearServer()

Clears all saved server configurations and resets the app to its default state. This will trigger an app restart.

```typescript
clearServer() => Promise<{ cleared: boolean; }>
```

**Returns:** <code>Promise&lt;{ cleared: boolean; }&gt;</code>

---

### applyServer()

Forces an application restart to apply the currently saved server configuration.

```typescript
applyServer() => Promise<ServerOptions>
```

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### Interfaces

#### ServerOptions

The configuration object for the dev server.

| Prop              | Type                 | Description                                      | Default |
| ----------------- | -------------------- | ------------------------------------------------ | ------- |
| **`url`**         | <code>string</code>  | The server URL (e.g. http://192.168.1.5:3000)    | —       |
| **`autoRestart`** | <code>boolean</code> | Automatically reload the webview (default: true) | `true`  |

</docgen-api>
