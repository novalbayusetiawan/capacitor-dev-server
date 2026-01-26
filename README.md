# capacitor-dev-server

**Dynamic updates for your Capacitor environment.** 🚀

A powerful Capacitor plugin that gives you full control over your app's web content source. Switch between local development servers for live reload or download and serve static web asset bundles dynamically.

## ✨ Features

- **🖥️ Remote Dev Server**: Connect your app to a running local server (e.g., `http://192.168.1.x:3000`) on your network. Perfect for Live Reload during development without rebuilding native code.
- **📦 Dynamic Bundles**: Download ZIP files containing your web app (HTML/CSS/JS), extract them locally, and serve them offline. Great for "Code Push" style updates or testing different branches.
- **⚡ Hot Swapping**: Switch between localized bundles or remote servers instantly.
- **🔒 Security**: Built-in SHA-256 Checksum verification ensures downloaded assets are authentic and untampered.
- **💾 Persistence**: Optionally persist your chosen environment (Server URL or Local Bundle) across app restarts.

---

## 📦 Install

```bash
npm install capacitor-dev-server
npx cap sync
```

## 🔧 Setup

To enable dynamic loading, you must inject the configuration before Capacitor initializes.

### Android

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
> To allow `http://` traffic (common for local dev servers), enable Cleartext Traffic.
>
> **Recommended**: Create `android/app/src/debug/AndroidManifest.xml`:
>
> ```xml
> <manifest xmlns:android="http://schemas.android.com/apk/res/android">
>     <application android:usesCleartextTraffic="true" />
> </manifest>
> ```

### iOS

Open `ios/App/App/ViewController.swift` (create it if missing):

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
        for (key, value) in devOptions ?? [:] {
            options[key] = value
        }

        return options
    }
}
```

> **Note**: Ensure `Main.storyboard` uses `ViewController` as the initial view controller.

---

## 🛠️ Usage

### Feature 1: Remote Dev Server

Connect to your computer's local server for live reload.

```typescript
import { DevServer } from 'capacitor-dev-server';

// Connect to a remote server
await DevServer.setServer({
  url: 'http://192.168.1.5:3000',
  autoRestart: true,
  persist: true, // Remember this URL on next app launch
});

// Revert to the built-in app bundle
await DevServer.restoreDefaultAsset();
```

### Feature 2: Webview Bundles (Asset Management)

Download and serve web assets dynamically.

```typescript
import { DevServer } from 'capacitor-dev-server';

// 1. Download a zip bundle (with optional security check)
await DevServer.downloadAsset({
  url: 'https://example.com/build-v2.zip',
  overwrite: true,
  checksum: 'a1b2c3d4...', // Optional SHA-256 hash for verification
});

// 2. List available bundles
const { assets } = await DevServer.getAssetList();
console.log(assets); // ['build-v2']

// 3. Apply the bundle (Hot Swap)
await DevServer.applyAsset({
  assetName: 'build-v2',
  persist: true, // Load this bundle on next app launch
});
```

---

## 📚 API

<docgen-index>

- [`setServer(...)`](#setserver)
- [`getServer()`](#getserver)
- [`clearServer()`](#clearserver)
- [`downloadAsset(...)`](#downloadasset)
- [`getAssetList()`](#getassetlist)
- [`applyAsset(...)`](#applyasset)
- [`removeAsset(...)`](#removeasset)
- [`restoreDefaultAsset()`](#restoredefaultasset)
- [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source(s) to generate documents.-->

### setServer(...)

```typescript
setServer(options: ServerOptions) => Promise<ServerOptions>
```

Updates the app to point to a specific server URL.

| Param         | Type                                                    | Description                        |
| ------------- | ------------------------------------------------------- | ---------------------------------- |
| **`options`** | <code><a href="#serveroptions">ServerOptions</a></code> | The server configuration to apply. |

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### getServer()

```typescript
getServer() => Promise<ServerOptions>
```

Retrieves the currently active server URL or asset configuration.

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### clearServer()

```typescript
clearServer() => Promise<{ cleared: boolean; }>
```

Resets configuration to defaults.

**Returns:** <code>Promise&lt;{ cleared: boolean; }&gt;</code>

---

### downloadAsset(...)

```typescript
downloadAsset(options: { url: string; overwrite?: boolean; checksum?: string; }) => Promise<void>
```

Downloads a ZIP file from a URL, verifies its checksum (optional), and extracts it.

| Param         | Type                                                                  | Description                                  |
| ------------- | --------------------------------------------------------------------- | -------------------------------------------- |
| **`options`** | <code>{ url: string; overwrite?: boolean; checksum?: string; }</code> | `url`: URL to zip. `checksum`: SHA-256 hash. |

---

### getAssetList()

```typescript
getAssetList() => Promise<{ assets: string[]; }>
```

Returns a list of downloaded asset names.

**Returns:** <code>Promise&lt;{ assets: string[]; }&gt;</code>

---

### applyAsset(...)

```typescript
applyAsset(options: { assetName: string; persist?: boolean; }) => Promise<void>
```

Switches the WebView to serve content from a downloaded asset.

| Param         | Type                                                   | Description                                                  |
| ------------- | ------------------------------------------------------ | ------------------------------------------------------------ |
| **`options`** | <code>{ assetName: string; persist?: boolean; }</code> | `assetName`: Name of folder. `persist`: Save across restart. |

---

### removeAsset(...)

```typescript
removeAsset(options: { assetName: string; }) => Promise<void>
```

Deletes a downloaded asset from the device.

| Param         | Type                                | Description |
| ------------- | ----------------------------------- | ----------- |
| **`options`** | <code>{ assetName: string; }</code> |             |

---

### restoreDefaultAsset()

```typescript
restoreDefaultAsset() => Promise<void>
```

Restores the app to use the built-in bundled web assets.

---

### Interfaces

#### ServerOptions

| Prop              | Type                 | Description                               |
| ----------------- | -------------------- | ----------------------------------------- |
| **`url`**         | <code>string</code>  | The URL to connect to.                    |
| **`autoRestart`** | <code>boolean</code> | Restart app automatically after applying. |
| **`persist`**     | <code>boolean</code> | Persist this setting across app restarts. |

</docgen-api>
