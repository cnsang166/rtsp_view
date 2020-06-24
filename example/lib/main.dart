import 'package:flutter/material.dart';
import 'package:rtspview/rtspview.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  RtspPlayerState state = new RtspPlayerState();
  int _duration = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Center(
              child: Container(
                width: 500,
                height: 500,
                child: Rtspplayer(
//                  keepAspectRatio: false,
                  showMediaController: true,
                  onCreated: (controller) {
                    controller.setVideoSource(
                      'rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov',
                      sourceType: VideoSourceType.network,
                      initTime: 18000,
                    );
                  },
                  onProgress: (position, duration) {
                    _duration = duration;
                  },
                  onPrepared: (controller, videoInfo) {
                    controller.play();
                  },
                  onCompletion: (controller) {},
                ),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            Center(
              child: RaisedButton(
                child: Icon(Icons.play_arrow),
                onPressed: () {
                  state.seekTo(3000, _duration);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
