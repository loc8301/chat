import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_test/body/call_screen.dart';
import 'package:flutter_application_test/body/videocall_screen.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_9.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String userId;

  ChatScreen({required this.userId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<DocumentSnapshot> _userFuture;
  TextEditingController _messageController = TextEditingController();
  CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('messages');

  void initState() {
    super.initState();
    _userFuture = getUserData();
  }

  Future<DocumentSnapshot> getUserData() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  void _sendMessage(String message) {
    _messagesCollection.add({
      'sender': FirebaseAuth.instance.currentUser?.uid,
      'receiver': widget.userId,
      'content': message,
      'timestamp': Timestamp.now(),
    });
    _messageController.clear();
  }

  void _getImageFromGallery() async {
    final picker = ImagePicker();
    // ignore: unused_local_variable
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // Handle image from gallery here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text('Loading...');
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              var userData = snapshot.data!.data();
              if (userData != null) {
                String name = snapshot.data!.get('name');
                String imageUrl = snapshot.data!.get('image_url');

                return _buildUserInfo(name, imageUrl);
              } else {
                return Text('No data available');
              }
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _buildMessageListView(),
            ),
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, String imageUrl) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 20,
            ),
            SizedBox(width: 10),
            Text(
              name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.phone),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CallScreen(
                            userId: widget.userId,
                          )), // Chuyển hướng đến màn hình cuộc gọi
                );
              },
            ),
            SizedBox(width: 10),
            IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VideoCallScreen(
                            userId: widget.userId,
                          )), // Chuyển hướng đến màn hình cuộc gọi video
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesCollection
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<DocumentSnapshot> messages = snapshot.data!.docs.where((msg) {
            return (msg['sender'] == FirebaseAuth.instance.currentUser?.uid &&
                    msg['receiver'] == widget.userId) ||
                (msg['sender'] == widget.userId &&
                    msg['receiver'] == FirebaseAuth.instance.currentUser?.uid);
          }).toList();
          return Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isSentByMe = messages[index]['sender'] ==
                    FirebaseAuth.instance.currentUser?.uid;
                bool isReceivedByMe = messages[index]['receiver'] ==
                    FirebaseAuth.instance.currentUser?.uid;
                return _buildMessageBubble(
                  messages[index]['content'],
                  isSentByMe,
                  isReceivedByMe,
                );
              },
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildMessageBubble(
      String message, bool isSentByMe, bool isReceivedByMe) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ChatBubble(
        clipper: ChatBubbleClipper9(
          type: isSentByMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
        ),
        alignment: isSentByMe ? Alignment.topRight : Alignment.topLeft,
        margin: isSentByMe
            ? EdgeInsets.only(
                top: 8.0,
                bottom: 8.0,
                left: MediaQuery.of(context).size.width * 0.2,
              )
            : EdgeInsets.only(
                top: 8.0,
                bottom: 8.0,
                right: MediaQuery.of(context).size.width * 0.2,
              ),
        backGroundColor: isSentByMe
            ? Color(0xFF5A9FFF)
            : isReceivedByMe
                ? Color(0xFFEAEAEA)
                : Color(0xFFB3E5FC),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: EdgeInsets.all(8.0),
          child: Text(
            message,
            style: TextStyle(
              color: isSentByMe ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _sendMessage(value.trim());
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.attach_file), // Image icon
            onPressed: _getImageFromGallery,
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              String message = _messageController.text.trim();
              if (message.isNotEmpty) {
                _sendMessage(message);
              }
            },
          ),
        ],
      ),
    );
  }
}
