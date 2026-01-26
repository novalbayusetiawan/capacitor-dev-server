export interface ServerOptions {
  url?: string;
  autoRestart?: boolean;
  /**
   * Whether to persist the server URL across app restarts.
   * If false, the server will revert to the default on the next app launch.
   * @default false
   */
  persist?: boolean;
}

export interface DevServerPlugin {
  // Multi-field operations
  setServer(options: ServerOptions): Promise<ServerOptions>;
  getServer(): Promise<ServerOptions>;
  clearServer(): Promise<{ cleared: boolean }>;
  applyServer(): Promise<ServerOptions>;

  // Asset Management
  downloadAsset(options: { url: string; overwrite?: boolean }): Promise<void>;
  getAssetList(): Promise<{ assets: string[] }>;
  applyAsset(options: { assetName: string; persist?: boolean }): Promise<void>;
  removeAsset(options: { assetName: string }): Promise<void>;
  restoreDefaultAsset(): Promise<void>;
}
