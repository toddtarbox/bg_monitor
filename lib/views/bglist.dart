import 'dart:convert';

import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:bg_monitor/secrets.dart';
import 'package:bg_monitor/storage.dart';
import 'package:bg_monitor/users.dart';
import 'package:bg_monitor/views/auth/login.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BGMonitor extends StatefulWidget {
  BGMonitor({Key key}) : super(key: key);

  @override
  _BGMonitorState createState() => _BGMonitorState();
}

class _BGMonitorState extends State<BGMonitor> {
  final _userService = new UserService();
  User _user;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  List<BGEntry> bgValues;

  Secrets secrets;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  void _init() async {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('launch_background');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    secrets = await SecretLoader(secretPath: 'assets/secrets.json').load();

    final QuickActions quickActions = new QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'reminder') {
        _remind();
      }
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
          type: 'reminder', localizedTitle: 'Send a Reminder', icon: 'plus'),
    ]);

    _user = await _userService.getCurrentUser();

    try {
      if (_user == null) {
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => new LoginScreen()),
        ).then((user) {
          setState(() {
            _user = user;
          });
          _getBGValues();
        });
      } else {
        _getBGValues();
      }
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException') {
        await _userService.signOut();
      }
      throw e;
    }
  }

  @override
  void initState() {
    _init();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final key = new GlobalKey<ScaffoldState>();
    return Scaffold(
      key: key,
      appBar: AppBar(
        title: Text('BG Monitor'),
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _getBGValues,
        child: _bgListView(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _sendBG(context);
        },
        tooltip: 'Send BG',
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _bgListView(BuildContext context) {
    return bgValues == null || bgValues.isEmpty
        ? Center(
            child: Text('No BG Values'),
          )
        : ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: bgValues.length,
            itemBuilder: (context, index) {
              final BGEntry entry = bgValues[index];
              return Card(
                child: ListTile(
                  title: Text(entry.bgValue),
                  subtitle: Text(new DateFormat("h:mm a MM-dd-yyyy")
                      .format(DateTime.parse(entry.bgTimestamp).toLocal())),
                ),
              );
            },
          );
  }

  void _sendBG(BuildContext context) async {
    final int currentBGValue = await _asyncInputDialog(context);
    if (currentBGValue != null) {
      _makePostRequest(currentBGValue);
    }
  }

  Future<Null> _getBGValues() {
    return _makeGetRequest();
  }

  Future<Null> _makePostRequest(int bgValue) async {
    String url = secrets.baseUrl;
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'x-api-key': secrets.apiKey
    };
    Map<String, Object> body = {
      'sender': 'BGMonitor',
      'userId': '${_user.userId}',
      'action': 'post',
      'bg': '$bgValue',
      'receivers': secrets.bolusReceivers //ex: ['+15555555555', '+15555555556']
    };

    Response response =
        await post(url, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 200) {
      _showToast("BG value posted");
    } else {
      _showToast(response.body);
    }

    var scheduledNotificationDateTime = bgValue >= 350
        ? new DateTime.now().add(new Duration(minutes: 30))
        : new DateTime.now().add(new Duration(minutes: 120));
    var notificationMessage = bgValue >= 350
        ? 'Your last BG was over 350. You should test again now.'
        : 'You were last tested 2 hours ago. You should test again now.';
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'bg-monitor', 'BG Monitor', 'BG Monitor Reminders');
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    NotificationDetails platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
        0,
        'BG Monitor Reminder',
        notificationMessage,
        scheduledNotificationDateTime,
        platformChannelSpecifics);
  }

  Future<Null> _remind() async {
    String url = secrets.baseUrl;
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'x-api-key': secrets.apiKey
    };
    Map<String, Object> body = {
      'sender': 'BGMonitor',
      'action': 'remind',
      'receivers': secrets.reminderReceivers //ex: ['+15555555557']
    };

    Response response =
        await post(url, headers: headers, body: jsonEncode(body));
    if (response.statusCode == 200) {
      _showToast("Reminder sent");
    } else {
      _showToast(response.body);
    }
  }

  Future<Null> _makeGetRequest() async {
    String userId = _user.userId;
    String url = secrets.baseUrl + '/$userId';
    Map<String, String> headers = {
      'Content-type': 'application/json',
      'x-api-key': secrets.apiKey
    };

    Response response = await get(url, headers: headers);
    int code = response.statusCode;
    String body = response.body;

    if (code == 200) {
      Map<String, dynamic> contents = jsonDecode(body);

      setState(() {
        bgValues = new List<BGEntry>.from(contents['Items']
            .map((item) => new BGEntry.fromJson(item))
            .toList());
      });
    } else {
      _showToast("Error: " + body);
    }
  }

  Future<int> _asyncInputDialog(BuildContext context) async {
    int bgValue = -1;
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter current BG value'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration:
                    new InputDecoration(labelText: 'BG Value', hintText: '123'),
                keyboardType: TextInputType.number,
                inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  bgValue = int.parse(value);
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Submit'),
              onPressed: () {
                if (bgValue > 0 && bgValue <= 600) {
                  Navigator.of(context).pop(bgValue);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1);
  }

  Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
          )
        ],
      ),
    );
  }
}

class BGEntry {
  String bgValue;
  String bgTimestamp;

  BGEntry({this.bgValue, this.bgTimestamp});

  factory BGEntry.fromJson(Map<String, dynamic> parsedJson) {
    return BGEntry(
        bgValue: parsedJson['bg']['N'],
        bgTimestamp: parsedJson['timestamp']['S']);
  }
}
