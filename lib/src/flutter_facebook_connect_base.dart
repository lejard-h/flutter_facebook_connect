// Copyright (c) 2017, lejard_h. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacebookConnect {
  final String _facebookConnectTokenKey = "FACEBOOK_CONNECT_TOKEN_KEY";
  final FacebookOptions options;
  final String responseContent;
  final bool fullscreen;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  FacebookConnect(this.options,
      {this.responseContent = "", this.fullscreen = false});

  Future<FacebookOAuthToken> login({bool force = false}) async {
    if (force == false) {
      _token = await _getStoredToken();
    }

    if (_shouldRequestCode(force: force)) {
      revoke();
      // close any open browser (happen on hot reload)
      await flutterWebviewPlugin.close();
      _isOpen = true;

      // init server
      _server = await _createServer();
      _listenCode(_server);

      // catch onDestroy event of WebView
      flutterWebviewPlugin.onDestroy.first.then((_) {
        _close();
      });

      flutterWebviewPlugin.onBackPressed.first.then((_) {
        _close();
      });

      String url = "https://www.facebook.com/dialog/oauth?client_id=${options
          .appId}&redirect_uri=http://localhost:8080/";
      if (options.scope != null) {
        url += "&scope=${options
            .scope}";
      }


      // launch url inside webview
      flutterWebviewPlugin.launch(
          url,
          clearCookies: !options.cookie,
          fullScreen: fullscreen);

      _code = await _onCode.first;
      _close();
      _token = await _getToken();
      _storeToken();
    }
    return _token;
  }

  void revoke() {
    _token = null;
    _storeToken();
    _code = null;
  }

  ///////////
  //// Private
  ////

  String _code;
  FacebookOAuthToken _token;
  StreamController<String> _onCodeCtrl;
  bool _isOpen = false;
  HttpServer _server;
  Stream<String> _onCodeStream;

  Future<FacebookOAuthToken> _getStoredToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(_facebookConnectTokenKey);
      if (token != null && token.isNotEmpty) {
        return new FacebookOAuthToken.fromMap(JSON.decode(token));
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future _storeToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(_facebookConnectTokenKey, _token != null ? JSON.encode(_token.toMap()) : null);
      await prefs.commit();
    } catch (e) {
      print(e);
    }
  }

  Future<FacebookOAuthToken> _getToken() async {
    final http.Response response = await http.get(
        "https://graph.facebook.com/${options
            .version}/oauth/access_token?client_id=${options
            .appId}&redirect_uri=http://localhost:8080/&client_secret=${options
            .clientSecret}&code=$_code");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return new FacebookOAuthToken.fromMap(JSON.decode(response.body));
    }
    //TODO Exception
    return null;
  }

  bool _shouldRequestCode({bool force = false}) => force || _token == null;

  Stream<String> get _onCode =>
      _onCodeStream ??= _onCodeCtrl.stream.asBroadcastStream();

  void _close([_]) {
    if (_isOpen) {
      // close server
      _server.close(force: true);
      _onCodeCtrl.close();

      flutterWebviewPlugin.close();
    }
    _isOpen = false;
  }

  Future<HttpServer> _createServer() async {
    final server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080,
        shared: true);
    return server;
  }

  _listenCode(HttpServer server) {
    _onCodeCtrl = new StreamController();
    server.listen((HttpRequest request) async {
      final uri = request.uri;
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.HTML.mimeType)
        ..write(responseContent);

      final String code = request.uri.queryParameters["code"];
      final error = uri.queryParameters["error"];
      await request.response.close();
      if (code != null && error == null) {
        _onCodeCtrl.add(code);
      } else if (error != null) {
        _onCodeCtrl.add(null);
        _onCodeCtrl.addError(error);
      }
    });
  }
}

class FacebookOptions {
  final String appId;
  final String scope;
  final bool cookie;
  final String clientSecret;

  //final bool xfbml;
  final String version;

  const FacebookOptions(
      {@required this.appId, @required this.clientSecret, this.version = 'v2.10', this.scope, this.cookie = false});
}

class FacebookOAuthToken {
  final String access;
  final String type;
  final num expiresIn;

  FacebookOAuthToken(this.access, this.type, this.expiresIn);

  FacebookOAuthToken.fromMap(Map<String, dynamic> json)
      : access = json['access_token'],
        type = json['token_type'],
        expiresIn = json['expires_in'];

  Map toMap() =>
      {'access_token': access, 'token_type': type, 'expires_in': expiresIn};
}
