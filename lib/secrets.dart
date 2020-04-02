import 'dart:async' show Future;
import 'dart:convert' show json;
import 'package:flutter/services.dart' show rootBundle;

class Secrets {
  final String apiKey;
  final String baseUrl;

  final String identityPoolId;
  final String awsUserPoolId;
  final String awsClientId;

  Secrets(
      {this.apiKey,
      this.baseUrl,
      this.identityPoolId,
      this.awsUserPoolId,
      this.awsClientId});

  factory Secrets.fromJson(Map<String, dynamic> jsonMap) {
    return new Secrets(
        apiKey: jsonMap["apiKey"],
        baseUrl: jsonMap["baseUrl"],
        identityPoolId: jsonMap["identityPoolId"],
        awsUserPoolId: jsonMap["awsUserPoolId"],
        awsClientId: jsonMap["awsClientId"]);
  }
}

class SecretLoader {
  final String secretPath;

  SecretLoader({this.secretPath});
  Future<Secrets> load() {
    return rootBundle.loadStructuredData<Secrets>(this.secretPath,
        (jsonStr) async {
      final secret = Secrets.fromJson(json.decode(jsonStr));
      return secret;
    });
  }
}
