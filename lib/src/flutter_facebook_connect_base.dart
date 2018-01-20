// Copyright (c) 2017, lejard_h. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kFacebookConnectTokenKey = "FACEBOOK_CONNECT_TOKEN_KEY";

class FacebookConnect {
  final String appId;
  final String clientSecret;
  final String version;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  static FacebookConnect _instance;

  FacebookOAuthToken get token => _token;

  FacebookConnect._({this.appId, this.clientSecret, this.version});

  factory FacebookConnect(
          {@required String appId,
          @required String clientSecret,
          String version = 'v2.10'}) =>
      _instance ??= new FacebookConnect._(
          appId: appId, clientSecret: clientSecret, version: version);

  /// Log user to Facebook using a webview
  ///
  /// [scope] see available scope in [FacebookAuthScope]
  ///   - more info [here](https://developers.facebook.com/docs/facebook-login/permissions/)
  /// [fullscreen] launch the webview in fullscreen or not on iOS
  /// [storeToken] store [FacebookOAuthToken] or not inside [SharedPreferences]
  Future<FacebookOAuthToken> login({
    bool force = false,
    List<String> scope,
    bool cookie = true,
    bool fullscreen = false,
    bool storeToken = true,
  }) async {
    _token = await getStoredToken();
    if (_shouldRequestCode(force: force)) {
      logout();
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

      String url =
          "https://www.facebook.com/dialog/oauth?client_id=${appId}&redirect_uri=http://localhost:8080/";
      if (scope?.isNotEmpty == true) {
        url += "&scope=${scope.join(",")}";
      }

      // launch url inside webview
      flutterWebviewPlugin.launch(url,
          clearCookies: !cookie, fullScreen: fullscreen);

      _code = await _onCode.first;
      _token = await _requestToken();
      if (storeToken) {
        _storeToken();
      }
      _close();
    }
    return _token;
  }

  void logout() {
    _token = null;
    _storeToken();
    _code = null;
  }

  /// Get the [FacebookOAuthToken] stored inside [SharedPreferences]
  static Future<FacebookOAuthToken> getStoredToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString(_kFacebookConnectTokenKey);
      if (token != null && token.isNotEmpty) {
        return new FacebookOAuthToken.fromMap(JSON.decode(token));
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  ///////////
  //// Private
  ////

  String _code;
  FacebookOAuthToken _token;
  final _onCodeCtrl = new StreamController<String>.broadcast();
  bool _isOpen = false;
  HttpServer _server;
  StreamSubscription _serverListener;

  Future<FacebookOAuthToken> _requestToken() async {
    final http.Response response = await http.get(
        "https://graph.facebook.com/${version}/oauth/access_token?client_id=${appId}&redirect_uri=http://localhost:8080/&client_secret=${clientSecret}&code=$_code");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return new FacebookOAuthToken.fromMap(JSON.decode(response.body));
    }
    //TODO Exception
    return null;
  }

  Future<bool> _storeToken() async {
    if (_token == null) {
      return _storeTokenValue("");
    }
    return _storeTokenValue(JSON.encode(_token.toMap()));
  }

  Future<bool> _storeTokenValue(String value) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(_kFacebookConnectTokenKey, value);
      return await prefs.commit();
    } catch (e) {
      print(e);
    }
    return false;
  }

  bool _shouldRequestCode({bool force = false}) =>
      _token == null || force == true;

  Stream<String> get _onCode => _onCodeCtrl.stream;

  void _close([_]) {
    if (_isOpen) {
      // close server
      _server.close(force: true);
      _serverListener?.cancel();

      flutterWebviewPlugin.close();
    }
    _isOpen = false;
  }

  Future<HttpServer> _createServer() =>
      HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080, shared: true);

  void _listenCode(HttpServer server) {
    _serverListener?.cancel();
    _serverListener = server.listen((HttpRequest request) async {
      final uri = request.uri;
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.HTML.mimeType)
        ..write("");

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

  void dispose() {
    _close();
    _onCodeCtrl.close();
  }
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

class FacebookAuthScope {
  static String get publicProfile => "public_profile";

  static String get userFriends => "user_friends";

  static String get email => "email";

  static String get userAboutMe => "user_about_me";

  static String get userActionsBooks => "user_actions.books";

  static String get userActionsFitness => "user_actions.fitness";

  static String get userActionsMusic => "user_actions.music ";

  static String get userActionsNews => "user_actions.news";

  static String get userActionsVideo => "user_actions.video";

  static String get userBirthday => "user_birthday";

  static String get userEducationHistory => "user_education_history";

  static String get userEvents => "user_events";

  static String get userGamesActivity => "user_games_activity";

  static String get userHometown => "user_hometown";

  static String get userLikes => "user_likes";

  static String get userLocation => "user_location";

  static String get userManagedGroups => "user_managed_groups";

  static String get userPhotos => "user_photos";

  static String get userPosts => "user_posts";

  static String get userRelationships => "user_relationships";

  static String get userRelationshipDetails => "user_relationship_details";

  static String get userReligion_politics => "user_religion_politics";

  static String get userTaggedPlaces => "user_tagged_places";

  static String get userVideos => "user_videos";

  static String get userWebsite => "user_website";

  static String get userWork_history => "user_work_history";

  static String get readCustomFriendlists => "read_custom_friendlists";

  static String get readInsights => "read_insights";

  static String get readAudienceNetworkInsights =>
      "read_audience_network_insights";

  static String get readPageMailboxes => "read_page_mailboxes";

  static String get managePages => "manage_pages";

  static String get publishPages => "publish_pages";

  static String get publishActions => "publish_actions";

  static String get rsvpEvent => "rsvp_event";

  static String get pagesShowList => "pages_show_list";

  static String get pagesManageCta => "pages_manage_cta";

  static String get pagesManageInstantArticles =>
      "pages_manage_instant_articles";

  static String get adsRead => "ads_read";

  static String get adsManagement => "ads_management";

  static String get businessManagement => "business_management";

  static String get pagesMessaging => "pages_messaging";

  static String get pagesMessagingSubscriptions =>
      "pages_messaging_subscriptions";

  static String get pagesMessagingPayments => "pages_messaging_payments";

  static String get pagesMessagingPhoneNumber => "pages_messaging_phone_number";

  static String userActions(String appNamespace) =>
      "user_actions:$appNamespace";
}
