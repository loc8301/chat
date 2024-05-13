import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_test/body/home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _image;

  Future<void> _signUp() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get user ID
      String userId = userCredential.user!.uid;

      // Upload image if available
      String imageUrl = '';
      if (_image != null) {
        // Upload image to Firebase Storage
        Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('profile_images/${DateTime.now()}.png');
        UploadTask uploadTask = storageReference.putFile(_image!);
        await uploadTask.whenComplete(() async {
          imageUrl = await storageReference.getDownloadURL();
        });
      }

      // Save user info to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'image_url': imageUrl,
      });

      // Navigate to HomeScreen after successful signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
      );
    } catch (e) {
      print("Đăng ký thất bại: $e");
    }
  }

  Future<void> _getImage() async {
    final imagePicker = ImagePicker();
    final image = await imagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (image != null) {
        _image = File(image.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Đăng Ký'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/pngwing.com.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.all(16.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _getImage,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage:
                            _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? Icon(Icons.camera_alt, size: 48)
                            : null,
                      ),
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Tên'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Số điện thoại'),
                    ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _signUp,
                      child: Text('Đăng Ký'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
