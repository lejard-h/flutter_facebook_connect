# flutter_facebook_connect


**DISCLAIMER**

**No maintenance on this package anymore. Prefer to use [flutter_facebook_login](https://github.com/roughike/flutter_facebook_login)**

Facebook Connect for [Flutter](https://flutter.io)

Easy way to connect users to Facebook inside your application via [OAuth2](https://developers.facebook.com/docs/facebook-login)


## Usage

See configuration for [flutter_webview_plugin](https://github.com/dart-flitter/flutter_webview_plugin)
 
**Redirection Url** need to be `http://localhost:8080`.

#### iOS Configuration

Add following lines to Info.plist

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost:8080</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```
   

#### Dart Code


Using `FacebookConnect` class
```dart
final _facebookConnect = new FacebookConnect(
          appId: '<APP_ID>',
          clientSecret: '<CLIENT_SECRET');

FacebookOAuthToken token = await _facebookConnect.login();
```

Using `FacebookLoginButton` widget
```dart
 new FacebookLoginButton(
          appId: '<APP_ID>',
          clientSecret: '<CLIENT_SECRET>',
          scope: [FacebookAuthScope.publicProfile],
          onConnect: (api, token) {
           ...
          }),
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/lejard-h/flutter_facebook_connect/issues/
