import 'package:flutter/material.dart';
import 'package:flutter_facebook_connect/flutter_facebook_connect.dart';

typedef OnConnect(FacebookConnect api, FacebookOAuthToken token);

class FacebookLoginButton extends StatefulWidget {
  final FacebookConnect facebookConnect;
  final String text;
  final bool force;
  final OnConnect onConnect;
  final String responseContent;
  final bool fullscreen;
  final bool storeToken;
  final List<String> scope;
  final bool cookie;

  FacebookLoginButton(
      {Key key,
      String appId,
      String clientSecret,
      String version = 'v2.10',
      this.text = "Log in with Facebook",
      this.responseContent = "",
      this.fullscreen = false,
      this.storeToken = true,
      this.scope,
      this.cookie = true,
      this.force,
      this.onConnect})
      : facebookConnect = new FacebookConnect(
            appId: appId, clientSecret: clientSecret, version: version),
        super(key: key);

  @override
  _FacebookLoginButtonState createState() => new _FacebookLoginButtonState();
}

class _FacebookLoginButtonState extends State<FacebookLoginButton> {
  @override
  @override
  Widget build(BuildContext context) {
    var btn = new RaisedButton(
        child: new Container(
            child: new Row(children: <Widget>[
          new Container(
              child: new Image(
                image: new NetworkImage(
                    "https://fr.facebookbrand.com/wp-content/uploads/2016/05/FB-fLogo-Blue-broadcast-2.png"),
              ),
              constraints: new BoxConstraints(maxHeight: 28.0),
              margin: new EdgeInsets.only(right: 8.0)),
          new Text(widget.text, style: new TextStyle(color: Colors.white)),
        ], mainAxisAlignment: MainAxisAlignment.center)),
        onPressed: _onPressed,
        color: new Color.fromARGB(255, 59, 89, 152));

    return new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [btn]);
  }

  _onPressed() async {
    FacebookOAuthToken token = await widget.facebookConnect.login(
        force: widget.force,
        fullscreen: widget.fullscreen,
        scope: widget.scope,
        cookie: widget.cookie,
        storeToken: widget.storeToken);
    if (widget.onConnect != null) {
      widget.onConnect(widget.facebookConnect, token);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.facebookConnect.dispose();
  }
}
