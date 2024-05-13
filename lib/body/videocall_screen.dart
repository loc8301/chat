import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camera_camera/camera_camera.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoCallScreen extends StatefulWidget {
  final String userId;

  VideoCallScreen({required this.userId});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late Future<DocumentSnapshot> _userFuture;
  late List<CameraDescription> cameras;
  RTCPeerConnection? _peerConnection;

  @override
  void initState() {
    super.initState();
    initCamera();
    _userFuture = getUserData();
    _createPeerConnection();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
  }

  Future<DocumentSnapshot> getUserData() async {
    if (widget.userId.isNotEmpty) {
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
    } else {
      // Xử lý trường hợp userId không hợp lệ ở đây
      return Future.error('userId không hợp lệ');
    }
  }

  void _endCall() {
    // Đóng kết nối peer
    _peerConnection?.close();

    // Xóa dữ liệu cuộc gọi từ Firestore
    FirebaseFirestore.instance.collection('calls').doc(widget.userId).delete();

    // Quay lại màn hình trước đó
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
      // Gửi ICE candidate tới peer kia
      FirebaseFirestore.instance
          .collection('calls')
          .doc(widget.userId)
          .collection('candidates')
          .add(candidate.toMap());
    };
    _peerConnection!.onIceConnectionState = (state) {
      // Xử lý các thay đổi trạng thái kết nối ICE
    };
    _peerConnection!.onTrack = (event) {
      // Xử lý khi một track được thêm vào kết nối
    };

    // Lắng nghe ICE candidates từ Firestore
    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.userId)
        .collection('candidates')
        .snapshots()
        .listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          if (docChange.doc.data() != null) {
            dynamic candidateData = docChange.doc.data();
            RTCIceCandidate candidate = RTCIceCandidate(
              candidateData['candidate'],
              candidateData['sdpMid'],
              candidateData['sdpMLineIndex'],
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
              child: Text('Lỗi: ${snapshot.error}'),
            );
          } else {
            if (snapshot.data!.exists) {
              String name = snapshot.data!.get('name');
              String imageUrl =
                  snapshot.data!.get('image_url') ?? 'default_image_url';

              return _buildCallScreen(name, imageUrl);
            } else {
              return Center(child: Text('Không có dữ liệu'));
            }
          }
        },
      ),
    );
  }

  Widget _buildCallScreen(String name, String imageUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Thông tin cuộc gọi video
        Expanded(
          child: Stack(
            children: [
              // Xem trước camera
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: _buildCameraPreview(),
                ),
              ),
              // Thông tin người dùng
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(imageUrl),
                    ),
                    SizedBox(height: 10),
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Đang gọi...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Hành động cuộc gọi video
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.call_end),
                onPressed: _endCall,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview() {
    if (cameras.isEmpty) {
      return Center(child: CircularProgressIndicator());
    } else {
      return CameraCamera(
        onFile: (File file) {},
      );
    }
  }
}
