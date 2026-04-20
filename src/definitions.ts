export interface ServerOptions {
  /**
   * The URL of the remote dev server.
   */
  url?: string;
  /**
   * Whether to automatically reload the app after setting the server.
   * @default true
   */
  autoRestart?: boolean;
  /**
   * Whether to persist the server URL across app restarts.
   * If false, the server will revert to the default on the next app launch.
   * @default false
   */
  persist?: boolean;
}

/**
 * Options for automated updates.
 */
export interface SyncOptions {
  /**
   * The URL of the update server (e.g. your Laravel backend).
   */
  url: string;
  /**
   * The deployment channel to check (e.g. 'production', 'staging').
   * @default 'production'
   */
  channel?: string;
}

/**
 * Result of the update check.
 */
export interface CheckUpdateResult {
  /**
   * Whether a newer bundle is available.
   */
  isUpdateAvailable: boolean;
  /**
   * Metadata of the latest bundle.
   */
  latestBundle?: any;
  /**
   * Metadata of the currently applied bundle.
   */
  currentBundle?: any;
  /**
   * The URL to download the ZIP bundle from.
   */
  downloadUrl?: string;
}

export interface DevServerPlugin {
  /**
   * Set a remote dev server URL.
   */
  setServer(options: ServerOptions): Promise<ServerOptions>;
  /**
   * Get the current dev server URL and persistence status.
   */
  getServer(): Promise<ServerOptions>;
  /**
   * Clear the current dev server URL and active asset.
   */
  clearServer(): Promise<{ cleared: boolean }>;
  /**
   * Apply the current server configuration (useful for manual reloads).
   */
  applyServer(): Promise<ServerOptions>;

  /**
   * Download a ZIP asset bundle and extract it locally.
   */
  downloadAsset(options: { url: string; overwrite?: boolean; checksum?: string }): Promise<void>;
  /**
   * List all locally available asset bundles.
   */
  getAssetList(): Promise<{ assets: string[] }>;
  /**
   * Apply a specific asset bundle by its name/folder.
   */
  applyAsset(options: { assetName: string; persist?: boolean }): Promise<void>;
  /**
   * Remove a locally stored asset bundle.
   */
  removeAsset(options: { assetName: string }): Promise<void>;
  /**
   * Revert to the built-in assets from the binary.
   */
  restoreDefaultAsset(): Promise<void>;

  /**
   * Check if a newer bundle is available on the update server.
   * Automatically handles device identification and version reporting.
   */
  checkForUpdate(options: SyncOptions): Promise<CheckUpdateResult>;
  /**
   * Orchestrates the full update cycle (check, download, apply, and reload).
   */
  sync(options: SyncOptions): Promise<{ updated: boolean }>;
}
