import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:deltacraft_klic/pages/confirmation_page.dart';
import 'package:deltacraft_klic/pages/qr_scan_material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'models/colours.dart';
import 'models/graphql-client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'Oznámení o přihlášení', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  final client = await getClient();
  runApp(MyApp(client));
}

class MyApp extends StatelessWidget {
  final ValueNotifier<GraphQLClient> client;

  MyApp(this.client);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DeltaCraft Klíč',
        theme: ThemeData(
          primarySwatch: colourTheme,
          appBarTheme: AppBarTheme(
            brightness: Brightness.dark,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
          textTheme: TextTheme(headline6: TextStyle(color: Colors.black)),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: colourTheme,
          appBarTheme: AppBarTheme(
            brightness: Brightness.dark,
            backgroundColor: primary,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
          // textTheme: TextTheme(
          //   headline6: TextStyle(color: Colors.white),
          //   bodyText1: TextStyle(color: Colors.white),
          //   bodyText2: TextStyle(color: Colors.white),
          // ),
          //scaffoldBackgroundColor: background,
          //cardColor: backgroundNav,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: backgroundNav,
            unselectedItemColor: Colors.white30,
            selectedItemColor: primaryiOS,
          ),
        ),
        themeMode: ThemeMode.system,
        home: HomePage(client),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage(this.client, {Key? key}) : super(key: key);
  final ValueNotifier<GraphQLClient> client;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String s = "";
  final storage = new FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _resolveLoggedIn();
  }

  Future _resolveLoggedIn() async {
    final token = await storage.read(key: "token");

    if (token != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(widget.client),
        ),
      );
      return;
    }

    await _scanQR();
  }

  Future _scanQR() async {
    final result = await Navigator.push<Barcode?>(
      context,
      MaterialPageRoute(
        builder: (context) => ScanCertMaterial(),
      ),
    );

    final code = result?.code ?? "";

    if (code.length != 0) {
      await storage.write(key: "token", value: code);
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(widget.client),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DeltaCraft Klíč"),
      ),
      body: Center(
        child: AnimatedTextKit(
          repeatForever: true,
          animatedTexts: [
            FadeAnimatedText(
              'Navštiv DeltaCraft Portal',
              textStyle: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
              duration: const Duration(seconds: 4),
            ),
            FadeAnimatedText(
              'Otevři nastavení profilu',
              textStyle: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
              duration: const Duration(seconds: 4),
            ),
            FadeAnimatedText(
              'Naskenuj QR kód',
              textStyle: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
              duration: const Duration(seconds: 4),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.qr_code_scanner),
        onPressed: _resolveLoggedIn,
      ),
    );
  }
}
