import { WebPlugin } from '@capacitor/core';

import type { DevServerPlugin, ServerOptions } from './definitions';

export class DevServerWeb extends WebPlugin implements DevServerPlugin {
  private readonly SESSION_KEY = 'cap_server_url_session';
  private readonly PERSIST_KEY = 'cap_server_url';

  async setServer(options: ServerOptions): Promise<ServerOptions> {
    if (options.url !== undefined) {
      if (options.persist) {
        localStorage.setItem(this.PERSIST_KEY, options.url);
        sessionStorage.removeItem(this.SESSION_KEY);
      } else {
        sessionStorage.setItem(this.SESSION_KEY, options.url);
        localStorage.removeItem(this.PERSIST_KEY);
      }
    }

    const result: ServerOptions = await this.getServer();
    result.autoRestart = options.autoRestart;
    result.persist = options.persist;

    if (options.autoRestart !== false) {
      window.location.reload();
    }

    return result;
  }

  async getServer(): Promise<ServerOptions> {
    const sessionUrl = sessionStorage.getItem(this.SESSION_KEY);
    const persistUrl = localStorage.getItem(this.PERSIST_KEY);

    return {
      url: sessionUrl || persistUrl || undefined,
      persist: !!persistUrl,
    };
  }

  async clearServer(): Promise<{ cleared: boolean }> {
    sessionStorage.removeItem(this.SESSION_KEY);
    localStorage.removeItem(this.PERSIST_KEY);

    window.location.reload();
    return { cleared: true };
  }

  async applyServer(): Promise<ServerOptions> {
    return this.getServer();
  }

  async downloadAsset(options: { url: string; overwrite?: boolean }): Promise<void> {
    console.warn('downloadAsset is not supported on web', options);
  }

  async getAssetList(): Promise<{ assets: string[] }> {
    console.warn('getAssetList is not supported on web');
    return { assets: [] };
  }

  async applyAsset(options: { assetName: string; persist?: boolean }): Promise<void> {
    console.warn('applyAsset is not supported on web', options);
  }

  async removeAsset(options: { assetName: string }): Promise<void> {
    console.warn('removeAsset is not supported on web', options);
  }

  async restoreDefaultAsset(): Promise<void> {
    console.warn('restoreDefaultAsset is not supported on web');
  }
}
