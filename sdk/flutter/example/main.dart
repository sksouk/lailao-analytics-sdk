import 'package:flutter/widgets.dart';
import 'package:lailao_analytics/lailao_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final analytics = LailaoAnalytics(
    endpoint: 'https://analytics.lailaolab.com',
    project: 'YOUR_PROJECT_ID',
    key: 'YOUR_SDK_WRITE_KEY',
  );
  runApp(const Placeholder());
  try {
    await analytics.sessionStart();
    await analytics.screenView('Home');
  } catch (error) {
    debugPrint('Analytics unavailable: $error');
  }
}
