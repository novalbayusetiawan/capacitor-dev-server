import { registerPlugin } from '@capacitor/core';

import type { DevServerPlugin } from './definitions';

const DevServer = registerPlugin<DevServerPlugin>('DevServer', {
  web: () => import('./web').then((m) => new m.DevServerWeb()),
});

export * from './definitions';
export { DevServer };
