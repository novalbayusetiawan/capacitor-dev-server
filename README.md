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
import dev.novals.capacitor_dev_server.CapacitorDevServer;

public class MainActivity extends BridgeActivity {

    @Override
    protected void load() {
        // Inject the dynamic config
        this.config = CapacitorDevServer.getCapacitorConfig(this);
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
import CapacitorDevServer

class ViewController: CAPBridgeViewController {

    override func capacitorOptions() -> [String : Any]! {
        var options = super.capacitorOptions() ?? [:]

        // Merge with our dev server options
        let devOptions = CapacitorDevServer.capacitorOptions()
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

```typescript
import { CapacitorDevServer } from 'capacitor-dev-server';

async function connectToDevServer() {
  await CapacitorDevServer.setServer({
    url: 'http://192.168.1.5:3000',
    cleartext: true, // Required for http:// on Android
    autoRestart: true, // Restarts the app to apply changes immediately
  });
}
```

### Advanced Configuration

You can also set individual properties if you don't want to use the full object:

```typescript
import { CapacitorDevServer } from 'capacitor-dev-server';

// Set just the URL
await CapacitorDevServer.setServerUrl({ url: 'http://192.168.1.5:3000' });

// Enable cleartext traffic (HTTP) on Android
await CapacitorDevServer.setCleartext({ allow: true });

// Change the scheme (e.g. for custom deep links or localhost)
await CapacitorDevServer.setAndroidScheme({ scheme: 'http' });

// Finally, apply and restart
await CapacitorDevServer.applyServer();
```

### Listening for Changes (Web)

In web development or testing environments, you can listen for custom events dispatched by the plugin:

```javascript
window.addEventListener('capacitorDevServer:serverChanged', (event) => {
  console.log('Server config changed:', event.detail);
});

window.addEventListener('capacitorDevServer:serverApply', (event) => {
  console.log('Server config applied:', event.detail);
});
```

---

## API

### setServer(...)

Updates the server configuration. This is the recommended way to set multiple options at once.

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

### setServerUrl(...)

Convenience method to update only the server URL.

```typescript
setServerUrl(options: { url: string; }) => Promise<{ url: string; }>
```

| Param         | Type                          | Description                |
| ------------- | ----------------------------- | -------------------------- |
| **`options`** | <code>{ url: string; }</code> | Object containing the URL. |

**Returns:** <code>Promise&lt;{ url: string; }&gt;</code>

---

### getServerUrl()

Retrieves only the currently saved server URL.

```typescript
getServerUrl() => Promise<{ url: string; }>
```

**Returns:** <code>Promise&lt;{ url: string; }&gt;</code>

---

### setCleartext(...)

Enables or disables cleartext (HTTP) traffic. Primarily used for Android development.

```typescript
setCleartext(options: { allow: boolean; }) => Promise<{ cleartext: boolean; }>
```

| Param         | Type                             | Description                         |
| ------------- | -------------------------------- | ----------------------------------- |
| **`options`** | <code>{ allow: boolean; }</code> | Whether to allow cleartext traffic. |

**Returns:** <code>Promise&lt;{ cleartext: boolean; }&gt;</code>

---

### getCleartext()

Checks if cleartext traffic is currently allowed.

```typescript
getCleartext() => Promise<{ cleartext: boolean; }>
```

**Returns:** <code>Promise&lt;{ cleartext: boolean; }&gt;</code>

---

### setAndroidScheme(...)

Updates the URL scheme for Android (e.g., 'http' or 'https').

```typescript
setAndroidScheme(options: { scheme: string; }) => Promise<{ scheme: string; }>
```

| Param         | Type                             | Description        |
| ------------- | -------------------------------- | ------------------ |
| **`options`** | <code>{ scheme: string; }</code> | The scheme to use. |

**Returns:** <code>Promise&lt;{ scheme: string; }&gt;</code>

---

### getAndroidScheme()

Retrieves the current Android URL scheme.

```typescript
getAndroidScheme() => Promise<{ scheme: string; }>
```

**Returns:** <code>Promise&lt;{ scheme: string; }&gt;</code>

---

### enableDevMode()

Enables development mode features.

```typescript
enableDevMode() => Promise<{ enabled: true; }>
```

**Returns:** <code>Promise&lt;{ enabled: true; }&gt;</code>

---

### disableDevMode()

Disables development mode features.

```typescript
disableDevMode() => Promise<{ enabled: false; }>
```

**Returns:** <code>Promise&lt;{ enabled: false; }&gt;</code>

---

### isDevModeEnabled()

Checks if development mode is currently enabled.

```typescript
isDevModeEnabled() => Promise<{ enabled: boolean; }>
```

**Returns:** <code>Promise&lt;{ enabled: boolean; }&gt;</code>

---

### Interfaces

#### ServerOptions

The main configuration object for the server.

| Prop              | Type                 | Description                                      | Default |
| ----------------- | -------------------- | ------------------------------------------------ | ------- |
| **`url`**         | <code>string</code>  | The server URL (e.g. http://192.168.1.5:3000)    | —       |
| **`cleartext`**   | <code>boolean</code> | Whether to allow HTTP traffic                    | —       |
| **`scheme`**      | <code>string</code>  | The URL scheme (e.g. http, https)                | —       |
| **`autoRestart`** | <code>boolean</code> | Automatically reload the webview (default: true) | `true`  |

</docgen-api>
