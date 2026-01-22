import { registerPlugin } from '@capacitor/core';

import type { CapacitorDevServerPlugin } from './definitions';

const CapacitorDevServer = registerPlugin<CapacitorDevServerPlugin>('CapacitorDevServer', {
  web: () => import('./definitions').then((m) => m.CapacitorDevServerWeb),
});

export * from './definitions';
export { CapacitorDevServer };
