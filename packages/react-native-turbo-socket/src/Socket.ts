import { NativeEventEmitter } from 'react-native';
import type { EmitterSubscription } from 'react-native';

import { TurboSocket } from './TurboSocket';
import type { ListenerType } from './types';

export class Socket {
  #subscription?: EmitterSubscription;

  constructor() {}

  startListening = (listener: ListenerType) => {
    const eventEmitter = new NativeEventEmitter(TurboSocket);
    this.#subscription = eventEmitter.addListener(`socketEvent`, params => {
      listener(params);
    });
  };

  stopListening = (): void => {
    this.#subscription?.remove();
  };
}
