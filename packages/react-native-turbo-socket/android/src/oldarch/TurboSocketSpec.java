package com.serserm.turbosocket;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;

abstract class TurboSocketSpec extends ReactContextBaseJavaModule {
  TurboSocketSpec(ReactApplicationContext context) {
    super(context);
  }

    public abstract void addListener(String eventName);

    public abstract void removeListeners(double count);

}
