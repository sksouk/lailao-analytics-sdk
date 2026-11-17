import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lailao_analytics/lailao_analytics.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    PackageInfo.setMockInitialValues(appName:'Example',packageName:'com.example.app',version:'2.3.4',buildNumber:'42',buildSignature:'');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/device_info'), (_) async => {
      for(final key in ['board','bootloader','brand','device','display','fingerprint','hardware','host','id','manufacturer','model','product','tags','type'])key:'sample',
      'manufacturer':'Google','brand':'google','model':'Pixel 9',
      'isPhysicalDevice':true,'isLowRamDevice':false,'physicalRamSize':8192,'availableRamSize':4096,'freeDiskSize':1000,'totalDiskSize':2000,
      'version':{'baseOS':'Android','codename':'REL','incremental':'1','previewSdkInt':0,'release':'15','sdkInt':35,'securityPatch':'2026-01-01'},
    });
  });
  tearDown(() { debugDefaultTargetPlatformOverride=null; binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/device_info'),null); });
  test('every event includes automatic Android and app metadata; visitor remains stable', () async {
    final requests=<Map<String,dynamic>>[];
    final analytics=LailaoAnalytics(project:'example',key:'test-only',httpClient:MockClient((r)async{requests.add(jsonDecode(r.body));return http.Response('',202);}));
    await analytics.sessionStart();await analytics.screenView('Home');await analytics.engagement(const Duration(seconds:2));
    expect(requests.length,3);
    for(final r in requests){expect(r['os'],'Android');expect(r['device']['osVersion'],'15');expect(r['device']['androidSdk'],35);expect(r['device']['model'],'Google Pixel 9');expect(r['device']['appVersion'],'2.3.4');expect(r['device']['appBuild'],'42');expect(r['device']['locale'],isNotEmpty);expect(r['device']['timezone'],isNotEmpty);}
    expect(requests.map((r)=>r['visitor']).toSet().length,1);
  });
  test('missing metadata plugin still sends events and explicit overrides work', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/device_info'), (_)async=>throw PlatformException(code:'missing'));
    Map<String,dynamic>? payload;
    final analytics=LailaoAnalytics(project:'example',key:'test-only',device:Future.value({'model':'Custom model'}),httpClient:MockClient((r)async{payload=jsonDecode(r.body);return http.Response('',202);}));
    await analytics.screenView('Home');expect(payload!['device']['model'],'Custom model');expect(payload!['device']['appVersion'],'2.3.4');
  });
}
