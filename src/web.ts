import { WebPlugin } from '@capacitor/core';

import type { DevServerPlugin, ServerOptions } from './definitions';

export class DevServerWeb extends WebPlugin implements DevServerPlugin {
  async setServer(options: ServerOptions): Promise<ServerOptions> {
    if (options.url !== undefined) {
      localStorage.setItem('cap_server_url', options.url);
    }

    const result: ServerOptions = {
      url: localStorage.getItem('cap_server_url') || undefined,
      autoRestart: options.autoRestart,
    };

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

    window.location.reload();
    return { cleared: true };
  }

  async applyServer(): Promise<ServerOptions> {
    const result: ServerOptions = await this.getServer();
    return result;
  }
}
