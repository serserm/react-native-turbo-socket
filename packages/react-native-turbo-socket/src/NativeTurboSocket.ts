import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  addListener(eventName: string): void;

  removeListeners(count: number): void;

  startServer(host: string, port: number, type: string): void;

  stopServer(host: string, port: number, type: string): void;

  connectHost(host: string, port: number, type: string): void;

  disconnectHost(host: string, port: number, type: string): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>('TurboSocket');
