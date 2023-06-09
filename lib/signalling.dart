// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lostwithiel/models/activity.dart';

enum RTCIceTransportPolicy {
  all,
  relay,
}

typedef ConnectionStatusCallback = void Function();
typedef MessageReceivedCallback = void Function(Payload payload);

final Map<String, dynamic> configuration = {
  "sdpSemantics": "unified-plan", // plan-b unified-plan Add this line
  "iceServers": [
    {
      "urls": "turn:turn.isense.bio?transport=udp",
      "username": "alice",
      "credential": "xZIWjuPFSI1t6hAus2Dqg4fQZtQ="
    },
  ],
  "bundlePolicy": "balanced",
  "encodedInsertableStreams": false,
  "iceCandidatePoolSize": 1,
};

final Map<String, dynamic> offerSdpConstraints = {
  "mandatory": {
    "OfferToReceiveAudio": false,
    "OfferToReceiveVideo": false,
  },
  "optional": [],
};

class Signaling {
  final ConnectionStatusCallback? onConnectedStatusChanged;
  final MessageReceivedCallback? onMessageReceived;

  Signaling({
    Key? key,
    required this.onConnectedStatusChanged,
    required this.onMessageReceived,
  });

  RTCPeerConnection? _pc;
  String? roomId;
  String? currentRoomText;
  RTCDataChannel? _dataChannel;

  _createDataChanel() async {
    final chanInit = RTCDataChannelInit();
    // ..negotiated = true
    // ..maxRetransmits = 30
    // ..id = 1;

    _dataChannel = await _pc!.createDataChannel('serverless', chanInit);
    _dataChannel?.onDataChannelState = (RTCDataChannelState channelState) {
      print('OFFER DCC state $channelState');
      onConnectedStatusChanged!();
    };

    _dataChannel!.onMessage = (data) {
      final Payload payload = Payload.fromJson(jsonDecode(data.text) as String);
      onMessageReceived!(payload);
    };
  }

  _subscribeDataChanel() {
    _pc!.onDataChannel = (channel) {
      print('subscribed');
      _dataChannel = channel;
      _dataChannel?.onDataChannelState = (RTCDataChannelState channelState) {
        print('ANSWER DCC state $channelState');
        onConnectedStatusChanged!();
      };
      _dataChannel!.onMessage = (data) {
        final Payload payload =
            Payload.fromJson(jsonDecode(data.text) as String);
        onMessageReceived!(payload);
      };
    };
  }

  FirebaseFirestore getFirestore() {
    FirebaseFirestore db = FirebaseFirestore.instance;

    if (!kReleaseMode) {
      print('in dev');
      db.settings = const Settings(
        persistenceEnabled: false,
        sslEnabled: false,
      );
      db.useFirestoreEmulator('localhost', 8080);
    } else {
      print('in prod');
    }
    return db;
  }

  Future<String> createRoom() async {
    FirebaseFirestore db = getFirestore();
    DocumentReference roomRef = db.collection('rooms').doc();

    _pc = await createPeerConnection(configuration, offerSdpConstraints);
    registerPeerConnectionListeners('OFFER');
    // Code for collecting ICE candidates below
    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    _pc?.onIceCandidate = (RTCIceCandidate candidate) {
      print('Got candidate: ${candidate.toMap()}');
      callerCandidatesCollection.add(candidate.toMap());
    };

    await _createDataChanel();

    // Add code for creating a room
    RTCSessionDescription offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    print('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    var roomId = roomRef.id;

    print('New room created with offer. Room ID: $roomId');

    // Listening for remote session description below
    roomRef.snapshots().listen((snapshot) async {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (_pc?.getRemoteDescription() != null && data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );
        var json = jsonEncode(answer.sdp.toString());
        print("Someone tried to connect $json");
        await _pc?.setRemoteDescription(answer);
      }
    });
    // Listening for remote session description above

    // Listen for remote Ice candidates below
    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          print('OFFER Got new remote ICE candidate: ${jsonEncode(data)}');
          _pc!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    return roomId;
  }

  Future<void> joinRoom(String roomId) async {
    FirebaseFirestore db = getFirestore();

    print(roomId);
    DocumentReference roomRef = db.collection('rooms').doc(roomId);
    var roomSnapshot = await roomRef.get();
    print('Got room ${roomSnapshot.exists}');

    if (roomSnapshot.exists) {
      print('Create PeerConnection with configuration: $configuration');
      _pc = await createPeerConnection(configuration);

      registerPeerConnectionListeners('ANSWER');

      // Code for collecting ICE candidates below
      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      _pc!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null) {
          print('onIceCandidate: complete!');
          return;
        }
        print('onIceCandidate: ${candidate.toMap()}');
        calleeCandidatesCollection.add(candidate.toMap());
      };
      // Code for collecting ICE candidate above

      // Code for creating SDP answer below
      var data = roomSnapshot.data() as Map<String, dynamic>;
      print('Got offer $data');
      var offer = data['offer'];
      await _pc?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );

      await _subscribeDataChanel();

      var answer = await _pc!.createAnswer();
      print('Created Answer $answer');

      await _pc!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);

      // Listening for remote ICE candidates below
      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          print(data);
          print('Got new remote ICE candidate: $data');
          _pc!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  void registerPeerConnectionListeners(String whoami) {
    _pc?.onIceGatheringState = (RTCIceGatheringState state) {
      print('ICE gathering state changed: $state');
    };

    _pc?.onConnectionState = (RTCPeerConnectionState state) async {
      print('$whoami Connection state change: $state');
      // await _dataChannel
      //     ?.send(RTCDataChannelMessage(faker.internet.ipv6Address()));
    };

    _pc?.onSignalingState = (RTCSignalingState state) {
      print('Signaling state change: $state');
    };

    _pc?.onAddStream = (MediaStream stream) {
      print("Add remote stream");
    };
  }

  void sendMessage(String message) {
    //https://github.com/flutter-webrtc/flutter-webrtc-demo/blob/master/lib/src/call_sample/data_channel_sample.dart
    // String text =
    //     'Say hello ' + timer.tick.toString() + ' times, from [$_selfId]';
    // _dataChannel
    //     ?.send(RTCDataChannelMessage.fromBinary(Uint8List(timer.tick + 1)));
    _dataChannel?.send(RTCDataChannelMessage(message));
  }
}
