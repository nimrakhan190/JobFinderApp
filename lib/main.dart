import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:job_clone_app/SignupPage/signup_screen.dart';
import 'package:job_clone_app/user_state.dart';
import 'LoginPage/login_screen.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();
  runApp( MyApp());
}
class MyApp extends StatelessWidget {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context,snapshot){
        if(snapshot.connectionState == ConnectionState.waiting){
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.0), // Add horizontal margins
                child: Center(
                  child: Text(
                    'My Job Clone app is being initialized',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Signatra',
                    ),
                    textAlign: TextAlign.center, // Align text in the center
                  ),
                ),
              ),
            ),
          );
        }
        else if(snapshot.hasError){
          print('Error initializing Firebase: ${snapshot.error}');
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text('An error has been occurred',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Signatra',
                  ),),
              ),
            ),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'My Job Clone App',
           theme: ThemeData(
             scaffoldBackgroundColor: Colors.black,
             primarySwatch: Colors.blue,
           ),
          home: UserState(),
        );
      },
    );
  }
}