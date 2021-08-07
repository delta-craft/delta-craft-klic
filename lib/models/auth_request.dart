class AuthRequest {
  DateTime authRequest;
  bool? auth;
  String ip;

  AuthRequest.fromJson(Map<String, dynamic> json)
      : ip = json["ip"],
        authRequest = json["authRequest"] is String
            ? DateTime.parse(json["authRequest"])
            : DateTime.fromMillisecondsSinceEpoch(json["authRequest"]),
        auth = json["auth"];
}
