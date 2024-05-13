import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_test/auth/login_screen.dart';
import 'package:flutter_application_test/body/acccout_screen.dart';
import 'package:flutter_application_test/body/search_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DocumentSnapshot> _userFuture;
  late Stream<QuerySnapshot> _usersStream;
  int _selectedIndex = 0; // Index của mục được chọn trong BottomNavigationBar

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _userFuture = getUserData();
    } else {
      // Xử lý trường hợp userId rỗng ở đây
    }

    _usersStream = FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<DocumentSnapshot> getUserData() async {
    return await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _confirmLogout(); // Hiển thị hộp thoại xác nhận
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: FutureBuilder<DocumentSnapshot>(
                future: _userFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    var userData = snapshot.data!.data();
                    if (userData != null) {
                      String name = snapshot.data!.get('name');
                      String imageUrl = snapshot.data!.get('image_url');

                      return _buildUserInfo(name, imageUrl);
                    } else {
                      return Center(child: Text('No data available'));
                    }
                  }
                },
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  List<DocumentSnapshot> usersData = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: usersData.map((user) {
                      var userData = user.data() as Map<String, dynamic>;
                      String name = userData['name'];
                      String imageUrl = userData['image_url'];
                      String userId = user.id;
                      if (userId != widget.userId) {
                        return _buildUserListItem(name, imageUrl, userId);
                      } else {
                        return SizedBox.shrink();
                      }
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Màu của biểu tượng khi được chọn
        unselectedItemColor:
            Colors.black, // Màu của biểu tượng khi không được chọn
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // Điều hướng đến trang chủ
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchScreen(),
          ),
        ); // Điều hướng đến trang tìm kiếm
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AccountScreen(userId: widget.userId),
          ),
        ); // Điều hướng đến trang tài khoản
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildUserInfo(String name, String imageUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
          radius: 50,
        ),
        SizedBox(height: 10),
        Text(
          name,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserListItem(String name, String imageUrl, String userId) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            _deleteUser(userId);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(userId: userId),
            ),
          );
        },
      ),
    );
  }

  void _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm hiển thị hộp thoại xác nhận khi nhấn logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Xác nhận đăng xuất"),
          content: Text("Bạn có muốn đăng xuất không?"),
          actions: <Widget>[
            TextButton(
              child: Text("Không"),
              onPressed: () {
                Navigator.of(context).pop(); // Đóng hộp thoại
              },
            ),
            TextButton(
              child: Text("Có"),
              onPressed: () {
                // Thực hiện hành động đăng xuất ở đây
                Navigator.of(context).pop(); // Đóng hộp thoại
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
          ],
        );
      },
    );
  }
}
