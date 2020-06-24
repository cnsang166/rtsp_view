package com.example.rtspview;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.graphics.Color;
import android.media.MediaPlayer;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.VideoView;

import java.util.HashMap;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class RtspController implements PlatformView, MethodChannel.MethodCallHandler,
        Application.ActivityLifecycleCallbacks, MediaPlayer.OnPreparedListener,
        MediaPlayer.OnErrorListener, MediaPlayer.OnCompletionListener {
    private static final String TAG = "FlutterTextView";
    private final MethodChannel methodChannel;
    private final View textView;
    private int initTime;
    private String dataSource = null;
    private String sourceType = null;
    private VideoView videoView;
    private PlayerState playerState;
    private boolean configured = false;
    private boolean disposed = false;

    private int registrarActivityHashCode;

    RtspController(Activity activity, Context context, BinaryMessenger messenger, int id, int state) {
//        this.registrarActivityHashCode = activity.hashCode();
        textView = getLayout(context);
        methodChannel = new MethodChannel(messenger, "rtspview_" + id);
        methodChannel.setMethodCallHandler(this);
        playerState = PlayerState.NOT_INITIALIZED;
    }

    private void configurePlayer() {
        videoView.setOnPreparedListener(this);
        videoView.setOnErrorListener(this);
        videoView.setOnCompletionListener(this);
        videoView.setZOrderOnTop(true);
        this.configured = true;
    }

    private void initVideo(String dataSource, String sourceType, int initTime) {
        if(!configured) {
            this.configurePlayer();
        }
        if(dataSource != null) {
            if(sourceType.equals("VideoSourceType.asset") || sourceType.equals("VideoSourceType.file")) {
                this.videoView.setVideoPath(dataSource);
            } else if(sourceType.equals("VideoSourceType.network")) {
                Uri videoUri = Uri.parse(dataSource);
                videoView.setVideoURI(videoUri);
            }
            this.dataSource = dataSource;
            this.sourceType = sourceType;
            this.initTime = initTime;
        }
    }

    public void dispose() { methodChannel.setMethodCallHandler(null); }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        Log.d(TAG, " >>>> onMethodCall: " + call.method);

        if(call.method.equals("player#setVideoSource")) {
            String videoPath = call.argument("videoSource");
            String sourceType = call.argument("sourceType");
            int initTime = call.argument("initTime");

            if(videoPath != null) {
                if(sourceType.equals("VideoSourceType.asset") || sourceType.equals("VideoSourceType.file")) {
                    initVideo("file://$videoPath", sourceType, initTime);
                } else {
                    initVideo(videoPath, sourceType, initTime);
                }
            }
            result.success(null);
        } else if(call.method.equals("player#start")) {
            startPlayback();
            result.success(null);
        } else if(call.method.equals("player#pause")) {
            pausePlayback();
            result.success(null);
        } else if(call.method.equals("player#stop")) {
            stopPlayback();
            result.success(null);
        } else if(call.method.equals("player#currentPosition")) {
            Map<String, Object> arguments = new HashMap<String, Object>();
            arguments.put("currentPosition", videoView.getCurrentPosition());
            result.success(arguments);
        } else if(call.method.equals("player#isPlaying")) {
            Map<String, Object> arguments2 = new HashMap<String, Object>();
            arguments2.put("isPlaying", videoView.isPlaying());
            result.success(arguments2);
        } else if(call.method.equals("player#seekTo")) {
            final int position = call.argument("position");

            if(position != 0) {
                videoView.seekTo(position);
                result.success(null);
            }
        } else if(call.method.equals("player#onCompletion")) {
            stopPlayback();
            methodChannel.invokeMethod("player:onCompletion", null);
        } else if(call.method.equals("player#onError")) {
            dataSource = null;
            playerState = PlayerState.NOT_INITIALIZED;
            Map<String, Object> arguments = new HashMap<String, Object>();
//            arguments.put("what", what);
//            arguments.put("extra", extra);
            methodChannel.invokeMethod("player#onError", arguments);

        } else if(call.method.equals("player#onPrepared")) {

            if(playerState == PlayerState.PLAY_WHEN_READY) {
                this.startPlayback();
            }
            videoView.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override
                public void onPrepared(MediaPlayer mp) {
                    notifyPlayerPrepared(mp);
                }
            });
        }
    }

    @Override
    public View getView() {
        return textView;
    }

    @SuppressLint("ClickableViewAccessibility")
    private View getLayout(Context context) {
        LinearLayout layout = new LinearLayout(context);
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        // view init
        View v = inflater.inflate(R.layout.activity_main, layout, true);
        videoView = v.findViewById(R.id.native_video_view);
        videoView.setBackgroundColor(Color.rgb(255,100,0));

        v.findViewById(R.id.video_view);
        return v;
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
        this.configurePlayer();
    }

    @Override
    public void onActivityStarted(Activity activity) {

    }

    @Override
    public void onActivityResumed(Activity activity) {

    }

    @Override
    public void onActivityPaused(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            this.pausePlayback();
        }
    }

    @Override
    public void onActivityDestroyed(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode) {
            this.destroyVideoView();
        }
    }

    @Override
    public void onActivityStopped(Activity activity) {
        if (disposed || activity.hashCode() != registrarActivityHashCode)  {
            this.stopPlayback();
        }
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle outState) {

    }

    @Override
    public void onPrepared(MediaPlayer mp) {
        if (playerState == PlayerState.PLAY_WHEN_READY) {
            this.startPlayback();
        }
        else {
            videoView.seekTo(initTime);
            notifyPlayerPrepared(mp);
        }
    }

    @Override
    public boolean onError(MediaPlayer mp, int what, int extra) {
        dataSource = null;
        playerState = PlayerState.NOT_INITIALIZED;
        Map<String, Object> arguments = new HashMap<String, Object>();
        arguments.put("arguments", what);
        arguments.put("extra", extra);
        methodChannel.invokeMethod("player#onError", arguments);
        return true;
    }

    @Override
    public void onCompletion(MediaPlayer mp) {
        stopPlayback();
        methodChannel.invokeMethod("player:onComplieton", null);
    }

    private void startPlayback() {
        if (playerState != PlayerState.PLAYING && dataSource != null) {
            if (playerState != PlayerState.NOT_INITIALIZED) {
                videoView.start();
                playerState = PlayerState.PLAYING;
            } else {
                playerState = PlayerState.PLAY_WHEN_READY;
                initVideo(dataSource, sourceType, initTime);
            }
        }
    }

    private void pausePlayback() {
        if (videoView.canPause()) {
            videoView.pause();
            playerState = PlayerState.PAUSED;
        }
    }

    private void stopPlayback() {
        videoView.stopPlayback();
        playerState = PlayerState.NOT_INITIALIZED;
    }

    private void destroyVideoView() {
        videoView.stopPlayback();
        videoView.setOnPreparedListener(null);
        videoView.setOnErrorListener(null);
        videoView.setOnCompletionListener(null);
        configured = false;
    }

    private void notifyPlayerPrepared(MediaPlayer mediaPlayer) {
        Map<String, Object> arguments = new HashMap<String, Object>();

        if (mediaPlayer != null) {
            arguments.put("height", mediaPlayer.getVideoHeight());
            arguments.put("width", mediaPlayer.getVideoWidth());
            arguments.put("duration", mediaPlayer.getDuration());
            arguments.put("initTime", initTime);
        }

        playerState = PlayerState.PREPARED;
        methodChannel.invokeMethod("player#onPrepared", arguments);

        if(initTime > 0) {
            videoView.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
                @Override
                public void onPrepared(MediaPlayer mp) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        mp.seekTo(initTime,MediaPlayer.SEEK_CLOSEST);
                    else
                        mp.seekTo((int)initTime);
                    videoView.start();
                    videoView.pause();
                }
            });
        }
    }
}
