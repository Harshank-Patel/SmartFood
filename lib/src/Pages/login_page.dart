import 'package:flutter/material.dart';
import '../widgets.dart';
import '../../main.dart';
import 'package:provider/provider.dart';
import '../authentication.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Theme.of(context).backgroundColor, Colors.white])),
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 50),
                  Image.asset(
                    'assets/logo.png',
                    height: 300,
                    color: Colors.green,
                  ),
                  const Text(
                    "Smartfood",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 64, color: Colors.green),
                  ),
                  const Text(
                    "Grocery Assistant",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.green),
                  ),
                  const SizedBox(height: 100),
                  Consumer<ApplicationState>(
                    builder: (context, appState, _) => Authentication(
                      email: appState.email,
                      loginState: appState.loginState,
                      startLoginFlow: appState.startLoginFlow,
                      verifyEmail: appState.verifyEmail,
                      signInWithEmailAndPassword:
                          appState.signInWithEmailAndPassword,
                      cancelRegistration: appState.cancelRegistration,
                      registerAccount: appState.registerAccount,
                      signOut: appState.signOut,
                    ),
                  ),
                ],
              ),
            )));
  }
}
