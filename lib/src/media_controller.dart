part of video_view;

/// Internal callback that notifies when a button of the media control is pressed
/// or when the video controller calls a function related to a controller.
typedef _ControlPressedCallback = void Function(_MediaControl control);

/// Media controller widget that draws playback controls over the video widget.
/// This widget controls the visibility of the controls over the widget.

class _MediaController extends StatefulWidget {
  /// Widget on which the media controls are drawn.
  final Widget child;

  /// Determines if the controller should hide automatically.
  final bool autoHide;

  final bool realtime;

  /// The time after which the controller will automatically hide.
  final Duration autoHideTime;

  /// Controller to update the media controller view when the
  /// video controller is used to call a playback function.
  final _MediaControlsController controller;

  /// Callback to notify when a button is pressed in the controller view.
  final _ControlPressedCallback onControlPressed;

  /// Progression callback used to notify when the progression slider
  /// is touched.
  final ProgressionCallback onPositionChanged;

  /// Constructor of the widget.
  const _MediaController({
    Key key,
    @required this.child,
    this.autoHide,
    this.autoHideTime,
    this.realtime,
    this.controller,
    this.onControlPressed,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  _MediaControllerState createState() => _MediaControllerState();
}

/// State of the media controller.
class _MediaControllerState extends State<_MediaController> {
  /// Determinate if the controls are visible or not over the widget.
  bool _visible = true;

  /// Timer to auto hide the controller after a few seconds.
  Timer _autoHideTimer;

  @override
  void initState() {
    super.initState();
    _setAutoHideTimer();
  }

  @override
  void dispose() {
    _cancelAutoHideTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Stack(
          children: <Widget>[
            widget.child,
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleController,
                child: Container(),
              ),
            ),
          ],
        ),
        _buildMediaController(),
      ],
    );
  }

  /// Builds the media controls over the widget in the stack.
  ///
  /// Returns a positioned widget with the controls.
  Widget _buildMediaController() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Offstage(
        child: _MediaControls(
          realtime: widget.realtime,
          controller: widget.controller,
          onControlPressed: widget.onControlPressed,
          onPositionChanged: widget.onPositionChanged,
          onTapped: _onControllerTapped,
        ),
        offstage: !_visible,
      ),
    );
  }

  /// This callback is called when the media controller is tapped.
  void _onControllerTapped() {
    _setAutoHideTimer();
  }

  /// Changes the state of the visibility of the controls and rebuilds
  /// the widget. If [visibility] is set then is used as a new value of
  /// visibility.
  void _toggleController({bool visibility}) {
    setState(() {
      _visible = visibility ?? !_visible;
    });
    _resolveAutoHide();
  }

  /// Resolve if the auto hide timer should be set or cancelled.
  void _resolveAutoHide() {
    bool autoHide = widget.autoHide ?? true;
    if (autoHide) {
      if (_visible)
        _setAutoHideTimer();
      else
        _cancelAutoHideTimer();
    }
  }

  /// Sets the auto hide timer.
  void _setAutoHideTimer() {
    _cancelAutoHideTimer();
    int time = widget.autoHideTime?.inMilliseconds ?? 2000;
    _autoHideTimer = Timer(Duration(milliseconds: time), () {
      _toggleController(visibility: false);
    });
  }

  /// Cancels the auto hide timer.
  void _cancelAutoHideTimer() {
    if (_autoHideTimer != null) {
      _autoHideTimer.cancel();
      _autoHideTimer = null;
    }
  }
}

/// Widget that contains the control buttons of the media controller.
class _MediaControls extends StatefulWidget {
  /// Controller to update the media controller view when the
  /// video controller is used to call a playback function.
  final _MediaControlsController controller;

  /// Callback to notify when a button is pressed in the controller view.
  final _ControlPressedCallback onControlPressed;

  /// Progression callback used to notify when the progression slider
  /// is touched.
  final ProgressionCallback onPositionChanged;

  /// Callback to notify when the widget is tapped.
  final Function onTapped;

  final bool realtime;

  /// Constructor of the widget.
  const _MediaControls({
    Key key,
    this.realtime,
    this.controller,
    this.onControlPressed,
    this.onPositionChanged,
    this.onTapped,
  }) : super(key: key);

  @override
  _MediaControlsState createState() => _MediaControlsState();
}

/// State of the control buttons and slider.
class _MediaControlsState extends State<_MediaControls> {
  /// Determinate if the state is playing and how the play/pause button
  /// is displayed.
  bool _playing = false;

  /// Current progress of the slider.
  double _progress = 0;

  /// Max duration of the slider.
  double _duration = 1000;

  String initPosition = '00:00';
  String totalPosition = '00:00';

  @override
  void initState() {
    super.initState();
    _initMediaController();
  }

