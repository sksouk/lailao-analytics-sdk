# Lailao Analytics for Flutter

Explicit screen, session and engagement event tracking for Lailao Analytics.

## Install (after the first pub.dev release)

```sh
flutter pub add lailao_analytics
```

Or add `lailao_analytics: ^0.1.0` to dependencies and run `flutter pub get`.
Before publication use a local `path:` dependency for testing.

```dart
import 'package:flutter/widgets.dart';
import 'package:lailao_analytics/lailao_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final analytics = LailaoAnalytics(
    endpoint: 'https://analytics.lailaolab.com',
    project: 'YOUR_PROJECT_ID',
    key: 'YOUR_SDK_WRITE_KEY',
    os: 'iOS', // or Android; optional
  );
  await analytics.sessionStart();
  await analytics.screenView('Home');
  // Launch your app; handle tracking errors without interrupting navigation.
}
```

Use project ID and SDK write key from your workspace. The key only permits event
ingestion; do not embed Google client secrets or dashboard credentials. Android
apps require the INTERNET permission in their release AndroidManifest.xml.

Use `screenView` after navigation. Call `engagement(elapsed)` with actual
foreground time measured by your app. This package does not install lifecycle
observers, automatic routing, or device collection. `device` optionally accepts a
`Future<Map<String, Object>>` containing your supported device metadata.

Events include a random project-scoped visitor ID persisted using
shared_preferences, event name, screen, Flutter platform, optional OS/device
metadata and measured duration. The server observes IP. Inform users and request
consent where required. Avoid personal data in screen/event names. Network
failures throw; callers should catch them. Requests time out after ten seconds;
there is no background retry queue.

Supported Flutter platforms depend on shared_preferences. Requires Dart 3.4+
and Flutter 3.22+. License: MIT.
