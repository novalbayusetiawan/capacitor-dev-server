export interface CapacitorDevServerPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
