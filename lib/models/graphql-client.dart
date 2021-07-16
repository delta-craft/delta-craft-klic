import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

Future<String> getToken() async {
  final storage = new FlutterSecureStorage();

  return await storage.read(key: "token") ?? "";
}

Future<ValueNotifier<GraphQLClient>> getClient() async {
  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink(
    'https://portal.deltacraft.eu/api/graphql',
  );

  final AuthLink authLink = AuthLink(
    getToken: () async => "Mobile ${await getToken()}",
    // OR
    // getToken: () => 'Bearer <YOUR_PERSONAL_ACCESS_TOKEN>',
  );

  final Link link = authLink.concat(httpLink);

  final client = ValueNotifier(
    GraphQLClient(
      link: link,
      // The default store is the InMemoryStore, which does NOT persist to disk
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  return client;
}
