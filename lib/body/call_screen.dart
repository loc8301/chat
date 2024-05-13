import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallScreen extends StatefulWidget {
  final String userId;

  CallScreen({required this.userId});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late Future<DocumentSnapshot> _userFuture;
  bool _isMicMuted = false;
  bool _isVolumeMuted = false;
  RTCPeerConnection? _peerConnection;

  @override
  void initState() {
    super.initState();
    _userFuture = getUserData();
    _createPeerConnection();
    _listenForIceCandidates();
  }

  Future<DocumentSnapshot> getUserData() async {
    if (widget.userId.isNotEmpty) {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
    } else {
      return Future.error('Invalid userId');
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
  }

  void _toggleVolume() {
    setState(() {
      _isVolumeMuted = !_isVolumeMuted;
    });
  }

  void _endCall() {
    _peerConnection?.close();
    // Xóa dữ liệu cuộc gọi khi cuộc gọi kết thúc
    FirebaseFirestore.instance.collection('calls').doc(widget.userId).delete();
    Navigator.pop(context);
  }

  void _createPeerConnection() async {
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };
    _peerConnection = await createPeerConnection(configuration);
    _peerConnection!.onIceCandidate = (candidate) {
      FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.userId)
          .collection('candidates')
          .add(candidate.toMap());
    };
    _peerConnection!.onIceConnectionState = (state) {
      // Xử lý các trạng thái kết nối ICE như connected, disconnected, failed, ...
    };
    _peerConnection!.onTrack = (event) {
      // Xử lý khi có track được thêm vào kết nối, ví dụ như video hoặc audio track
    };
  }

  void _startCall() async {
    RTCSessionDescription offer = await _peerConnection!
        .createOffer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
    await _peerConnection!.setLocalDescription(offer);

    // Lưu offer vào Firestore
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .set({'offer': offer.toMap()});
  }

  void _receiveCall(RTCSessionDescription offer) async {
    await _peerConnection!.setRemoteDescription(offer);
    RTCSessionDescription answer = await _peerConnection!
        .createAnswer({'offerToReceiveAudio': 1, 'offerToReceiveVideo': 0});
    await _peerConnection!.setLocalDescription(answer);

    // Gửi answer tới người gọi
    await FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .set({'answer': answer.toMap()});
  }

  void _listenForIceCandidates() {
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          if (docChange.doc.data() != null) {
            RTCIceCandidate candidate = RTCIceCandidate(
              docChange.doc.data()!['candidate'],
              docChange.doc.data()!['sdpMid'],
              docChange.doc.data()!['sdpMLineIndex'],
            );
            _peerConnection!.addCandidate(candidate);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<DocumentSnapshot>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            if (snapshot.data!.exists) {
              String name = snapshot.data!.get('name');
              String imageUrl =
                  snapshot.data!.get('image_url') ?? 'default_image_url';

              return _buildCallScreen(name, imageUrl);
            } else {
              return Center(child: Text('No data available'));
            }
          }
        },
      ),
    );
  }

  Widget _buildCallScreen(String name, String imageUrl) {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0288D1),
                Color(0xFF01579B),
              ],
            ),
          ),
        ),
        // Call Information
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 80,
                backgroundImage: NetworkImage(imageUrl),
              ),
              SizedBox(height: 20),
              Text(
                name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Calling...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
        // Call Actions
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic),
                onPressed: _toggleMic,
                color: Colors.white,
              ),
              IconButton(
                icon: Icon(Icons.call_end),
                onPressed: _endCall,
                color: Colors.white,
              ),
              IconButton(
                icon: Icon(_isVolumeMuted ? Icons.volume_off : Icons.volume_up),
                onPressed: _toggleVolume,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
