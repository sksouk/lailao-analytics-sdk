import 'package:flutter/material.dart';
import 'package:lailao_analytics/lailao_analytics.dart';

final analytics = LailaoAnalytics(project: 'YOUR_PROJECT_ID', key: 'YOUR_SDK_WRITE_KEY');
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  analytics.start();
  runApp(MaterialApp(navigatorObservers: [analytics.navigatorObserver],
    home: const Scaffold(body: Center(child: Text('Lailao Analytics example')))));
}
