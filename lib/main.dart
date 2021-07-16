import 'package:deltacraft_klic/pages/confirmation_page.dart';
import 'package:deltacraft_klic/pages/qr_scan_material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'models/colours.dart';
import 'models/graphql-client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      // TODO: Verify token
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Navštiv DeltaCraft Portal',
              style: Theme.of(context).textTheme.headline5,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'Otevři nastavení svého profilu',
              style: Theme.of(context).textTheme.headline5,
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              'Naskenuj QR kód',
              style: Theme.of(context).textTheme.headline5,
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: _scanQR,
              child: Text("Skenovat"),
            ),
          ],
        ),
      ),
    );
  }
}
