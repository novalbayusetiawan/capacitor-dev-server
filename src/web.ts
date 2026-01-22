import { WebPlugin } from '@capacitor/core';

import type { CapacitorDevServerPlugin, ServerOptions } from './definitions';

export class CapacitorDevServerWeb extends WebPlugin implements CapacitorDevServerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('[CapacitorDevServer][web] echo', options.value);
    return { value: options.value };
  }

  async setServer(options: ServerOptions): Promise<ServerOptions> {
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
    };

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverChanged', { detail: result }));
    } catch (e) {
      // ignore in restricted environments
    }

    return result;
  }

  async getServer(): Promise<ServerOptions> {
    return {
      url: localStorage.getItem('cap_server_url') || undefined,
      cleartext: localStorage.getItem('cap_server_cleartext') === '1' || undefined,
      scheme: localStorage.getItem('cap_server_scheme') || undefined,
    };
  }

  async clearServer(): Promise<{ cleared: boolean }> {
    localStorage.removeItem('cap_server_url');
    localStorage.removeItem('cap_server_cleartext');
    localStorage.removeItem('cap_server_scheme');
    localStorage.removeItem('cap_dev_enabled');

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverChanged', { detail: { cleared: true } }));
    } catch (e) {
      // ignore
    }

    return { cleared: true };
  }

  async applyServer(): Promise<ServerOptions> {
    const result: ServerOptions = await this.getServer();

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverApply', { detail: result }));
    } catch (e) {
      // ignore
    }

    return result;
  }

  async setServerUrl(options: { url: string }): Promise<{ url: string }> {
    localStorage.setItem('cap_server_url', options.url);
    return { url: options.url };
  }

  async getServerUrl(): Promise<{ url: string }> {
    return { url: localStorage.getItem('cap_server_url') || '' };
  }

  async setCleartext(options: { allow: boolean }): Promise<{ cleartext: boolean }> {
    localStorage.setItem('cap_server_cleartext', options.allow ? '1' : '0');
    return { cleartext: options.allow };
  }

  async getCleartext(): Promise<{ cleartext: boolean }> {
    return { cleartext: localStorage.getItem('cap_server_cleartext') === '1' };
  }

  async setAndroidScheme(options: { scheme: string }): Promise<{ scheme: string }> {
    localStorage.setItem('cap_server_scheme', options.scheme);
    return { scheme: options.scheme };
  }

  async getAndroidScheme(): Promise<{ scheme: string }> {
    return { scheme: localStorage.getItem('cap_server_scheme') || '' };
  }

  async enableDevMode(): Promise<{ enabled: true }> {
    localStorage.setItem('cap_dev_enabled', '1');
    return { enabled: true };
  }

  async disableDevMode(): Promise<{ enabled: false }> {
    localStorage.setItem('cap_dev_enabled', '0');
    return { enabled: false };
  }

  async isDevModeEnabled(): Promise<{ enabled: boolean }> {
    return { enabled: localStorage.getItem('cap_dev_enabled') === '1' };
  }
}
