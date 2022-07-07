import 'package:flutter/material.dart';
import 'package:smartfood/main.dart';
import 'package:provider/provider.dart';
import '../authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutterfire_ui/firestore.dart';

void main() {
  runApp(ProfilePage());
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      backgroundColor: const Color.fromRGBO(255, 195, 0, 0.6),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "${FirebaseAuth.instance.currentUser?.displayName}",
              style: const TextStyle(
                fontSize: 40.0,
                fontFamily: 'Pacifico',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text(
              'SmartFood User',
              style: TextStyle(
                fontSize: 20.0,
                fontFamily: 'SourceSansPro',
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
            SizedBox(
              height: 40.0,
              width: 150,
              child: Divider(
                color: Colors.teal.shade100,
              ),
            ),
            InkWell(
              child: Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 25.0),
                child: ListTile(
                  leading: const Icon(
                    Icons.email,
                    color: Colors.teal,
                  ),
                  title: Text(
                    '${FirebaseAuth.instance.currentUser?.email}',
                    style: TextStyle(
                        fontFamily: 'SourceSansPro',
                        fontSize: 20,
                        color: Colors.teal.shade900),
                  ),
                ),
              ),
            ),
            Consumer<ApplicationState>(
              builder: (context, appState, _) => Authentication(
                email: appState.email,
                loginState: appState.loginState,
                startLoginFlow: appState.startLoginFlow,
                verifyEmail: appState.verifyEmail,
                signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
                cancelRegistration: appState.cancelRegistration,
                registerAccount: appState.registerAccount,
                signOut: appState.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
