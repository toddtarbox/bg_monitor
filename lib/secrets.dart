import 'dart:async' show Future;
import 'dart:convert' show json;
import 'package:flutter/services.dart' show rootBundle;

class Secrets {
  final String apiKey;
  final String baseUrl;

  final String identityPoolId;
  final String awsUserPoolId;
  final String awsClientId;

  final List<dynamic> bolusReceivers;
  final List<dynamic> reminderReceivers;

  Secrets(
      {this.apiKey,
      this.baseUrl,
      this.identityPoolId,
      this.awsUserPoolId,
      this.awsClientId,
      this.bolusReceivers,
      this.reminderReceivers});

  factory Secrets.fromJson(Map<Object, dynamic> jsonMap) {
    return new Secrets(
        apiKey: jsonMap["apiKey"],
        baseUrl: jsonMap["baseUrl"],
        identityPoolId: jsonMap["identityPoolId"],
        awsUserPoolId: jsonMap["awsUserPoolId"],
        awsClientId: jsonMap["awsClientId"],
        bolusReceivers: jsonMap["bolusReceivers"],
        reminderReceivers: jsonMap["reminderReceivers"]);
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
