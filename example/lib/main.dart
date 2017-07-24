import 'package:flutter/material.dart';
import 'package:flutter_facebook_connect/flutter_facebook_connect.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FacebookConnect _facebookConnect = new FacebookConnect(const FacebookOptions(
      appId: '<APP_ID>',
      clientSecret: '<CLIENT_SECRET'));

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new RaisedButton(
                  onPressed: () {
                    _facebookConnect.login().then((FacebookOAuthToken token) {
                      debugPrint(token.toMap().toString());
                    });
                  },
                  child: new Text("Facebook Connect")),
              new FlatButton(
                  onPressed: () {
                    _facebookConnect.revoke();
                  },
                  child: new Text("Logout"))
            ],
          ),
        ));
  }
}
