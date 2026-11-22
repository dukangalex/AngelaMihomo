import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Config _config(String label) => Config(
  themeProps: defaultThemeProps,
  profiles: [Profile.normal(label: label)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory home;
  late String path;

  Future<SharedPreferences> prefs() async =>
      (await preferences.sharedPreferencesCompleter.future)!;

  Future<String?> savedLabel([String? target]) async {
    final file = File(target ?? path);
    if (!await file.exists()) return null;
    final config = Config.compatibleFromJson(
      json.decode(await file.readAsString()),
    );
    return config.profiles.firstOrNull?.label;
  }

  setUpAll(() async {
    home = await Directory.systemTemp.createTemp('angelamihomo_preferences_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => home.path,
        );
    SharedPreferences.setMockInitialValues({});
    path = await appPath.appConfigPath;
  });

  tearDownAll(() => home.delete(recursive: true));

  setUp(() async {
    for (final name in [path, '$path.bak']) {
      final file = File(name);
      if (await file.exists()) await file.delete();
    }
    await (await prefs()).clear();
    await preferences.getConfig();
  });

  test('并发保存时最后一次写入胜出', () async {
    final results = await Future.wait([
      for (var index = 0; index < 8; index++)
        preferences.saveConfig(_config('profile-$index')),
    ]);
    expect(results, everyElement(isTrue));
    expect(await savedLabel(), 'profile-7');
    expect(
      home.listSync().where((item) => item.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('内容没变时不重复写盘，文件丢失时补写', () async {
    final config = _config('same');
    await preferences.saveConfig(config);
    final modified = await File(path).lastModified();
    await Future.delayed(const Duration(milliseconds: 20));
    await preferences.saveConfig(config);
    await preferences.saveConfig(config.copyWith());
    expect(await File(path).lastModified(), modified);
    await File(path).delete();
    await preferences.saveConfig(config.copyWith());
    expect(await savedLabel(), 'same');
    await preferences.saveConfig(_config('changed'));
    expect(await savedLabel(), 'changed');
  });

  test('配置文件损坏时回退到启动时备份', () async {
    await preferences.saveConfig(_config('good'));
    expect((await preferences.getConfig())?.profiles.single.label, 'good');
    expect(await savedLabel('$path.bak'), 'good');
    await File(path).writeAsString('{broken');
    final config = await preferences.getConfig();
    expect(config?.profiles.single.label, 'good');
    expect(await savedLabel(), 'good');
  });

  test('旧版镜像只用于恢复，并在写入后清除', () async {
    final store = await prefs();
    await store.setString(configKey, json.encode(_config('legacy')));
    final config = await preferences.getConfig();
    expect(config?.profiles.single.label, 'legacy');
    expect(await savedLabel(), 'legacy');
    expect(store.containsKey(configKey), isFalse);
  });

  test('不再把配置镜像写入 SharedPreferences', () async {
    await preferences.saveConfig(_config('file-only'));
    final store = await prefs();
    expect(store.containsKey(configKey), isFalse);
    expect(store.getBool('autoLaunch'), isFalse);
  });

  group('敏感字段落盘加密（T249）', () {
    Config secretConfig() => Config(
      themeProps: defaultThemeProps,
      appSetting: defaultAppSettingProps.copyWith(
        backupPassword: 'backup-pw',
      ),
      dav: const DAV(
        uri: 'https://dav.example.com',
        user: 'dav-user',
        password: 'dav-pw',
      ),
      profiles: [
        Profile(
          id: 'p1',
          label: 'secret-profile',
          url: 'https://sub.example.com/feed?token=sekrit',
          autoUpdateDuration: const Duration(hours: 24),
        ),
      ],
    );

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      utils.resetSecretKeyCache();
    });

    test('落盘是密文，读回还原明文', () async {
      await preferences.saveConfig(secretConfig());
      final raw = await File(path).readAsString();
      expect(raw, isNot(contains('dav-pw')));
      expect(raw, isNot(contains('dav-user')));
      expect(raw, isNot(contains('backup-pw')));
      expect(raw, isNot(contains('sekrit')));
      expect(raw, contains('ENC2~'));
      final loaded = await preferences.getConfig();
      expect(loaded?.dav?.user, 'dav-user');
      expect(loaded?.dav?.password, 'dav-pw');
      expect(loaded?.appSetting.backupPassword, 'backup-pw');
      expect(
        loaded?.profiles.single.url,
        'https://sub.example.com/feed?token=sekrit',
      );
    });

    test('存量明文配置原样读入', () async {
      await File(path).writeAsString(json.encode(secretConfig()));
      final loaded = await preferences.getConfig();
      expect(loaded?.dav?.password, 'dav-pw');
      expect(loaded?.appSetting.backupPassword, 'backup-pw');
      expect(
        loaded?.profiles.single.url,
        'https://sub.example.com/feed?token=sekrit',
      );
    });

    test('异机密钥解不开的字段置空，配置仍加载', () async {
      await preferences.saveConfig(secretConfig());
      FlutterSecureStorage.setMockInitialValues({});
      utils.resetSecretKeyCache();
      final loaded = await preferences.getConfig();
      expect(loaded, isNotNull);
      expect(loaded?.profiles.single.label, 'secret-profile');
      expect(loaded?.dav?.password, '');
      expect(loaded?.appSetting.backupPassword, '');
      expect(loaded?.profiles.single.url, '');
    });
  });
}
