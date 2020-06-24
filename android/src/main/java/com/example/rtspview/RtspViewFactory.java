package com.example.rtspview;

import android.app.Activity;
import android.content.Context;
import android.view.View;

import io.flutter.Log;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class RtspViewFactory extends PlatformViewFactory {
    private static final String TAG = "RtspViewFactory";
    private final BinaryMessenger messager;
    private final View containerView;
    private final Activity activity;
    private final int state;

    public RtspViewFactory(Activity activity, BinaryMessenger messenger, int state, View containerView) {
        super(StandardMessageCodec.INSTANCE);
        this.messager = messenger;
        this.containerView = containerView;
        this.activity = activity;
        this.state = state;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new RtspController(activity, context, messager, viewId, state);
    }
}
