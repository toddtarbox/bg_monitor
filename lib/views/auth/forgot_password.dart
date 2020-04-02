import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:flutter/material.dart';

import 'package:bg_monitor/storage.dart';
import 'package:bg_monitor/users.dart';
import 'package:bg_monitor/views/auth/reset_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => new _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final userService = new UserService();

  String email;

  void submit(BuildContext context) async {
    _formKey.currentState.save();

    String message;
    try {
      await userService.forgotPassword(email);
      Navigator.push(
        context,
        new MaterialPageRoute(builder: (context) => new ResetPasswordScreen(email: email)),
      );
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException' ||
          e.code == 'InvalidParameterException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    if (message != null) {
      final snackBar = new SnackBar(
        content: new Text(message),
        duration: new Duration(seconds: 30),
      );

      Scaffold.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Forgot Password'),
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Container(
            child: new Form(
              key: _formKey,
              child: new ListView(
                children: <Widget>[
                  new ListTile(
                    leading: const Icon(Icons.email),
                    title: new TextFormField(
                      decoration: new InputDecoration(
                          hintText: 'example@gmail.com',
                          labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (String userEmail) {
                        email = userEmail;
                      },
                    ),
                  ),
                  new Container(
                    padding: new EdgeInsets.all(20.0),
                    width: screenSize.width,
                    child: new RaisedButton(
                      child: new Text(
                        'Reset Password',
                        style: new TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        submit(context);
                      },
                      color: Colors.blue,
                    ),
                    margin: new EdgeInsets.only(
                      top: 10.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
