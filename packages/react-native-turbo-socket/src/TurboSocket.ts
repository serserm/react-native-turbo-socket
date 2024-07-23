import { NativeModules } from 'react-native';

import { LINKING_ERROR } from './errors';

// @ts-expect-error
const isTurboModuleEnabled = global.__turboModuleProxy != null;

const TurboSocketModule = isTurboModuleEnabled
  ? require('./NativeTurboSocket').default
  : NativeModules.TurboSocket;

export const TurboSocket = TurboSocketModule
  ? TurboSocketModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      },
    );
