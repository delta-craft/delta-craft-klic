import 'package:deltacraft_klic/main.dart';
import 'package:deltacraft_klic/models/graphql-client.dart';
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

          final date = f.format(new DateTime.fromMicrosecondsSinceEpoch(
              data["authRequest"] * 1000));
          final authConfirmed =
              data["auth"] != null ? data["auth"] as bool : false;

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
                      if (data["auth"] != null)
                        Text(
                          authConfirmed ? "Schváleno" : "Zamítnuto",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      SizedBox(height: 30),
                      Text(
                        "Zažádáno: $date",
                      ),
                      SizedBox(height: 30),
                      Text(
                        "IP adresa: ${data["ip"]}",
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
