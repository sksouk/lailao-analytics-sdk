import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LailaoAnalytics {
  LailaoAnalytics({
    required String endpoint,
    required this.project,
    required this.key,
    this.os,
    this.device,
  }) : _events = Uri.parse(
          '${endpoint.replaceFirst(RegExp(r'/$'), '')}/api/events',
        ) {
    _visitor = _loadVisitor();
  }

  final Uri _events;
  final String project;
  final String key;
  final String? os;
  final Future<Map<String, Object>>? device;
  late final Future<String> _visitor;
  static final _random = Random.secure();

  static String _id() => List.generate(
        18,
        (_) => _random.nextInt(256),
      ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  Future<String> _loadVisitor() async {
    final preferences = SharedPreferencesAsync();
    final storageKey = 'lailao-analytics:$project';
    final existing = await preferences.getString(storageKey);
    if (existing != null) return existing;
    final visitor = _id();
    await preferences.setString(storageKey, visitor);
    return visitor;
  }

  Future<void> track(String name, {String page = '', int? durationMs}) async {
    final response = await http
        .post(
          _events,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': _id(),
            'visitor': await _visitor,
            'project': project,
            'key': key,
            'name': name,
            'page': page,
            'platform': 'Flutter',
            if (os != null) 'os': os,
            if (device != null) 'device': await device!,
            if (durationMs != null) 'durationMs': durationMs,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 202) {
      throw StateError('Analytics event rejected (${response.statusCode})');
    }
  }

  Future<void> sessionStart() => track('session_start');

  Future<void> engagement(Duration elapsed) =>
      track('app_engagement', durationMs: elapsed.inMilliseconds);

  Future<void> screenView(String screen) => track('screen_view', page: screen);
}
