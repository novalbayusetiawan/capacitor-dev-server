export interface ServerOptions {
  url?: string;
  cleartext?: boolean;
  scheme?: string;
  autoRestart?: boolean;
}

export interface CapacitorDevServerPlugin {
  // Multi-field operations
  setServer(options: ServerOptions): Promise<ServerOptions>;
  getServer(): Promise<ServerOptions>;
  clearServer(): Promise<{ cleared: boolean }>;
  applyServer(): Promise<ServerOptions>;

  // Convenience single-field APIs
  setServerUrl(options: { url: string }): Promise<{ url: string }>;
  getServerUrl(): Promise<{ url: string }>;
  setCleartext(options: { allow: boolean }): Promise<{ cleartext: boolean }>;
  getCleartext(): Promise<{ cleartext: boolean }>;
  setAndroidScheme(options: { scheme: string }): Promise<{ scheme: string }>;
  getAndroidScheme(): Promise<{ scheme: string }>;

  // Dev mode toggles
  enableDevMode(): Promise<{ enabled: true }>;
  disableDevMode(): Promise<{ enabled: false }>;
  isDevModeEnabled(): Promise<{ enabled: boolean }>;
}

/**
 * Web fallback implementation for environments where native plugins are not available.
 * This mirrors the native plugin behavior using localStorage so the web app can
 * interact with the same API during development or testing.
 *
 * Note: In a real Capacitor plugin package you'd normally register a web implementation
 * that uses Capacitor's `registerPlugin` API. This file provides a portable fallback.
 */
export const CapacitorDevServerWeb: CapacitorDevServerPlugin = {
  setServer: async (options) => {
    if (options.url !== undefined) {
      localStorage.setItem('cap_server_url', options.url);
    }
    if (options.cleartext !== undefined) {
      localStorage.setItem('cap_server_cleartext', options.cleartext ? '1' : '0');
    }
    if (options.scheme !== undefined) {
      localStorage.setItem('cap_server_scheme', options.scheme);
    }

    const result: ServerOptions = {
      url: localStorage.getItem('cap_server_url') || undefined,
      cleartext: localStorage.getItem('cap_server_cleartext') === '1' || undefined,
      scheme: localStorage.getItem('cap_server_scheme') || undefined,
      autoRestart: options.autoRestart,
    };

    // Emit a synthetic event so web apps can listen for changes if desired
    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverChanged', { detail: result }));
    } catch (e) {
      // ignore in restricted environments
    }

    if (options.autoRestart !== false) {
      window.location.reload();
    }

    return result;
  },

  getServer: async () => {
    return {
      url: localStorage.getItem('cap_server_url') || undefined,
      cleartext: localStorage.getItem('cap_server_cleartext') === '1' || undefined,
      scheme: localStorage.getItem('cap_server_scheme') || undefined,
    };
  },

  clearServer: async () => {
    localStorage.removeItem('cap_server_url');
    localStorage.removeItem('cap_server_cleartext');
    localStorage.removeItem('cap_server_scheme');
    localStorage.removeItem('cap_dev_enabled');

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverChanged', { detail: { cleared: true } }));
    } catch (e) {
      // ignore
    }

    window.location.reload();
    return { cleared: true };
  },

  applyServer: async () => {
    const result: ServerOptions = {
      url: localStorage.getItem('cap_server_url') || undefined,
      cleartext: localStorage.getItem('cap_server_cleartext') === '1' || undefined,
      scheme: localStorage.getItem('cap_server_scheme') || undefined,
    };

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverApply', { detail: result }));
    } catch (e) {
      // ignore
    }

    return result;
  },

  setServerUrl: async ({ url }) => {
    localStorage.setItem('cap_server_url', url);
    return { url };
  },

  getServerUrl: async () => {
    return { url: localStorage.getItem('cap_server_url') || '' };
  },

  setCleartext: async ({ allow }) => {
    localStorage.setItem('cap_server_cleartext', allow ? '1' : '0');
    return { cleartext: allow };
  },

  getCleartext: async () => {
    return { cleartext: localStorage.getItem('cap_server_cleartext') === '1' };
  },

  setAndroidScheme: async ({ scheme }) => {
    // Stored generically so iOS/web can still persist the value
    localStorage.setItem('cap_server_scheme', scheme);
    return { scheme };
  },

  getAndroidScheme: async () => {
    return { scheme: localStorage.getItem('cap_server_scheme') || '' };
  },

  enableDevMode: async () => {
    localStorage.setItem('cap_dev_enabled', '1');
    return { enabled: true };
  },

  disableDevMode: async () => {
    localStorage.setItem('cap_dev_enabled', '0');
    return { enabled: false };
  },

  isDevModeEnabled: async () => {
    return { enabled: localStorage.getItem('cap_dev_enabled') === '1' };
  },
};

export default CapacitorDevServerWeb;
