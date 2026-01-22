import { registerPlugin } from '@capacitor/core';

import type { CapacitorDevServerPlugin } from './definitions';

const CapacitorDevServer = registerPlugin<CapacitorDevServerPlugin>('CapacitorDevServer', {
  web: () => import('./web').then((m) => new m.CapacitorDevServerWeb()),
});

export * from './definitions';
export { CapacitorDevServer };
