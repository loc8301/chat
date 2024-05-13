import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_test/auth/forgot_password_screen.dart';
import 'package:flutter_application_test/auth/login_screen.dart';
import 'package:flutter_application_test/auth/signup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Khởi tạo Firebase App
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) =>
            LoginScreen(), // Đặt màn hình đăng nhập là màn hình ban đầu
        '/signup': (context) => SignUpScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
      },
    );
  }
}
