# flutter_facebook_connect

Facebook Connect for Flutter

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

```dart
final _facebookConnect = new FacebookConnect(const FacebookOptions(
          appId: '<APP_ID>',
          clientSecret: '<CLIENT_SECRET'));

FacebookOAuthToken token = await _facebookConnect.login();
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/lejard-h/flutter_facebook_connect/issues/
