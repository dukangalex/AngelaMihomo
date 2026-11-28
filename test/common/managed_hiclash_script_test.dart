import 'dart:convert';
import 'dart:io';

import 'package:angelamihomo/common/common.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:code_forge/script.dart';
import 'package:flutter_test/flutter_test.dart';

import '../plugins/code_forge/support.dart';

/// T95: the bundled managed script is the HiClash full script carried by the
/// upstream managed-scripts mechanism. It must declare the AngelaMihomo
/// compatibility marker, point its rule providers at the project's own
/// data repository (angelamihomo-geo, which mirrors the official
/// MetaCubeX source), and stay off until the user enables it per profile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled managed script is the HiClash script with our marker', () async {
    final content = await ManagedScript.readBundled();
    expect(content, contains('const Compatible_With_AngelaMihomo'));
    expect(content, contains('function main(config, context)'));
    expect(content, contains('const ruleOptionsEnable'));
    expect(ManagedScript.parseVersion(content), matches(RegExp(r'^\d{10}$')));
    // Rule providers come from the project's own data repository,
    // not the upstream MetaCubeX source or a CDN mirror.
    expect(
      content,
      contains(
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geosite-geolocation-cn.mrs',
      ),
    );
    expect(content, isNot(contains('MetaCubeX')));
    expect(content, isNot(contains('fastly.jsdelivr.net/gh/MetaCubeX')));
    expect(content, isNot(contains('cdn.jsdelivr.net/gh/MetaCubeX')));
    // GeoX defaults align with the app's own defaults.
    expect(
      content,
      contains(
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geosite.dat',
      ),
    );
    // Group icons are served from the project's icons repo (T236);
    // kernel UA pins follow the core.
    expect(content, isNot(contains('HiClash@assets-v1')));
    expect(
      content,
      contains(
        'https://raw.githubusercontent.com/dukangalex/angelamihomo-icons/main/icon/svg/',
      ),
    );
    expect(content, contains('mihomo/1.19.34'));
    expect(content, isNot(contains('mihomo/1.19.32')));
  });

  test(
    'every icon referenced by the bundled script is bundled locally',
    () async {
      final content = await ManagedScript.readBundled();
      final pattern = RegExp(
        r'angelamihomo-icons/main/icon/svg/(?:[A-Za-z0-9_.-]+/)?([A-Za-z0-9_.-]+\.svg)',
      );
      final names = {
        for (final match in pattern.allMatches(content)) match.group(1)!,
      };
      expect(names.length, greaterThanOrEqualTo(30));
      // routeIconAsset resolves these URLs by basename against the
      // bundled route_svg set, so every referenced icon must be there.
      for (final name in names) {
        expect(
          File('assets/route_svg/$name').existsSync(),
          isTrue,
          reason: 'assets/route_svg/$name is referenced but missing',
        );
      }
    },
  );

  test(
    'bundled version is the floor and nothing is synced by default',
    () async {
      await ManagedScript.loadBundledVersion();
      // setup.dart re-stamps the version on every build; assert the stamp
      // format and that the floor logic uses it, not one frozen value.
      expect(ManagedScript.bundledVersion, matches(RegExp(r'^\d{10}$')));
      const props = ManagedProps();
      expect(props.syncedVersion, isNull);
      expect(ManagedScript.syncedVersion(props), isNull);
      expect(ManagedScript.version(props), ManagedScript.bundledVersion);
      expect(ManagedScript.isCustom(props), isFalse);
    },
  );

  test('profiles do not run the managed script unless the user enables it', () {
    const profile = Profile(id: 'fresh', autoUpdateDuration: Duration.zero);
    expect(profile.managed, isFalse);
    expect(profile.runsManagedScript, isFalse);
    final optedIn = profile.copyWith(managed: true);
    expect(optedIn.runsManagedScript, isTrue);
  });

  test('the script engine extracts the bundled script options', () async {
    await initEditorNative();
    final content = await ManagedScript.readBundled();
    final decoded =
        json.decode(await extractScriptOptions(script: content)) as Map;
    final options = decoded['options'] as Map;
    expect(options.keys, containsAll(['手动选择', '自动选择', 'AdBlock', 'GitHub']));
    final icons = decoded['icons'] as Map;
    expect(icons['GitHub'], contains('icon/svg/common/GitHub.svg'));
  });

  test('the bundled script transforms a minimal profile end to end', () async {
    await initEditorNative();
    final dir = await Directory.systemTemp.createTemp('hiclash_eval_');
    addTearDown(() => dir.delete(recursive: true));
    final input = File('${dir.path}/input.json')
      ..writeAsStringSync(
        json.encode({
          'port': 7890,
          'mode': 'rule',
          'proxies': [
            {
              'name': 'HK-1',
              'type': 'ss',
              'server': '127.0.0.1',
              'port': 8388,
              'cipher': 'aes-128-gcm',
              'password': 'x',
            },
          ],
          'proxy-groups': <Object?>[],
          'rules': ['MATCH,DIRECT'],
        }),
      );
    final output = File('${dir.path}/output.json');
    await evaluateScriptFile(
      script: await ManagedScript.readBundled(),
      inputPath: input.path,
      outputPath: output.path,
      token: 7,
    );
    final result =
        json.decode(output.readAsStringSync()) as Map<String, dynamic>;
    final groups = (result['proxy-groups'] as List)
        .map((g) => (g as Map)['name'])
        .toList();
    expect(groups, containsAll(['手动选择', '自动选择', 'GitHub', 'AdBlock']));
    final providers = result['rule-providers'] as Map;
    expect(providers, isNotEmpty);
    expect(
      providers.values.map((p) => (p as Map)['url']).join(' '),
      contains(
        'github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/',
      ),
    );
  });

  test('T325 absorption batch 1 lands in the generated config', () async {
    await initEditorNative();
    final dir = await Directory.systemTemp.createTemp('t325_eval_');
    addTearDown(() => dir.delete(recursive: true));
    Map<String, Object?> node(String name, String server) => {
      'name': name,
      'type': 'ss',
      'server': server,
      'port': 8388,
      'cipher': 'aes-128-gcm',
      'password': 'x',
    };
    final input = File('${dir.path}/input.json')
      ..writeAsStringSync(
        json.encode({
          'port': 7890,
          'mode': 'rule',
          'proxies': [
            node('香港 01', '203.0.113.1'),
            node('香港 02', '203.0.113.2'),
            node('美国 01', '203.0.113.3'),
          ],
          'proxy-groups': <Object?>[],
          'rules': ['MATCH,DIRECT'],
        }),
      );
    final output = File('${dir.path}/output.json');
    await evaluateScriptFile(
      script: await ManagedScript.readBundled(),
      inputPath: input.path,
      outputPath: output.path,
      token: 7,
    );
    final result =
        json.decode(output.readAsStringSync()) as Map<String, dynamic>;

    // 动作 20：地区组增产负载均衡子组，成员序在自动选择之后
    final groups = {
      for (final g in result['proxy-groups'] as List)
        (g as Map)['name'] as String: g,
    };
    final hkLb = groups['香港-负载均衡'] as Map;
    expect(hkLb['type'], 'load-balance');
    expect(hkLb['hidden'], isTrue);
    final hkMembers = (groups['香港'] as Map)['proxies'] as List;
    expect(
      hkMembers.sublist(hkMembers.length - 2),
      ['香港-自动选择', '香港-负载均衡'],
    );
    expect(groups['美国-负载均衡'], isNotNull);

    final rules = (result['rules'] as List).cast<String>();
    // 动作 2/18：teg 钉死与微信直连包
    expect(rules, contains('DOMAIN-SUFFIX,teg.tencent-cloud.net,REJECT-DROP'));
    // T330：biliintl/disney 必须排在 geolocation-cn 之前，
    // 否则重叠域名被直连先行截获、按地区解锁的意图落空
    expect(
      rules.indexOf('RULE-SET,biliintl,默认代理'),
      lessThan(rules.indexOf('RULE-SET,geolocation-cn,直连')),
    );
    expect(
      rules.indexOf('RULE-SET,disney,默认代理'),
      lessThan(rules.indexOf('RULE-SET,geolocation-cn,直连')),
    );
    expect(rules, contains('DOMAIN,szlong.weixin.qq.com,直连'));
    expect(rules, contains('DOMAIN-SUFFIX,weixin.qq.com,直连'));
    expect(rules, contains('IP-CIDR,101.226.0.0/16,DIRECT,no-resolve'));
    expect(rules, contains('IP-CIDR,140.207.0.0/16,DIRECT,no-resolve'));
    // 动作 19：进程名直连包（38 条）
    expect(
      rules.where(
        (r) => r.startsWith('PROCESS-NAME-WILDCARD,') && r.endsWith(',直连'),
      ),
      hasLength(38),
    );
    expect(rules, contains('PROCESS-NAME-WILDCARD,*com.icbc*,直连'));
    expect(
      rules,
      contains('PROCESS-NAME-WILDCARD,*com.eg.android.Alipay*,直连'),
    );
    // T336 二版：远控组改按目标判别，tailscale 进程规则与 SRC-IP 死规则已删，
    // Tailscale 基础设施域名与 WireGuard 数据面端口（41641）指向远控工具
    expect(
      rules,
      isNot(contains('PROCESS-NAME-WILDCARD,*tailscale*,远控工具')),
    );
    expect(
      rules,
      isNot(contains('PROCESS-NAME-WILDCARD,*tailscaled*,远控工具')),
    );
    expect(rules, isNot(contains('SRC-IP-CIDR,100.64.0.0/10,默认代理')));
    expect(rules, contains('DOMAIN-SUFFIX,tailscale.com,远控工具'));
    expect(rules, contains('DOMAIN-SUFFIX,tailscale.io,远控工具'));
    expect(rules, contains('DOMAIN-SUFFIX,ts.net,远控工具'));
    expect(
      rules,
      contains(
        'AND,((PROCESS-NAME-WILDCARD,*tailscale*),(DST-PORT,41641)),远控工具',
      ),
    );
    // 动作 7/9/10/11：STUN 补面、SSDP/mDNS、硬编码 DNS 守卫
    expect(rules, contains('AND,((NETWORK,TCP),(DST-PORT,19302-19309)),REJECT'));
    expect(rules, contains(r'DOMAIN-REGEX,^(stun|turn|stuns|turns)\.,REJECT'));
    expect(
      rules,
      contains(
        'AND,((NETWORK,UDP),(DST-PORT,1900),(NOT,((RULE-SET,cn_ip,no-resolve)))),REJECT-DROP',
      ),
    );
    expect(
      rules,
      contains(
        'AND,((NETWORK,UDP),(DST-PORT,53),(NOT,((RULE-SET,cn_ip,no-resolve)))),REJECT-DROP',
      ),
    );

    final dns = result['dns'] as Map;
    // 动作 12/13：引导与直连 DNS 补齐、双栈齐全
    expect(dns['default-nameserver'], hasLength(7));
    expect(dns['default-nameserver'], contains('tls://[2400:3200::1]#DIRECT'));
    expect(
      dns['direct-nameserver'],
      contains('https://doh.pub/dns-query#DIRECT'),
    );
    expect(
      dns['direct-nameserver'],
      contains('https://[2400:3200::1]/dns-query#DIRECT'),
    );
    // T330：引导解析的 IPv6 端点同为国内解析商（DNSPod），无境外端点混入
    expect(
      dns['default-nameserver'],
      contains('tls://[2402:4e00::]#DIRECT'),
    );
    // 动作 3/4 与 respect-rules 定版
    expect(dns['disable-qtype-65'], isTrue);
    expect(dns['direct-nameserver-follow-policy'], isTrue);
    expect(dns['respect-rules'], isFalse);
    // 动作 14/15/16：nameserver-policy 扩表
    final policy = dns['nameserver-policy'] as Map;
    expect(
      policy.keys,
      containsAll([
        'rule-set:cn',
        'rule-set:geolocation-cn',
        'rule-set:bilibili',
        '+.cn',
        '+.gov.cn',
        'geosite:google',
        'geosite:telegram',
        'geosite:geolocation-!cn',
        '+.openai.com',
        '+.claude.ai',
        'recaptcha.google.com',
      ]),
    );
    // 动作 17：fake-ip-filter 三类小批
    final fakeIpFilter = (dns['fake-ip-filter'] as List).cast<String>();
    expect(
      fakeIpFilter,
      containsAll([
        'DOMAIN-SUFFIX,msftconnecttest.com',
        'DOMAIN,captive.apple.com',
        'DOMAIN,connectivitycheck.gstatic.com',
        'DOMAIN-SUFFIX,tplinkwifi.net',
        'DOMAIN-SUFFIX,ts.net',
        'DOMAIN-SUFFIX,pool.ntp.org',
        'DOMAIN,time.cloudflare.com',
      ]),
    );

    // 动作 5/6：hosts 钉址与双栈
    final hosts = result['hosts'] as Map;
    expect(hosts['dns.msftncsi.com'], ['131.107.255.255', 'fd3e:4f5a:5b81::1']);
    expect(hosts['cloudflare-dns.com'], contains('2606:4700:4700::1111'));
    expect(hosts['doh.pub'], contains('2402:4e00::'));
  });

  test('T327 media rule sets land in the generated config', () async {
    await initEditorNative();
    final dir = await Directory.systemTemp.createTemp('t327_eval_');
    addTearDown(() => dir.delete(recursive: true));
    Map<String, Object?> node(String name, String server) => {
      'name': name,
      'type': 'ss',
      'server': server,
      'port': 8388,
      'cipher': 'aes-128-gcm',
      'password': 'x',
    };
    final input = File('${dir.path}/input.json')
      ..writeAsStringSync(
        json.encode({
          'port': 7890,
          'mode': 'rule',
          'proxies': [
            node('香港 01', '203.0.113.1'),
            node('美国 01', '203.0.113.3'),
          ],
          'proxy-groups': <Object?>[],
          'rules': ['MATCH,DIRECT'],
        }),
      );
    final output = File('${dir.path}/output.json');
    await evaluateScriptFile(
      script: await ManagedScript.readBundled(),
      inputPath: input.path,
      outputPath: output.path,
      token: 7,
    );
    final result =
        json.decode(output.readAsStringSync()) as Map<String, dynamic>;

    const mediaSets = [
      'hulu',
      'hbo',
      'amazon',
      'bahamut',
      'abema',
      'bbc',
      'gitlab',
      'instagram',
      'discord',
      'icloud',
    ];

    // Media 聚合组：select 组，成员口径与其它分流组一致
    final groups = {
      for (final g in result['proxy-groups'] as List)
        (g as Map)['name'] as String: g,
    };
    final media = groups['Media'] as Map;
    expect(media['type'], 'select');
    expect(
      (media['proxies'] as List),
      containsAll(['默认代理', '手动选择', '自动选择', '负载均衡', '故障转移']),
    );
    expect(
      media['icon'],
      contains('angelamihomo-icons/main/icon/svg/common/Media.svg'),
    );

    // 十个新集的提供者定义与既有条目同构；提供者总数 40 → 50
    final providers = result['rule-providers'] as Map;
    expect(providers, hasLength(50));
    for (final name in mediaSets) {
      final provider = providers[name] as Map;
      expect(
        provider['url'],
        'https://github.com/dukangalex/angelamihomo-geo/releases/download/geo-data-2026.11/geosite-$name.mrs',
        reason: name,
      );
      expect(provider['path'], './ruleset/$name.mrs', reason: name);
      expect(provider['path-in-bundle'], 'geo/geosite/$name.mrs', reason: name);
      expect(provider['behavior'], 'domain', reason: name);
      expect(provider['format'], 'mrs', reason: name);
    }
    // 微信维持内联过渡，不生成 wechat 提供者
    expect(providers.containsKey('wechat'), isFalse);

    // 十集规则统一指向 Media
    final rules = (result['rules'] as List).cast<String>();
    for (final name in mediaSets) {
      expect(rules, contains('RULE-SET,$name,Media'), reason: name);
    }
  });
}
