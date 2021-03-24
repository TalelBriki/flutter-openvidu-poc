import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:flutter_openvidu_demo/utils/signaling.dart';

import 'main.dart';

class CallSampleWidget extends StatefulWidget {


  CallSampleWidget({Key key,this.isWatching , @required this.server, this.sessionName, this.userName, this.secret, this.iceServer}) : super(key: key);

  final String server;
  final String sessionName;
  final String userName;
  final String secret;
  final String iceServer;
  final bool isWatching;
  @override
  _CallSampleWidgetState createState() => _CallSampleWidgetState();
}

class _CallSampleWidgetState extends State<CallSampleWidget> {

  final _localRenderer = new RTCVideoRenderer();
  final _remoteRenderer = new RTCVideoRenderer();

  Signaling _signaling;

  @override
  void initState() {

    super.initState();
    //_isWatching=false;
    initRenderers();
  }

  Future<void> initRenderers() async {

    await _remoteRenderer.initialize();

    await _localRenderer.initialize();

    _connect();
  }

  void _hangUp() {
    if (_signaling != null) {
      Navigator.of(context).pop();
    }
  }

  void _switchCamera() {
    _signaling.switchCamera();
  }

  void _muteMic() {
    _signaling.muteMic();
  }
  
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: widget.isWatching? Text(widget.userName) : Text("My stream"),
        leading: IconButton(icon: Icon(Icons.arrow_back),onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => MyHome()),
    );
    },

      ),),

      body: OrientationBuilder(builder: (context, orientation) {
        return new Container(
          child: new Stack(children: <Widget>[
            new Positioned(
              left: 0.0,
              right: 0.0,
              top: 0.0,
              bottom: 0.0,
              child: new Container(
                margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: new RTCVideoView(widget.isWatching? _remoteRenderer:_localRenderer),
                decoration: new BoxDecoration(color: Colors.black),
              )
            ),

          ]),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: new SizedBox(
        width: 200.0,
        child:widget.isWatching ? null: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FloatingActionButton(
              child: const Icon(Icons.switch_camera),
              onPressed: _switchCamera,
              heroTag: "btn_switchCamera",
            ),
            FloatingActionButton(
              onPressed: _hangUp,
              heroTag: "btn_hangUp",
              tooltip: 'Hangup',
              child: new Icon(Icons.call_end),
              backgroundColor: Colors.pink,
            ),
            FloatingActionButton(
              child: const Icon(Icons.mic_off),
              onPressed: _muteMic,
              heroTag: "btn_muteMic",
            )
          ]
        )
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _signaling?.close();
    _localRenderer?.dispose();
    _remoteRenderer?.dispose();
    print('◤◢◤◢◤◢◤◢◤◢◤ dispose() ALL ◤◢◤◢◤◢◤◢◤◢◤');
  }

  Future<void> _connect() async {
    
    if (_signaling == null) {

      //_Init Signaling
      _signaling = new Signaling(widget.server, widget.secret, widget.userName, widget.iceServer,widget.isWatching);
//get session

      final bool sessionInfo=await _signaling.webRtcSessionLookup(sessionId: widget.sessionName);
      print('◤◢◤◢◤◢◤◢◤◢◤ session exists: $sessionInfo  ◤◢◤◢◤◢◤◢◤◢◤ ');

      //_Create session
      final String sessionId = await _signaling.createWebRtcSession(sessionId: widget.sessionName);
      print('◤◢◤◢◤◢◤◢◤◢◤ sessionId: $sessionId  ◤◢◤◢◤◢◤◢◤◢◤ ');

      //_Create_token
      final String token = await _signaling.createWebRtcToken(sessionId: sessionId,role: "PUBLISHER");
      print('◤◢◤◢◤◢◤◢◤◢◤ token: $token  ◤◢◤◢◤◢◤◢◤◢◤ ');
    
      //_Connect_socket //ADDED AWAIT
      await _signaling.connect();

      _signaling.onStateChange = (SignalingState state) {
        print('_signaling.onStateChange: $state');
        switch (state) {
          case SignalingState.CallStateNew:
            break;
          case SignalingState.CallStateBye:
            break;
          default:
            break;
        }
      };



      _signaling.onAddRemoteStream = ((stream) {
        print('onAddRemoteStream: ${stream.id}');
        _remoteRenderer.srcObject = stream;
      });
      _signaling.onLocalStream = ((stream) {
        print('onLocalStream: ${stream.id}');
        _localRenderer.srcObject = stream;
      });
      _signaling.onRemoveRemoteStream = ((stream) {
        print('onRemoveRemoteStream');
        _remoteRenderer.srcObject = null;
      });
    }
  }
}
