class AuthRequest {
  DateTime authRequest;
  bool? auth;
  String ip;

  AuthRequest.fromJson(Map<String, dynamic> json)
      : ip = json["ip"],
        authRequest =
            DateTime.fromMicrosecondsSinceEpoch(json["authRequest"] * 1000),
        auth = json["auth"];
}
