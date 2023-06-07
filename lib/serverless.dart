// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:clipboard/clipboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lostwithiel/signalling.dart';
import 'package:sdp_transform/sdp_transform.dart';

import 'chat_screen.dart';

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black87,
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2.0)),
  ),
);

final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
  foregroundColor: Colors.black87,
  backgroundColor: Colors.grey[300],
  minimumSize: const Size(88, 36),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);

class Serverless extends StatefulWidget {
  const Serverless({Key? key}) : super(key: key);

  @override
  State<Serverless> createState() => _ServerlessState();
}

class _ServerlessState extends State<Serverless> {
  RTCPeerConnection? _pc;
  bool _offer = false;
  bool _waiting = false;
  RTCDataChannel? _dataChannel;
  FirebaseFirestore? firestore;
  final Signaling _signaling = Signaling();
  TextEditingController textEditingController = TextEditingController(text: '');
  String _roomId = '';

  @override
  void initState() {
    super.initState();
  }

  _createDataChanel() async {
    final chanInit = RTCDataChannelInit()..id = 1;
    // ..negotiated = true
    // ..maxRetransmits = 30;

    _dataChannel = await _pc!.createDataChannel('serverless', chanInit);

    RTCDataChannelState dataChannelState;

    _dataChannel?.onDataChannelState = (RTCDataChannelState channelState) {
      dataChannelState = channelState;
      print('connection state $dataChannelState');
    };

    _dataChannel!.onMessage = (data) {
      print(data.toString());
    };
  }

  _subscribeDataChanel() {
    _pc!.onDataChannel = (channel) {
      print('subscribed');
      _dataChannel = channel;
      _dataChannel!.onMessage = (data) {
        print(data.toString());
      };
    };
  }

  _makeConnection() async {
    Map<String, dynamic> configuration = {
      "sdpSemantics": "plan-b", // Add this line
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": false,
        "OfferToReceiveVideo": false,
      },
      "optional": [],
    };

    final pc = await createPeerConnection(configuration, offerSdpConstraints);
    return pc;
  }

  _makeOffer() async {
    await _createDataChanel();
    final offer = await _pc?.createOffer();
    await _pc?.setLocalDescription(offer!);
    _offer = true;
    _pc?.onIceCandidate = (e) async {
      if (e.candidate != null) {
        RTCSessionDescription? offer = await _pc?.getLocalDescription();
        var session = parse(offer!.sdp.toString());
        session.putIfAbsent('candidate', () => e.candidate);
        session.putIfAbsent('sdpMid', () => e.sdpMid);
        session.putIfAbsent('sdpMlineIndex', () => e.sdpMLineIndex);
        FlutterClipboard.copy(
          json.encode(session),
        ).then(
          (value) {
            return ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offer Presence copied'),
              ),
            );
          },
        );
      }
    };

    _pc?.onIceConnectionState = (e) {
      print('$_offer $e');
    };
  }

  _setRemoteDescription() async {
    String jsonString = await FlutterClipboard.paste();
    dynamic session = await jsonDecode(jsonString);

    String sdp = write(session, null);
    RTCSessionDescription description =
        RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    await _pc!.setRemoteDescription(description);
  }

  _createAnswer() async {
    await _subscribeDataChanel();

    final Map<String, dynamic> dcConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };
    RTCSessionDescription description = await _pc!.createAnswer(dcConstraints);
    await _pc!.setLocalDescription(description);

    _pc?.onIceCandidate = (e) async {
      if (e.candidate != null) {
        RTCSessionDescription? answer = await _pc?.getLocalDescription();
        var session = parse(answer!.sdp.toString());
        session.putIfAbsent('candidate', () => e.candidate);
        session.putIfAbsent('sdpMid', () => e.sdpMid);
        session.putIfAbsent('sdpMlineIndex', () => e.sdpMLineIndex);
        FlutterClipboard.copy(
          json.encode(session),
        ).then(
          (value) {
            return ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Answer Presence copied'),
              ),
            );
          },
        );
      }
    };

    _pc?.onIceConnectionState = (e) {
      print('$_offer $e');
    };
  }

  _addCandidate() async {
    String jsonString = await FlutterClipboard.paste();
    dynamic session = await jsonDecode(jsonString);
    dynamic candidate = RTCIceCandidate(
      session['candidate'],
      session['sdpMid'],
      session['sdpMlineIndex'],
    );
    await _pc!.addCandidate(candidate);
  }

  void registerPeerConnectionListeners() {
    _pc?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    _pc?.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state change: $state');
    };

    _pc?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    _pc?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Serverless & Homeless'),
      ),
      body: const ChatScreen(),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Center _center(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 800,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, //Center Row contents horizontally,
              crossAxisAlignment: CrossAxisAlignment.center, //
              children: [
                TextButton(
                  style: raisedButtonStyle,
                  onPressed: () async {
                    final roomId = await _signaling.createRoom();
                    setState(() {
                      _roomId = roomId;
                    });
                  },
                  child: const Text('Announce'),
                ),
                Row(children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Text("ID"),
                  ),
                  Text(_roomId),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: _roomId),
                      ).then(
                        (value) => {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ID copied'),
                            ),
                          )
                        },
                      );
                    },
                  ),
                ]),
              ],
            ),
          ),
          SizedBox(
            //width: 800,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, //Center Row contents horizontally,

              children: [
                SizedBox(
                  width: 228,
                  child: TextField(
                    controller: textEditingController,
                    decoration: InputDecoration(
                      hintText: 'ID',
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            width: 3, color: Colors.black26), //<-- SEE HERE
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          var t = textEditingController.text;
                          _signaling.joinRoom(t);
                        },
                        icon: const Icon(Icons.connect_without_contact),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Serverless',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }
}
