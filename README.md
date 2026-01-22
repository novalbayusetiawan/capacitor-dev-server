# capacitor-dev-server

A Capacitor plugin to dynamically load the development server URL at runtime. This allows you to switch between different development servers (or between local dev and production) without rebuilding the native app, similar to "Expo Go".

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

## API

<docgen-index>

- [`setServer(...)`](#setserver)
- [`getServer()`](#getserver)
- [`clearServer()`](#clearserver)
- [`applyServer()`](#applyserver)
- [`setServerUrl(...)`](#setserverurl)
- [`getServerUrl()`](#getserverurl)
- [`setCleartext(...)`](#setcleartext)
- [`getCleartext()`](#getcleartext)
- [`setAndroidScheme(...)`](#setandroidscheme)
- [`getAndroidScheme()`](#getandroidscheme)
- [`enableDevMode()`](#enabledevmode)
- [`disableDevMode()`](#disabledevmode)
- [`isDevModeEnabled()`](#isdevmodeenabled)
- [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### setServer(...)

```typescript
setServer(options: ServerOptions) => Promise<ServerOptions>
```

| Param         | Type                                                    |
| ------------- | ------------------------------------------------------- |
| **`options`** | <code><a href="#serveroptions">ServerOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### getServer()

```typescript
getServer() => Promise<ServerOptions>
```

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### clearServer()

```typescript
clearServer() => Promise<{ cleared: boolean; }>
```

**Returns:** <code>Promise&lt;{ cleared: boolean; }&gt;</code>

---

### applyServer()

```typescript
applyServer() => Promise<ServerOptions>
```

**Returns:** <code>Promise&lt;<a href="#serveroptions">ServerOptions</a>&gt;</code>

---

### setServerUrl(...)

```typescript
setServerUrl(options: { url: string; }) => Promise<{ url: string; }>
```

| Param         | Type                          |
| ------------- | ----------------------------- |
| **`options`** | <code>{ url: string; }</code> |

**Returns:** <code>Promise&lt;{ url: string; }&gt;</code>

---

### getServerUrl()

```typescript
getServerUrl() => Promise<{ url: string; }>
```

**Returns:** <code>Promise&lt;{ url: string; }&gt;</code>

---

### setCleartext(...)

```typescript
setCleartext(options: { allow: boolean; }) => Promise<{ cleartext: boolean; }>
```

| Param         | Type                             |
| ------------- | -------------------------------- |
| **`options`** | <code>{ allow: boolean; }</code> |

**Returns:** <code>Promise&lt;{ cleartext: boolean; }&gt;</code>

---

### getCleartext()

```typescript
getCleartext() => Promise<{ cleartext: boolean; }>
```

**Returns:** <code>Promise&lt;{ cleartext: boolean; }&gt;</code>

---

### setAndroidScheme(...)

```typescript
setAndroidScheme(options: { scheme: string; }) => Promise<{ scheme: string; }>
```

| Param         | Type                             |
| ------------- | -------------------------------- |
| **`options`** | <code>{ scheme: string; }</code> |

**Returns:** <code>Promise&lt;{ scheme: string; }&gt;</code>

---

### getAndroidScheme()

```typescript
getAndroidScheme() => Promise<{ scheme: string; }>
```

**Returns:** <code>Promise&lt;{ scheme: string; }&gt;</code>

---

### enableDevMode()

```typescript
enableDevMode() => Promise<{ enabled: true; }>
```

**Returns:** <code>Promise&lt;{ enabled: true; }&gt;</code>

---

### disableDevMode()

```typescript
disableDevMode() => Promise<{ enabled: false; }>
```

**Returns:** <code>Promise&lt;{ enabled: false; }&gt;</code>

---

### isDevModeEnabled()

```typescript
isDevModeEnabled() => Promise<{ enabled: boolean; }>
```

**Returns:** <code>Promise&lt;{ enabled: boolean; }&gt;</code>

---

### Interfaces

| Prop              | Type                 | Description                                      |
| ----------------- | -------------------- | ------------------------------------------------ |
| **`url`**         | <code>string</code>  | The server URL (e.g. http://192.168.1.5:3000)    |
| **`cleartext`**   | <code>boolean</code> | Whether to allow HTTP traffic                    |
| **`scheme`**      | <code>string</code>  | The URL scheme (e.g. http, https)                |
| **`autoRestart`** | <code>boolean</code> | Automatically reload the webview (default: true) |

</docgen-api>
