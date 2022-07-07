import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider
import 'package:provider/provider.dart';

// Misc
import 'firebase_options.dart';
import 'src/authentication.dart';
import 'src/widgets.dart';

// Pages
import 'src/Pages/profile_page.dart';
import 'src/Pages/home_page.dart';
import 'src/Pages/login_page.dart';
import 'src/Pages/inventory_page.dart';
import 'src/Pages/APIPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env"); // Load env variables

  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => const App(),
    ),
  );
}

// Themebuilder
class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Meetup',
      theme: ThemeData(
        primaryColor: const Color.fromRGBO(118, 232, 163, 1.0),
        backgroundColor: const Color.fromRGBO(255, 195, 0, 0.6),
        scaffoldBackgroundColor: Colors.white,
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: const Color.fromRGBO(118, 232, 163, 1.0),
            ),
        primarySwatch: CustomColor.generateMaterialColor(
            const Color.fromRGBO(255, 195, 0, 0.75)),
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<ApplicationState>(
        builder: (_, auth, __) =>
            auth.isSignedIn ? const BasicBottomNavBar() : const LoginPage(),
      ),
    );
  }
}

// Auth State
class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  Future<void> init() async {
    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginState = ApplicationLoginState.loggedIn;
      } else {
        _loginState = ApplicationLoginState.loggedOut;
      }

      notifyListeners();
    });
  }

  ApplicationLoginState _loginState = ApplicationLoginState.loggedOut;
  ApplicationLoginState get loginState => _loginState;

  String? _email;
  String? get email => _email;

  bool get isSignedIn => _loginState == ApplicationLoginState.loggedIn;

  void startLoginFlow() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        _loginState = ApplicationLoginState.register;
      }
      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void cancelRegistration() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> registerAccount(
      String email,
      String displayName,
      String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(displayName);

      FirebaseFirestore.instance
          .collection('users')
          .add({
            'uid': credential.user?.uid,
            'name': displayName,
            'email': email
          })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }
}

// NavBar
class BasicBottomNavBar extends StatefulWidget {
  const BasicBottomNavBar({Key? key}) : super(key: key);

  @override
  _BasicBottomNavBarState createState() => _BasicBottomNavBarState();
}

class _BasicBottomNavBarState extends State<BasicBottomNavBar> {
  int _selectedIndex = 1;

  static List<Widget> _pages = <Widget>[
    InventoryPage(),
    HomePage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final user = Provider.of<User>(context);

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('BottomNavigationBar Demo'),
      // ),
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Fixed
        backgroundColor: Colors.black, // <-- This works for fixed
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
