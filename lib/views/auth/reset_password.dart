import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:flutter/material.dart';

import 'package:bg_monitor/keys.dart';
import 'package:bg_monitor/storage.dart';
import 'package:bg_monitor/users.dart';

class ResetPasswordScreen extends StatefulWidget {
  ResetPasswordScreen({Key key, this.email}) : super(key: key);

  final String email;

  @override
  _ResetPasswordScreenState createState() => new _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final userService = new UserService();

  String email;
  String verificationCode;
  String newPassword;

  void submit(BuildContext context) async {
    _formKey.currentState.save();

    String message;
    bool passwordReset = false;
    try {
      passwordReset = await userService.confirmPassword(email, verificationCode, newPassword);
      if (passwordReset) {
        message = 'Password reset successful!';
      } else {
        message = 'Password rest failed!';
      }
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

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (passwordReset) {
            Keys.navigationKey.currentState.pushReplacementNamed("/home");
          }
        },
      ),
      duration: new Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
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
                      initialValue: widget.email,
                      readOnly: true,
                      onSaved: (String userEmail) {
                        email = userEmail;
                      },
                    ),
                  ),
                  new ListTile(
                    leading: const Icon(Icons.account_box),
                    title: new TextFormField(
                      decoration: new InputDecoration(labelText: 'Verification Code'),
                      onSaved: (String code) {
                        verificationCode = code;
                      },
                    ),
                  ),
                  new ListTile(
                    leading: const Icon(Icons.lock),
                    title: new TextFormField(
                      decoration: new InputDecoration(
                        hintText: 'Password',
                      ),
                      obscureText: true,
                      onSaved: (String password) {
                        newPassword = password;
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
