import 'dart:io';

import 'package:deltacraft_klic/main.dart';
import 'package:deltacraft_klic/models/auth_request.dart';
import 'package:deltacraft_klic/models/graphql-client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';

class ConfirmationPage extends StatefulWidget {
  ConfirmationPage(this.client, {Key? key}) : super(key: key);

  final ValueNotifier<GraphQLClient> client;

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  @override
  void initState() {
    super.initState();

    _resolveNotificationToken();
  }

  final updateToken = r"""
    mutation UpdateFcmToken($token: String!) {
      updateFcmToken(token: $token)
    }
  """;

  Future _resolveNotificationToken() async {
    if (Platform.isIOS) {
      final resPerm = await FirebaseMessaging.instance.requestPermission();
      if (resPerm.authorizationStatus != AuthorizationStatus.authorized) return;
    }

    final token = await FirebaseMessaging.instance.getToken();

    if (token == null) return;

    final client = widget.client;

    await client.value.mutate(MutationOptions(
        document: gql(updateToken), variables: {"token": token}));
  }

  final f = new DateFormat('dd.MM.yyyy hh:mm');
  final storage = new FlutterSecureStorage();

  final query = r"""
  query GetLoginSession {
    loginSession {
      id
      ip
      auth
      authRequest
      updated
    }
  }
  """;

  final mutation = r"""
  mutation UpdateLoginSession($confirm: Boolean!) {
    updateLoginSession(confirm: $confirm)
  }
  """;

  Future confirmResolve(
      bool confirm, Future<QueryResult?> Function() refetch) async {
    final client = widget.client;

    final res = await client.value.mutate(MutationOptions(
        document: gql(mutation), variables: {"confirm": confirm}));

    refetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("DeltaCraft Klíč"),
        actions: [
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Tooltip(
                message: "Odhlásit se",
                child: GestureDetector(
                  onTap: () async {
                    await storage.delete(key: "token");
                    await Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(widget.client),
                      ),
                    );
                  },
                  child: Icon(Icons.logout),
                ),
              )),
        ],
      ),
      body: Query(
        options: QueryOptions(
          document: gql(query),
          pollInterval: Duration(seconds: 20),
        ),
        builder: (result,
            {Future<QueryResult> Function(FetchMoreOptions)? fetchMore,
            Future<QueryResult?> Function()? refetch}) {
          if (result.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = result.data?["loginSession"];

          if (data == null) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Není zde nic ke schválení",
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  Text(
                    "Nejprve se zkus připojit na server",
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  ElevatedButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh),
                        Text("Obnovit"),
                      ],
                    ),
                    onPressed: () => refetch!(),
                  ),
                ],
              ),
            );
          }

          final req = AuthRequest.fromJson(data);

          final date = f.format(req.authRequest);

          return Column(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 20.0),
                  child: Column(
                    children: [
                      Text(
                        "Žádost o přihlášení",
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      if (req.auth != null)
                        Text(
                          req.auth! ? "Schváleno" : "Zamítnuto",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      SizedBox(height: 30),
                      Text(
                        "Zažádáno: $date",
                      ),
                      SizedBox(height: 30),
                      Text(
                        "IP adresa: ${req.ip}",
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(),
                            onPressed: () => confirmResolve(false, refetch!),
                            child: Text("Zamítnout"),
                          ),
                          ElevatedButton(
                            style: ButtonStyle(),
                            onPressed: () => confirmResolve(true, refetch!),
                            child: Text("Schválit"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
