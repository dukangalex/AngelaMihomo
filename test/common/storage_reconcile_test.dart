import 'dart:io';

import 'package:bett_box/common/storage_reconcile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

// T111 E-02/E-03: the startup sweep removes orphaned profile
// files and temp residue, and nothing else.
void main() {
  late Directory root;
  late Directory profilesDir;
  late String configPath;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('reconcile_test_');
    profilesDir = Directory(p.join(root.path, 'profiles'));
    await profilesDir.create(recursive: true);
    configPath = p.join(root.path, 'config.json');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  Future<File> write(String dir, String name) async {
    final file = File(p.join(dir, name));
    await file.writeAsString('x');
    return file;
  }

  test('removes orphans and residue, keeps referenced files', () async {
    final kept = await write(profilesDir.path, 'known1.yaml');
    await write(profilesDir.path, 'orphan1.yaml');
    await write(profilesDir.path, 'orphan2.yml');
    await write(profilesDir.path, 'known1.yaml.1712345678.tmp');
    await write(profilesDir.path, 'stray.txt');
    final providersDir = Directory(p.join(profilesDir.path, 'providers'));
    await providersDir.create();
    final providerFile = await write(providersDir.path, 'known1.yaml');
    await write(root.path, 'config.json');
    await write(root.path, 'config.json.1712345678.tmp');
    await write(root.path, 'config.json.bak');

    final removed = await reconcileProfileStorage(
      profilesPath: profilesDir.path,
      configPath: configPath,
      knownProfileIds: {'known1'},
    );

    expect(removed, 4);
    expect(await kept.exists(), isTrue);
    expect(await providerFile.exists(), isTrue);
    expect(await File(p.join(profilesDir.path, 'orphan1.yaml')).exists(), isFalse);
    expect(await File(p.join(profilesDir.path, 'orphan2.yml')).exists(), isFalse);
    expect(await File(p.join(profilesDir.path, 'stray.txt')).exists(), isTrue);
    expect(await File(p.join(root.path, 'config.json')).exists(), isTrue);
    expect(await File(p.join(root.path, 'config.json.bak')).exists(), isTrue);
    expect(
      await File(p.join(root.path, 'config.json.1712345678.tmp')).exists(),
      isFalse,
    );
  });

  test('missing directories are a no-op', () async {
    final removed = await reconcileProfileStorage(
      profilesPath: p.join(root.path, 'nope'),
      configPath: p.join(root.path, 'alsono', 'config.json'),
      knownProfileIds: const {},
    );
    expect(removed, 0);
  });
}
