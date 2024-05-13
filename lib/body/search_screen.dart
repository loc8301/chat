import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _users = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _users.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  void _searchUsers(String query) async {
    if (query.isEmpty) {
      _users.clear();
      setState(() {});
      return;
    }

    QuerySnapshot users = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .get();

    setState(() {
      _users = users.docs;
    });
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        String userId = _users[index].id;
        String name = _users[index]['name'];
        String email = _users[index]['email'];
        String imageUrl = _users[index]['image_url'];
        String phone = _users[index]['phone'];

        return ListTile(
          title: Text(name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(email),
              Text(phone),
            ],
          ),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(imageUrl),
          ),
          onTap: () {
            _navigateToChatScreen(userId);
          },
        );
      },
    );
  }

  void _navigateToChatScreen(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(userId: userId)),
    );
  }
}
