import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Explicit events and opt-in lifecycle tracking, with automatic device metadata.
class LailaoAnalytics with WidgetsBindingObserver {
  LailaoAnalytics({
    String endpoint = 'https://analytics.lailaolab.com',
    required this.project,
    required this.key,
    this.os,
    this.device,
    this.onError,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client(),
       _events = Uri.parse(
         '${endpoint.replaceFirst(RegExp(r'/$'), '')}/api/events',
       ) {
    if (project.trim().isEmpty ||
        key.trim().isEmpty ||
        !['http', 'https'].contains(_events.scheme) ||
        _events.host.isEmpty ||
        _events.userInfo.isNotEmpty ||
        _events.hasQuery ||
        _events.hasFragment) {
      throw ArgumentError(
        'Provide a project, SDK write key and HTTP(S) endpoint.',
      );
    }
  }
  final Uri _events;
  final http.Client _http;
  final String project, key;
  final String? os;

  /// Supplied fields override automatic metadata.
  final Future<Map<String, Object>>? device;
  final void Function(Object error)? onError;
  Future<String>? _visitor;
  Future<Map<String, Object>>? _metadata;
  static final _random = Random.secure();
  bool _started = false, _sessionOpen = false;
  Timer? _heartbeat;
  final _foreground = Stopwatch();
  late final NavigatorObserver navigatorObserver = _AnalyticsNavigator(this);
  static String _id() =>
      List.generate(
        18,
        (_) => _random.nextInt(256),
      ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  String? get _os =>
      os ??
      (kIsWeb
          ? 'Web'
          : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'Android',
            TargetPlatform.iOS => 'iOS',
            TargetPlatform.macOS => 'macOS',
            TargetPlatform.windows => 'Windows',
            TargetPlatform.linux => 'Linux',
            _ => null,
          });
  Future<String> _loadVisitor() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = 'lailao-analytics:$project';
    final existing = prefs.getString(storageKey);
    if (existing != null) return existing;
    final id = _id();
    await prefs.setString(storageKey, id);
    return id;
  }

  Future<Map<String, Object>> _collectMetadata() async {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final view = dispatcher.views.firstOrNull;
    final data = <String, Object>{
      'locale': dispatcher.locale.toLanguageTag(),
      'timezone': DateTime.now().timeZoneName,
      if (view != null) 'screenWidth': view.physicalSize.width.round(),
      if (view != null) 'screenHeight': view.physicalSize.height.round(),
      if (view != null) 'pixelRatio': view.devicePixelRatio,
    };
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final info = await DeviceInfoPlugin().androidInfo;
        data.addAll({
          'osVersion': info.version.release,
          'androidSdk': info.version.sdkInt,
          'model': '${info.manufacturer} ${info.model}',
          'manufacturer': info.manufacturer,
          'brand': info.brand,
          'deviceType': info.isPhysicalDevice ? 'physical' : 'emulator',
        });
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        data.addAll({
          'osVersion': info.systemVersion,
          'model': info.modelName,
          'deviceType': info.isPhysicalDevice ? 'physical' : 'simulator',
        });
      }
    } catch (_) {
      /* Missing plugins must not block delivery. */
    }
    try {
      final info = await PackageInfo.fromPlatform();
      data.addAll({'appVersion': info.version, 'appBuild': info.buildNumber});
    } catch (_) {
      /* Partial metadata remains available. */
    }
    if (device != null) {
      try {
        data.addAll(await device!);
      } catch (_) {}
    }
    return data;
  }

  Future<void> track(String name, {String page = '', int? durationMs}) async {
    final response = await _http
        .post(
          _events,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': _id(),
            'visitor': await (_visitor ??= _loadVisitor()),
            'project': project,
            'key': key,
            'name': name,
            'page': page,
            'platform': 'Flutter',
            if (_os != null) 'os': _os,
            'device': await (_metadata ??= _collectMetadata()),
            if (durationMs != null) 'durationMs': durationMs,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 202)
      throw StateError('Analytics event rejected (${response.statusCode})');
  }

  Future<void> sessionStart() => track('session_start');
  Future<void> engagement(Duration elapsed) =>
      track('app_engagement', durationMs: elapsed.inMilliseconds);
  Future<void> screenView(String screen) => track('screen_view', page: screen);
  void _send(Future<void> event) {
    unawaited(
      event.catchError((Object e) {
        onError?.call(e);
      }),
    );
  }

  /// Call once after binding initialization and any consent flow.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    didChangeAppLifecycleState(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  void _flushElapsed() {
    final elapsed = _foreground.elapsedMilliseconds;
    _foreground.reset();
    if (elapsed > 0) _send(engagement(Duration(milliseconds: elapsed)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      if (!_sessionOpen) {
        _sessionOpen = true;
        _send(sessionStart());
      }
      _foreground.start();
      _heartbeat ??= Timer.periodic(
        const Duration(seconds: 60),
        (_) => _flushElapsed(),
      );
    } else {
      _foreground.stop();
      _heartbeat?.cancel();
      _heartbeat = null;
      _flushElapsed();
      if (state != AppLifecycleState.inactive) _sessionOpen = false;
    }
  }

  /// Stop automatic tracking. Explicit methods remain usable.
  void stop() {
    if (!_started) return;
    _foreground.stop();
    _heartbeat?.cancel();
    _heartbeat = null;
    _flushElapsed();
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _sessionOpen = false;
  }
}

class _AnalyticsNavigator extends NavigatorObserver {
  _AnalyticsNavigator(this.analytics);
  final LailaoAnalytics analytics;
  void _view(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (route is PageRoute && name != null && name.isNotEmpty)
      analytics._send(analytics.screenView(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _view(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _view(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _view(newRoute);
}
