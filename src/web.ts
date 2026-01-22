import { WebPlugin } from '@capacitor/core';

import type { CapacitorDevServerPlugin, ServerOptions } from './definitions';

export class CapacitorDevServerWeb extends WebPlugin implements CapacitorDevServerPlugin {
  async setServer(options: ServerOptions): Promise<ServerOptions> {
    if (options.url !== undefined) {
      localStorage.setItem('cap_server_url', options.url);
    }

    const result: ServerOptions = {
      url: localStorage.getItem('cap_server_url') || undefined,
      autoRestart: options.autoRestart,
    };

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverChanged', { detail: result }));
    } catch (e) {
      // ignore in restricted environments
    }

    if (options.autoRestart !== false) {
      window.location.reload();
    }

    return result;
  }

  async getServer(): Promise<ServerOptions> {
    return {
      url: localStorage.getItem('cap_server_url') || undefined,
    };
  }

  async clearServer(): Promise<{ cleared: boolean }> {
    localStorage.removeItem('cap_server_url');

    try {
      window.dispatchEvent(new CustomEvent('capacitorDevServer:serverChanged', { detail: { cleared: true } }));
    } catch (e) {
      // ignore
    }

    window.location.reload();
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
}
