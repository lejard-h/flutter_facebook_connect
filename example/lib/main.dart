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
  FacebookConnect _connect;

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
              new Container(
                child: new Text(
                    _connect?.token != null ? "connected" : "not connected"),
                padding: new EdgeInsets.all(8.0),
              ),
              new FacebookLoginButton(
                  appId: '<APP_ID>',
                  clientSecret: '<CLIENT_SECRET>',
                  scope: [FacebookAuthScope.publicProfile],
                  cookie: false,
                  onConnect: (api, token) {
                    _connect = api;
                    print(token);
                    setState(() {});
                  }),
              new FlatButton(
                  onPressed: () {
                    _connect?.logout();
                    setState(() {});
                  },
                  child: new Text("Logout"))
            ],
          ),
        ));
  }
}
