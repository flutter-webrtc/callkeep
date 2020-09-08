package com.github.cloudwebrtc.flutter_callkeep;

import android.app.Activity;
import android.content.Context;
import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.wazo.callkeep.CallKeepModule;

/** FlutterCallkeepPlugin */
public class FlutterCallkeepPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private CallKeepModule callKeep;

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final FlutterCallkeepPlugin plugin = new FlutterCallkeepPlugin();

    plugin.startListening(registrar.context(), registrar.messenger());

    if (registrar.activeContext() instanceof Activity) {
      plugin.setActivity((Activity) registrar.activeContext());
    }

    registrar.addViewDestroyListener(view -> {
      plugin.stopListening();
      return false;
    });
  }

  private void setActivity(@NonNull Activity activity) {
    callKeep.setActivity(activity);
  }

  private void startListening(final Context context, BinaryMessenger messenger) {
    channel = new MethodChannel(messenger, "FlutterCallKeep.Method");
    channel.setMethodCallHandler(this);
    callKeep = new CallKeepModule(context, messenger);
  }

  private void stopListening() {
    channel.setMethodCallHandler(null);
    channel = null;
    callKeep.dispose();
    callKeep = null;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    startListening(flutterPluginBinding.getApplicationContext(), flutterPluginBinding.getBinaryMessenger());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (!callKeep.HandleMethodCall(call, result)) {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    stopListening();
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    callKeep.setActivity(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    callKeep.setActivity(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    callKeep.setActivity(binding.getActivity());
  }

  @Override
  public void onDetachedFromActivity() {
    callKeep.setActivity(null);
  }
}
