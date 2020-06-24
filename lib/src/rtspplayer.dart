part of video_view;

typedef ViewCreatedCallback = void Function(VideoViewController controller);

/// Callback that is called when the playback of a video is completed.
typedef CompletionCallback = void Function(VideoViewController controller);

/// Callback that is called when the player had an error trying to load/play
/// the video source. The values [what] and [extra] are Android exclusives and
/// [message] is iOS exclusive.
typedef ErrorCallback = void Function(
    VideoViewController controller, int what, int extra, String message);

/// Callback that is called when the player finished loading the video
/// source and is prepared to start the playback. The [controller]
/// and [videoInfo] is given as parameters when the function is called.
/// The [videoInfo] parameter contains info related to the file loaded.
typedef PreparedCallback = void Function(VideoViewController controller, VideoInfo videoInfo);

/// Callback that indicates the progression of the media being played.
typedef ProgressionCallback = void Function(int elapsedTime, int duration);

class Rtspplayer extends StatefulWidget {
  final bool keepAspectRatio;
  final bool showMediaController;
  final bool autoHide;
  final Duration autoHideTime;

  final ViewCreatedCallback onCreated;
  final CompletionCallback onCompletion;
  final PreparedCallback onPrepared;
  final ProgressionCallback onProgress;
  final ErrorCallback onError;

  const Rtspplayer({
    Key key,
    this.keepAspectRatio,
    this.showMediaController,
    this.autoHide,
    this.autoHideTime,
    @required this.onCreated,
    @required this.onPrepared,
    @required this.onCompletion,
    this.onError,
    this.onProgress,
  })  : assert(onCreated != null && onPrepared != null && onCompletion != null),
        super(key: key);

  @override
  RtspPlayerState createState() => RtspPlayerState();
}

class RtspPlayerState extends State<Rtspplayer> {
  final Completer<VideoViewController> _controller = Completer<VideoViewController>();

  _MediaControlsController _mediaController = new _MediaControlsController();

//  double _aspectRatio = 16 / 9;
  int setViewid = 0;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _buildVideoView(
        child: AndroidView(
          viewType: 'plugins.flutter.io/rtspview',
          onPlatformViewCreated: onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        ),
      );
    }
  }

  Widget _buildVideoView({Widget child}) {
    bool keepAspectRatio = widget.keepAspectRatio ?? false;
    bool showMediaController = widget.showMediaController ?? false;
    Widget videoView = keepAspectRatio
        ? Expanded(
            child: child,
//  2020.06.23 주석처리
//            aspectRatio: _aspectRatio,
          )
        : child;
    return showMediaController
        ? _MediaController(
            child: videoView,
            controller: _mediaController,
            autoHide: widget.autoHide,
            autoHideTime: widget.autoHideTime,
            onControlPressed: _onControlPressed,
            onPositionChanged: _onPositionChanged,
          )
        : videoView;
  }

  /// Callback that is called when the view is created in the platform.
  Future<void> onPlatformViewCreated(int id) async {
    final VideoViewController controller = await VideoViewController.init(id, this);
    setViewid = id;
    _controller.complete(controller);
    if (widget.onCreated != null) widget.onCreated(controller);
  }

  /// Disposes the controller of the player.
  void _disposeController() async {
    final controller = await _controller.future;
    if (controller != null) controller.dispose();
  }

  /// Time Seek function
  Future<void> seekTo(int position, int duration) async {
    int id = setViewid;
    notifyPlayerPosition(position, duration);
    MethodChannel channel = MethodChannel('rtspview_$id');
    Map<String, dynamic> args = {"position": position};

    await channel.invokeMethod("player#findSeek", args);
  }

  /// Function that is called when the platform notifies that the video has
  /// finished playing.
  /// This function calls the widget's [CompletionCallback] instance.
  void onCompletion(VideoViewController controller) {
    if (widget.onCompletion != null) widget.onCompletion(controller);
  }

  /// Notifies when an action of the player (play, pause & stop) must be
  /// reflected by the media controller view.
  void notifyControlChanged(_MediaControl mediaControl) {
    if (_mediaController != null) _mediaController.notifyControlPressed(mediaControl);
  }

  /// Notifies the player position to the media controller view.
  void notifyPlayerPosition(int position, int duration) {
    if (_mediaController != null) {
      _mediaController.notifyPositionChanged(position, duration);
    }
  }

  /// Function that is called when the platform notifies that an error has
  /// occurred during the video source loading.
  /// This function calls the widget's [ErrorCallback] instance.
  void onError(VideoViewController controller, int what, int extra, String message) {
    if (widget.onError != null) widget.onError(controller, what, extra, message);
  }

  /// Function that is called when the platform notifies that the video
  /// source has been loaded and is ready to start playing.
  /// This function calls the widget's [PreparedCallback] instance.
  void onPrepared(VideoViewController controller, VideoInfo videoInfo) {
    if (videoInfo != null) {
      ////// 2020.06.23 주석처리
//      setState(() {
//        _aspectRatio = videoInfo.aspectRatio;
//      });
      notifyPlayerPosition(videoInfo.initTime, videoInfo.duration);
      if (widget.onPrepared != null) widget.onPrepared(controller, videoInfo);
    }
  }

  /// Function that is called when the player updates the time played.
  void onProgress(int position, int duration) {
    if (widget.onProgress != null) widget.onProgress(position, duration);
    notifyPlayerPosition(position, duration);
  }

  /// When a control is pressed in the media controller, the actions are
  /// realized by the [VideoViewController] and then the result is returned
  /// to the media controller to update the view.
  void _onControlPressed(_MediaControl mediaControl) async {
    VideoViewController controller = await _controller.future;
    if (controller != null) {
      switch (mediaControl) {
        case _MediaControl.pause:
          controller.pause();
          break;
        case _MediaControl.play:
          controller.play();
          break;
        case _MediaControl.stop:
          controller.stop();
          break;
        case _MediaControl.fwd:
          int duration = controller.videoFile?.info?.duration;
          int position = await controller.currentPosition();
          if (duration != null && position != -1) {
            int newPosition = position + 3000 > duration ? duration : position + 3000;
            controller.seekTo(newPosition);
            notifyPlayerPosition(newPosition, duration);
          }
          break;
        case _MediaControl.rwd:
          int duration = controller.videoFile?.info?.duration;
          int position = await controller.currentPosition();
          if (duration != null && position != -1) {
            int newPosition = position - 3000 < 0 ? 0 : position - 3000;
            controller.seekTo(newPosition);
            notifyPlayerPosition(newPosition, duration);
          }
          break;
      }
    }
  }

  /// When the position is changed in the media controller, the action is
  /// realized by the [VideoViewController] to change the position of
  /// the video playback.
  void _onPositionChanged(int position, int duration) async {
    VideoViewController controller = await _controller.future;
    if (controller != null) controller.seekTo(position);
  }
}
