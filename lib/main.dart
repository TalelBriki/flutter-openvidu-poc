import 'package:flutter/material.dart';
import 'package:flutter_openvidu_demo/HexColor.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_openvidu_demo/call_sample.dart';
import 'package:flutter_openvidu_demo/utils/signaling.dart';

import 'package:url_launcher/url_launcher.dart';

import 'utils/signaling.dart';

void main() => runApp(MaterialApp(home: MyHome()));

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => new _MyHomeState();
}

class _MyHomeState extends State<MyHome> {

  bool isOnline = false;
  TextEditingController _textSessionController;
  TextEditingController _textUserNameController;
  TextEditingController _textUrlController;
  TextEditingController _textSecretController;
  TextEditingController _textPortController;
  TextEditingController _textIceServersController;
  bool _sessionInfo=true;
  Signaling _signaling;



  @override
  void initState(){
    super.initState();

    _textSessionController    = TextEditingController();
    _textUserNameController   = TextEditingController();
    _textUrlController        = TextEditingController(text: 'demos.openvidu.io');
    _textSecretController     = TextEditingController(text: 'MY_SECRET');
    _textPortController       = TextEditingController(text: '443');
    _textIceServersController = TextEditingController(text: 'stun.l.google.com:19302');


    _loadSharedPref();
    _liveConn();
  }
  Future<void> _loadSharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _textUrlController.text        = prefs.getString('textUrl')        ?? _textUrlController.text;
    _textSecretController.text     = prefs.getString('textSecret')     ?? _textSecretController.text;
    _textPortController.text       = prefs.getString('textPort')       ?? _textPortController.text;
    _textIceServersController.text = prefs.getString('textIceServers') ?? _textIceServersController.text;
    print('Loaded user inputs value.');
  }
  Future<void> _saveSharedPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('textUrl', _textUrlController.text);
    await prefs.setString('textSecret', _textSecretController.text);
    await prefs.setString('textPort', _textPortController.text);
    await prefs.setString('textIceServers', _textIceServersController.text);
    print('Saved user inputs values.'); 
  }
  Future<void> _liveConn() async{
    await _checkOnline();
    Timer.periodic(Duration(seconds: 5), (timer) async{
      await _checkOnline();
    });
  }
  Future<void> _checkOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (!isOnline) {
          isOnline = true;
          setState(() {});
          print('Online..');
        }
      }
    } on SocketException catch (_) {
      if (isOnline) {
        isOnline = false;
        setState(() {});
        print('..Offline');
      }
    }
  }
  Future<dynamic> _launchStreamHandle(BuildContext context) async{
    {
      _signaling = new Signaling('${_textUrlController.text}:${_textPortController.text}', _textSecretController.text,_textUserNameController.text,_textIceServersController.text,false);
      _sessionInfo=await _signaling.webRtcSessionLookup(sessionId: _textSessionController.text);
// testing if session with given id already exists
      if(!_sessionInfo){
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          _saveSharedPref();
          return CallSampleWidget(
              isWatching:false,
              server: '${_textUrlController.text}:${_textPortController.text}',
              sessionName: _textSessionController.text,
              userName: _textUserNameController.text,
              secret: _textSecretController.text,
              iceServer: _textIceServersController.text );
        })
        );
      }
      else {

        ScaffoldMessenger
            .of(context)
            .showSnackBar(SnackBar(content: Text('Stream id already exits')));
  }
    }
  }


  Future<dynamic> _watchStreamHandle(BuildContext context) async{
    {
      _signaling = new Signaling('${_textUrlController.text}:${_textPortController.text}', _textSecretController.text,_textUserNameController.text,_textIceServersController.text,false);
      _sessionInfo=await _signaling.webRtcSessionLookup(sessionId: _textSessionController.text);
// testing if session with given id already exists
      if(_sessionInfo){
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          _saveSharedPref();
          return CallSampleWidget(
              isWatching:true,
              server: '${_textUrlController.text}:${_textPortController.text}',
              sessionName: _textSessionController.text,
              userName: _textUserNameController.text,
              secret: _textSecretController.text,
              iceServer: _textIceServersController.text );
        })
        );
      }
      else {

        ScaffoldMessenger
            .of(context)
            .showSnackBar(SnackBar(content: Text('Stream id does not exit')));
      }
}
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor:Colors.white,
        appBar: new AppBar(
          backgroundColor: HexColor("e33f0c"),
          title: const Text('Shopchat poc'),
          actions: <Widget>[
            Row(children: <Widget>[
              isOnline ? Image(image: AssetImage('assets/openvidu_logo.png'),fit: BoxFit.fill, width: 35,) :
              Image(image: AssetImage('assets/offline_icon.png'),fit: BoxFit.fill, width: 35,),
            ]),
          ]
        ),

        body: Center(
          child: Container(

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 10),
                    TextField(
                      controller: _textSessionController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                            borderSide:BorderSide(color:HexColor("e33f0c"))),
                        contentPadding: EdgeInsets.all(5),
                        border: OutlineInputBorder(),
                        labelText: 'Session room name',
                        hintText: 'Enter session room name'
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _textUserNameController,
                      decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide:BorderSide(color:HexColor("e33f0c")),
                          ),
                          contentPadding: EdgeInsets.all(5),
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                          hintText: 'Enter Username'
                      ),
                    ),
                    SizedBox(height:30,),
                    Wrap(
                      spacing: 20, // to apply margin in the main axis of the wrap
                      runSpacing: 20,

                      children: [
                        FlatButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right:0.5),
                                child: Text(isOnline ? 'LunchStream' : '   Offline  ',
                                  style: TextStyle(fontSize: 20.0),
                                ),
                              ),
                              Icon(Icons.video_call_sharp,color:Colors.black,size:30,),
                            ],
                          ),
                          textColor: Colors.white,
                          padding: EdgeInsets.all(15.0),
                          shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(50)),
                          color: Colors.green[400],
                          disabledColor: Colors.grey,
                          onPressed: isOnline ? ()  =>_launchStreamHandle(context)
                              : null,
                        ),

                        FlatButton(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right:0.5),
                                child: Text(isOnline ? 'WatchStream' : '   Offline  ',
                                  style: TextStyle(fontSize: 20.0),
                                ),
                              ),
                              Icon(Icons.personal_video_sharp,color:Colors.black,size:30,),
                            ],
                          ),

                          textColor: Colors.white,
                          padding: EdgeInsets.all(15.0),
                          shape: RoundedRectangleBorder(borderRadius:BorderRadius.circular(50)),
                          color: Colors.green[400],
                          disabledColor: Colors.grey,
                          onPressed: isOnline ? () =>_watchStreamHandle(context)
                          : null,
                        ),
                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
