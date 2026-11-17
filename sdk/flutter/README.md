# Lailao Analytics for Flutter

## 1. Install

```sh
flutter pub add lailao_analytics
```

Version 0.2.0 requires Dart 3.7+ and Flutter 3.29+. Android requires Java 17,
compile SDK 36+, Android Gradle Plugin 8.12.1+ and Gradle 8.13+ through device_info_plus.
Use the stricter requirements of your installed Flutter version.

## 2. Connect

```dart
import 'package:flutter/material.dart';
import 'package:lailao_analytics/lailao_analytics.dart';

final analytics = LailaoAnalytics(
  project: 'YOUR_PROJECT_ID',
  key: 'YOUR_SDK_WRITE_KEY',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  analytics.start();
  runApp(MaterialApp(
    navigatorObservers: [analytics.navigatorObserver],
    home: const HomePage(), // Your application's widget.
  ));
}
```

The default endpoint is `https://analytics.lailaolab.com`. Override `endpoint`
only for your own server/local testing. On a physical phone, localhost refers to
that phone, not your development computer. Android release builds need
`<uses-permission android:name="android.permission.INTERNET" />` in AndroidManifest.xml.

`start()` is opt-in and idempotent: it tracks sessions and actual foreground time.
Call `stop()` when stopping automatic tracking. The navigator observer tracks
named PageRoutes. For Router APIs or unnamed screens, call
`analytics.screenView('Home')` after navigation. Avoid tracking the same screen
both manually and automatically. Existing explicit session/engagement methods
remain available; do not combine them with automatic lifecycle tracking.

Metadata is automatic on every event: Android/iOS OS version, model, device type,
app version/build, locale, timezone and display dimensions/pixel ratio. Android
also includes manufacturer, brand and API level. No hardware identifier, phone
number, contacts or GPS is collected. Missing plugins degrade to partial metadata.
An optional `device` future can override automatic fields.

## 3. Verify

Open your project's SDK setup panel. It polls for the first real event and shows
its timestamp, event name and platform. It does not send synthetic test events.

## Custom events and error handling

```dart
await analytics.track('button_clicked', page: 'Home');
```

Explicit methods throw on failed delivery; catch errors to keep analytics from
interrupting navigation. Automatic tracking reports failures through optional
`onError`. Requests time out after ten seconds. This release does not persist or
retry failed events offline. Obtain any consent your app requires before calling
`start()` or event methods. Visitor IDs are random, project-scoped and stored in
shared_preferences. The SDK key permits collection only, not dashboard access.

License: MIT.
