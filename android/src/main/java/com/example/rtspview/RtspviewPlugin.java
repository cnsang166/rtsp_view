package com.example.rtspview;

import android.app.Activity;
import android.content.Intent;
import android.view.LayoutInflater;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** RtspviewPlugin */
public class RtspviewPlugin implements FlutterPlugin, ActivityAware {
  private static String TAG = "RtspviewPlugin";
  private Activity activity;
  private RtspController controller;
  private int state;

  /*
     VideoPlayer State Value   */
  private int CREATE = 1;
  private int STARTED = 2;
  private int RESUMED = 3;
  private int PAUSED = 4;
  private int STOPPED = 5;
  private int DESTROYED = 6;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    state = 0;

    binding
            .getFlutterEngine()
            .getPlatformViewsController()
            .getRegistry()
            .registerViewFactory(
                    "plugins.flutter.io/rtspview", new  RtspViewFactory(this.activity, binding.getBinaryMessenger(), state, null));
  }

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "plugins.flutter.io/rtspview");
  }


  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    if(controller == null) {
      return;
    }

    controller.dispose();
    controller = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

  }

  @Override
  public void onDetachedFromActivity() {

  }
}
