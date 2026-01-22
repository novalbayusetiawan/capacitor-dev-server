export interface ServerOptions {
  url?: string;
  autoRestart?: boolean;
}

export interface CapacitorDevServerPlugin {
  // Multi-field operations
  setServer(options: ServerOptions): Promise<ServerOptions>;
  getServer(): Promise<ServerOptions>;
  clearServer(): Promise<{ cleared: boolean }>;
  applyServer(): Promise<ServerOptions>;
}
