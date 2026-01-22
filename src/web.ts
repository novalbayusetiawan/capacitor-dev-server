import { WebPlugin } from '@capacitor/core';

import type { CapacitorDevServerPlugin } from './definitions';

export class CapacitorDevServerWeb extends WebPlugin implements CapacitorDevServerPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