  @override
  void dispose() {
    _disposeMediaController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildControlButtons(),
          _buildProgressionBar(),
        ],
      ),
    );
  }

  /// Builds the playback control buttons.
  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildControlButton(
          iconData: Icons.fast_rewind,
          onPressed: _rewind,
        ),
        _buildControlButton(
          iconData: _playing ? Icons.pause : Icons.play_arrow,
          onPressed: _playPause,
        ),
        _buildControlButton(
          iconData: Icons.stop,
          onPressed: _stop,
        ),
        _buildControlButton(
          iconData: Icons.fast_forward,
          onPressed: _forward,
        ),
      ],
    );
  }

  /// Builds the progression bar of the player.
  Widget _buildProgressionBar() {
    return Row(
      children: [
        SizedBox(width: 5),
        Text(
          '$initPosition',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        Expanded(
          child:
              Slider(onChanged: _onSliderPositionChanged, value: _progress, min: 0, max: _duration),
        ),
        Text(
          '$totalPosition',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        SizedBox(width: 5),
      ],
    );
  }

  /// Builds a single control button. Requires the [iconData] to display
  /// the icon and a [onPressed] function to call when the button is pressed.
  Widget _buildControlButton({@required IconData iconData, @required Function onPressed}) {
    return IconButton(
      icon: Icon(iconData, color: Colors.white),
      onPressed: onPressed,
    );
  }

  /// Initializes the media controller if is not null.
  void _initMediaController() {
    if (widget.controller != null) {
      widget.controller.addControlPressedListener(_onControlPressed);
      widget.controller.addPositionChangedListener(_onPositionChanged);
    }
  }

  /// Clear callbacks in the media controller when this view is disposed.
  void _disposeMediaController() {
    if (widget.controller != null) {
      widget.controller.clearControlPressedListener();
      widget.controller.clearPositionChangedListener();
    }
  }

  /// Callback that is called when the controller calls a function and the
  /// control view needs to be updated.
  void _onControlPressed(_MediaControl mediaControl) {
    switch (mediaControl) {
      case _MediaControl.pause:
        setState(() {
          _playing = false;
        });
        break;
      case _MediaControl.play:
        setState(() {
          _playing = true;
        });
        break;
      case _MediaControl.stop:
        setState(() {
          _playing = false;
        });
        break;
      default:
        break;
    }
  }

  /// Callback that is called when the controller notifies that the playback
  /// time has changed and the control view needs to be updated.
  void _onPositionChanged(int position, int duration) {
    setState(() {
      _progress = position > 0 && position <= duration ? position.toDouble() : 0;
      _duration = duration > 0 ? duration.toDouble() : 0;

      _onPositionStringChanged(position, duration);
    });
  }

  // change position string
  void _onPositionStringChanged(int position, int duration) {
    double startmin = 0.0;
    double startsecond = 0.0;
    double endmin = 0.0;
    double endsecond = 0.0;

    setState(() {
      double startvalue = position.toDouble() / 1000;
      double endvalue = duration.toDouble() / 1000;
      startmin = startvalue / 60;
      startsecond = startvalue % 60;

      endmin = endvalue / 60;
      endsecond = endvalue % 60;

      // time string init
      String min = startmin.toInt().toString().padLeft(2, '0');
      String second = startsecond.toInt().toString().padLeft(2, '0');

      String _min = endmin.toInt().toString().padLeft(2, '0');
      String _second = endsecond.toInt().toString().padLeft(2, '0');

      String startStr = min + ':' + second;
      String totalStr = _min + ':' + _second;

      initPosition = startStr;
      totalPosition = totalStr;
    });
  }

  /// Notifies when the slider in the media controller has been touched
  /// and the playback position needs to be updated through the video controller.
  void _onSliderPositionChanged(double position) {
    _onPositionChanged(position.toInt(), _duration.toInt());
    _onPositionStringChanged(position.toInt(), _duration.toInt());
    if (widget.onPositionChanged != null)
      widget.onPositionChanged(position.toInt(), _duration.toInt());
    if (widget.onTapped != null) widget.onTapped();
  }

  /// Notifies when the rewind button in the media controller has been pressed
  /// and the playback position needs to be updated through the video controller.
  void _rewind() {
    _notifyControlPressed(_MediaControl.rwd);
  }

  /// Notifies when the play/pause button in the media controller has been pressed
  /// and the playback state needs to be updated through the video controller.
  void _playPause() async {
    _notifyControlPressed(_playing ? _MediaControl.pause : _MediaControl.play);
  }

  /// Notifies when the stop button in the media controller has been pressed
  /// and the playback state needs to be updated through the video controller.
  void _stop() async {
    _onPositionChanged(0, _duration.toInt());
    _onPositionStringChanged(0, _duration.toInt());
    _notifyControlPressed(_MediaControl.stop);
  }

  /// Notifies when the forward button in the media controller has been pressed
  /// and the playback position needs to be updated through the video controller.
  void _forward() {
    _notifyControlPressed(_MediaControl.fwd);
  }

  void _notifyControlPressed(_MediaControl control) {
    if (widget.onControlPressed != null) widget.onControlPressed(control);
    if (widget.onTapped != null) widget.onTapped();
  }
}

/// Media controller class used to notify when the video controller has
/// changed the playback position/state and the controls view needs to be
/// updated.
class _MediaControlsController {
  /// Control callback that is registered and is used to notify
  /// the video controller updates.
  _ControlPressedCallback _controlPressedCallback;

  /// Position callback that is registered and is used to notify
  /// the video controller updates.
  ProgressionCallback _positionChangedCallback;

  /// Adds callback that receive notifications when the video controller
  /// updates the state.
  void addControlPressedListener(_ControlPressedCallback controlPressedCallback) {
    _controlPressedCallback = controlPressedCallback;
  }

  /// Removes the control pressed callback registered.
  void clearControlPressedListener() {
    _controlPressedCallback = null;
  }

  /// Notifies when the video controller changes the state.
  void notifyControlPressed(_MediaControl mediaControl) {
    if (_controlPressedCallback != null) _controlPressedCallback(mediaControl);
  }

  /// Adds callback that receive notifications when the video controller
  /// updates the position of the playback.
  void addPositionChangedListener(ProgressionCallback positionChangedCallback) {
    _positionChangedCallback = positionChangedCallback;
  }

  /// Removes the position callback registered.
  void clearPositionChangedListener() {
    _positionChangedCallback = null;
  }

  /// Notifies when the video controller changes the playback position.
  void notifyPositionChanged(int position, int duration) {
    if (_positionChangedCallback != null) _positionChangedCallback(position, duration);
  }
}
