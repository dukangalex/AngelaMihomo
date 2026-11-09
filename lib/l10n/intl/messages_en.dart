// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(log) => "Analyze Angela Mihomo (Mihomo) log: ${log}";

  static String m1(error) => "Auto backup failed: ${error}";

  static String m2(hours) =>
      "Auto-update is on for this subscription (every ${hours} h, as suggested by the provider). You can change it in the profile settings.";

  static String m3(hours) =>
      "Auto-update is on for this subscription (every ${hours} h). You can change it in the profile settings.";

  static String m4(value) => "Avg ${value}";

  static String m5(count) => "${Intl.plural(count, one: 'day', other: 'days')}";

  static String m6(label) => "Delete selected ${label}?";

  static String m7(label) => "Delete current ${label}?";

  static String m8(reason) => "Fake-IP · ${reason}: returns the real IP";

  static String m9(reason, range) =>
      "Fake-IP · ${reason}: returns a virtual address from ${range}";

  static String m10(ips) => "Matched Hosts: returns ${ips}";

  static String m11(outbound) =>
      "Via \"${outbound}\", the node resolves the domain";

  static String m12(outbound) =>
      "Via \"${outbound}\", the node resolves the domain; Hosts not applied";

  static String m13(label) => "${label} cannot be empty";

  static String m14(label) => "${label} already exists";

  static String m15(count) =>
      "${Intl.plural(count, one: 'hour', other: 'hours')}";

  static String m16(port) => "Port ${port} is already in use. Try another port";

  static String m17(code) => "The server rejected the test (error ${code})";

  static String m18(lost, total) => "${lost}/${total} packets";

  static String m19(name) => "Scanned: ${name}";

  static String m20(value) => "${value} s";

  static String m21(port) => "Listening on port ${port}";

  static String m22(count) => "${count} streams";

  static String m23(count) => "${count}";

  static String m24(count) => "${count} bytes";

  static String m25(address) => "From ${address}";

  static String m26(count) =>
      "Showing the latest ${count}. Copy the result to see all";

  static String m27(min, avg, max, jitter) =>
      "Round trip: min ${min} / avg ${avg} / max ${max} / jitter ${jitter} ms";

  static String m28(target) => "Ping statistics for ${target}";

  static String m29(sent, received, lost, loss) =>
      "Sent ${sent}, received ${received}, lost ${lost} (${loss}% loss)";

  static String m30(level) =>
      "${level} mode is for network debugging; turn it off for daily use";

  static String m31(done, total, unlocked) =>
      "${done}/${total} tested · ${unlocked} available";

  static String m32(count) =>
      "${Intl.plural(count, one: 'minute', other: 'minutes')}";

  static String m33(count) =>
      "${Intl.plural(count, one: 'month', other: 'months')}";

  static String m34(count) => "${count} entries";

  static String m35(ip) => "via ${ip}";

  static String m36(count) => "${count} new logs";

  static String m37(label) => "No ${label}";

  static String m38(min, max) => "Enter a whole number from ${min} to ${max}";

  static String m39(label) => "${label} must be a number";

  static String m40(label) => "Only ${label}";

  static String m41(count) =>
      "${Intl.plural(count, one: '1 area needs attention', other: '${count} areas need attention')}";

  static String m42(count) =>
      "${Intl.plural(count, one: '1 matching log entry', other: '${count} matching log entries')}";

  static String m43(first, last) => "First ${first} · latest ${last}";

  static String m44(stage) => "Live probes put the failure at: ${stage}";

  static String m45(status) =>
      "The server answered, but with error status ${status}. The address was reached; the provider side refused to serve the subscription. An expired, wrong or revoked link answers exactly like this.";

  static String m46(label) =>
      "${label} must be between 1024 and 49151, 0 to disable";

  static String m47(statusCode) =>
      "Failed to import profile. Please check your network status or try resetting the subscription link ( HTTP error code: ${statusCode} )";

  static String m48(index, time) => "Resolved by rule #${index} · ${time} ms";

  static String m49(ips) => "Hosts hit: ${ips}";

  static String m50(total, index) => "${total} rules, matched #${index}";

  static String m51(total) => "${total} rules";

  static String m52(count) => "${count} items selected";

  static String m53(count) =>
      "Multi uses ${count} parallel connections to saturate bandwidth";

  static String m54(provider) =>
      "The outbound may be blocking ${provider} speed tests. Switch the test source or the outbound.";

  static String m55(protocol, fallback) =>
      "${protocol} unavailable, fell back to ${fallback}";

  static String m56(count) => "${count} connections";

  static String m57(provider) => "Switch to ${provider}";

  static String m58(error) =>
      "Could not confirm these settings were applied to the current profile: ${error}";

  static String m59(label) => "${label} must be a URL";

  static String m60(count) =>
      "${Intl.plural(count, one: 'year', other: 'years')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About"),
    "accessControl": MessageLookupByLibrary.simpleMessage("Access Control"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Only route selected apps through VPN",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "App allowlist and blocklist",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "Exclude selected apps from VPN",
    ),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "action": MessageLookupByLibrary.simpleMessage("Action"),
    "action_mode": MessageLookupByLibrary.simpleMessage("Switch Mode"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("System Proxy"),
    "action_start": MessageLookupByLibrary.simpleMessage("Start/Stop"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("Show/Hide"),
    "activeGoroutines": MessageLookupByLibrary.simpleMessage("Goroutines"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "addProfile": MessageLookupByLibrary.simpleMessage("Add Profile"),
    "addRule": MessageLookupByLibrary.simpleMessage("Add Rule"),
    "addTunnel": MessageLookupByLibrary.simpleMessage("Add Forwarding"),
    "addUser": MessageLookupByLibrary.simpleMessage("Add User"),
    "addedOriginRules": MessageLookupByLibrary.simpleMessage(
      "Append to Original Rules",
    ),
    "address": MessageLookupByLibrary.simpleMessage("Address"),
    "addressHelp": MessageLookupByLibrary.simpleMessage(
      "WebDAV server address",
    ),
    "addressTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid WebDAV address",
    ),
    "adminAutoLaunch": MessageLookupByLibrary.simpleMessage(
      "Admin Auto-Launch",
    ),
    "adminAutoLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Auto-start with admin privileges",
    ),
    "advancedSettings": MessageLookupByLibrary.simpleMessage(
      "Advanced Settings",
    ),
    "ageCipherText": MessageLookupByLibrary.simpleMessage(
      "Cipher Text (-----BEGIN AGE ENCRYPTED FILE-----)",
    ),
    "ageDecryptFailed": MessageLookupByLibrary.simpleMessage(
      "Decryption failed",
    ),
    "ageEncryptFailed": MessageLookupByLibrary.simpleMessage(
      "Encryption failed",
    ),
    "ageFileTooLarge": MessageLookupByLibrary.simpleMessage(
      "File too large (8 MB max)",
    ),
    "ageGenerateKeyPair": MessageLookupByLibrary.simpleMessage("New Key Pair"),
    "ageInputRequired": MessageLookupByLibrary.simpleMessage(
      "Enter content or choose a file",
    ),
    "ageKeyGenerateTitle": MessageLookupByLibrary.simpleMessage(
      "Age Key Generation",
    ),
    "ageKeyHybridTip": MessageLookupByLibrary.simpleMessage(
      "Post-quantum hybrid key. Stronger, but the public key is much longer and requires age v1.3 or later.",
    ),
    "ageKeyPairGeneratedSuccess": MessageLookupByLibrary.simpleMessage(
      "X25519 Key pair generated, please keep it safe",
    ),
    "ageKeyType": MessageLookupByLibrary.simpleMessage("Key type"),
    "ageNotEncrypted": MessageLookupByLibrary.simpleMessage(
      "Content is not Age encrypted",
    ),
    "ageOutput": MessageLookupByLibrary.simpleMessage("Result"),
    "agePlainText": MessageLookupByLibrary.simpleMessage("Plain Text"),
    "agePrivateKeyLabel": MessageLookupByLibrary.simpleMessage(
      "Age Private Key",
    ),
    "agePrivateKeyRequired": MessageLookupByLibrary.simpleMessage(
      "Please enter a correct Age private key first",
    ),
    "agePublicKeyLabel": MessageLookupByLibrary.simpleMessage("Age Public Key"),
    "ageRecipientRequired": MessageLookupByLibrary.simpleMessage(
      "Add at least one recipient public key",
    ),
    "ageRecipients": MessageLookupByLibrary.simpleMessage(
      "Recipient Public Keys",
    ),
    "ageRecipientsHint": MessageLookupByLibrary.simpleMessage(
      "One age1… key per line, multiple allowed",
    ),
    "ageSecretKeyInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid Age secret key (must start with AGE-SECRET-KEY-)",
    ),
    "ageSecretKeyOptional": MessageLookupByLibrary.simpleMessage(
      "Age Secret Key (Optional)",
    ),
    "ageTabDecrypt": MessageLookupByLibrary.simpleMessage("Decrypt"),
    "ageTabEncrypt": MessageLookupByLibrary.simpleMessage("Encrypt"),
    "ageTabKeys": MessageLookupByLibrary.simpleMessage("Keys"),
    "ageTool": MessageLookupByLibrary.simpleMessage("Age Encrypt / Decrypt"),
    "ageToolDesc": MessageLookupByLibrary.simpleMessage(
      "Generate keys, encrypt or decrypt text and configs",
    ),
    "ageToolTip": MessageLookupByLibrary.simpleMessage(
      "Everything runs locally. Private keys are never stored or uploaded.",
    ),
    "ageUseForEncrypt": MessageLookupByLibrary.simpleMessage("Use to Encrypt"),
    "ageUseProfileKey": MessageLookupByLibrary.simpleMessage(
      "Use Current Profile Key",
    ),
    "ago": MessageLookupByLibrary.simpleMessage(" ago"),
    "agree": MessageLookupByLibrary.simpleMessage("Agree"),
    "aiApiKey": MessageLookupByLibrary.simpleMessage("API key"),
    "aiConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Optional. Bring your own API key and the patrol page gains an AI interpretation of its report. With no key configured, patrol works fully on-device and nothing is ever sent anywhere.",
    ),
    "aiConfigTitle": MessageLookupByLibrary.simpleMessage(
      "AI interpretation (BYOK)",
    ),
    "aiEndpoint": MessageLookupByLibrary.simpleMessage("API endpoint"),
    "aiError": MessageLookupByLibrary.simpleMessage("AI request failed"),
    "aiGetKey": MessageLookupByLibrary.simpleMessage("Open key console"),
    "aiGroqGuideTitle": MessageLookupByLibrary.simpleMessage("Get an API key"),
    "aiGuideSteps": MessageLookupByLibrary.simpleMessage(
      "1. Open the provider console and sign up (Groq is free and needs no card). 2. Create an API key — it is shown only once, copy it right away. 3. If the provider offers Zero Data Retention (Groq does), turn it on in the console. 4. Paste the key above. The key is stored only on this device and is never included in backups.",
    ),
    "aiInterpret": MessageLookupByLibrary.simpleMessage("AI interpretation"),
    "aiModel": MessageLookupByLibrary.simpleMessage("Model"),
    "aiPatrol": MessageLookupByLibrary.simpleMessage("AI Patrol"),
    "aiPreset": MessageLookupByLibrary.simpleMessage("Provider preset"),
    "aiPreviewDesc": MessageLookupByLibrary.simpleMessage(
      "This is the exact text that will be sent. Node names, addresses and credentials are masked.",
    ),
    "aiPreviewTitle": MessageLookupByLibrary.simpleMessage(
      "Send this to the AI?",
    ),
    "aiResultTitle": MessageLookupByLibrary.simpleMessage("AI interpretation"),
    "aiSend": MessageLookupByLibrary.simpleMessage("Send"),
    "aiTestConnection": MessageLookupByLibrary.simpleMessage("Test connection"),
    "aiTestFailed": MessageLookupByLibrary.simpleMessage("Connection failed"),
    "aiTestOk": MessageLookupByLibrary.simpleMessage("Connection OK"),
    "aiThinking": MessageLookupByLibrary.simpleMessage("Asking the AI…"),
    "aiZdrSettings": MessageLookupByLibrary.simpleMessage(
      "Zero-retention settings",
    ),
    "allApps": MessageLookupByLibrary.simpleMessage("All Apps"),
    "allocatedMemory": MessageLookupByLibrary.simpleMessage("Allocated"),
    "allowBypass": MessageLookupByLibrary.simpleMessage("Allow Bypassing VPN"),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "Allow specific apps to bypass VPN",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("Allow LAN"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage(
      "Allow LAN access to proxy",
    ),
    "alreadyInWhitelist": MessageLookupByLibrary.simpleMessage(
      "Already in whitelist",
    ),
    "alwaysShowTitleBar": MessageLookupByLibrary.simpleMessage("Title Buttons"),
    "alwaysShowTitleBarDesc": MessageLookupByLibrary.simpleMessage(
      "Always show top-right title bar buttons",
    ),
    "analyzeLogPrompt": m0,
    "app": MessageLookupByLibrary.simpleMessage("App"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage(
      "App Access Control",
    ),
    "appDesc": MessageLookupByLibrary.simpleMessage("App-related settings"),
    "appLock": MessageLookupByLibrary.simpleMessage("App lock"),
    "appLockBiometric": MessageLookupByLibrary.simpleMessage("Use biometrics"),
    "appLockBiometricUnavailable": MessageLookupByLibrary.simpleMessage(
      "Biometrics are not available on this device",
    ),
    "appLockConfirmPin": MessageLookupByLibrary.simpleMessage(
      "Enter the PIN again",
    ),
    "appLockDesc": MessageLookupByLibrary.simpleMessage(
      "Require a PIN when opening the app. Only the interface locks — the VPN service keeps running.",
    ),
    "appLockEnterPin": MessageLookupByLibrary.simpleMessage("Enter PIN"),
    "appLockNoRecovery": MessageLookupByLibrary.simpleMessage(
      "There is no PIN recovery. If you forget the PIN, the only way back is clearing the app data.",
    ),
    "appLockPinMismatch": MessageLookupByLibrary.simpleMessage(
      "The two PINs do not match",
    ),
    "appLockRelock": MessageLookupByLibrary.simpleMessage(
      "Re-lock after leaving",
    ),
    "appLockRelock1m": MessageLookupByLibrary.simpleMessage("1 minute"),
    "appLockRelock30s": MessageLookupByLibrary.simpleMessage("30 seconds"),
    "appLockRelock5m": MessageLookupByLibrary.simpleMessage("5 minutes"),
    "appLockRelockImmediate": MessageLookupByLibrary.simpleMessage(
      "Immediately",
    ),
    "appLockSetPin": MessageLookupByLibrary.simpleMessage(
      "Set a PIN (4-6 digits)",
    ),
    "appLockUnlockBiometric": MessageLookupByLibrary.simpleMessage(
      "Unlock with biometrics",
    ),
    "appLockWait": MessageLookupByLibrary.simpleMessage(
      "Too many attempts. Wait a while and try again.",
    ),
    "appLockWrongPin": MessageLookupByLibrary.simpleMessage("Wrong PIN"),
    "application": MessageLookupByLibrary.simpleMessage("Application"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage(
      "Modify application settings",
    ),
    "authorized": MessageLookupByLibrary.simpleMessage("Authorized"),
    "auto": MessageLookupByLibrary.simpleMessage("Auto"),
    "autoBackup": MessageLookupByLibrary.simpleMessage("Auto Backup"),
    "autoBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Auto back up on profile changes",
    ),
    "autoBackupFailed": m1,
    "autoBackupSuccess": MessageLookupByLibrary.simpleMessage(
      "Auto backed up to WebDAV",
    ),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage(
      "Auto Check Updates",
    ),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "Check updates on app launch",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage(
      "Auto-Close Connections",
    ),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "Close connections when switching nodes",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("Auto Launch"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Launch on system startup",
    ),
    "autoRun": MessageLookupByLibrary.simpleMessage("Auto Run"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage(
      "Connect on app launch",
    ),
    "autoScroll": MessageLookupByLibrary.simpleMessage("Auto Scroll"),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage(
      "Auto Set System DNS",
    ),
    "autoStickyHeader": MessageLookupByLibrary.simpleMessage(
      "Auto Sticky Header",
    ),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("Auto Update"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage(
      "Auto update interval (min)",
    ),
    "autoUpdateOnImportTip": m2,
    "autoUpdateOnImportTipDefault": m3,
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "backup": MessageLookupByLibrary.simpleMessage("Backup"),
    "backupAndRecovery": MessageLookupByLibrary.simpleMessage(
      "Backup & Restore",
    ),
    "backupAndRecoveryDesc": MessageLookupByLibrary.simpleMessage(
      "Sync data via WebDAV or locally",
    ),
    "backupEncryptedTip": MessageLookupByLibrary.simpleMessage(
      "Backup encrypted with AES-256",
    ),
    "backupPassword": MessageLookupByLibrary.simpleMessage("Backup Password"),
    "backupPasswordDesc": MessageLookupByLibrary.simpleMessage(
      "AES-256 encrypted, leave blank for none",
    ),
    "backupPasswordRequired": MessageLookupByLibrary.simpleMessage(
      "This backup is encrypted, please enter the password",
    ),
    "backupPasswordTip": MessageLookupByLibrary.simpleMessage(
      "Only English letters, digits and symbols are supported",
    ),
    "backupPasswordWrong": MessageLookupByLibrary.simpleMessage(
      "Incorrect backup password",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("Backup Successful"),
    "basicConfig": MessageLookupByLibrary.simpleMessage("Core Configuration"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage(
      "Global core settings",
    ),
    "batteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Battery Optimization",
    ),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Request battery optimization whitelist",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("Bind"),
    "blacklist": MessageLookupByLibrary.simpleMessage("Blacklist"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("Blacklist Mode"),
    "blockComment": MessageLookupByLibrary.simpleMessage("Comment"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("Bypass Domain"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage(
      "Active only when System Proxy is on",
    ),
    "bypassPrivateRoute": MessageLookupByLibrary.simpleMessage(
      "Bypass Private Network",
    ),
    "bypassPrivateRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Automatically bypass private network IP addresses",
    ),
    "cacheAlgorithm": MessageLookupByLibrary.simpleMessage("Cache Algorithm"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "Cache corrupted. Clear it?",
    ),
    "cameraPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Camera Permission Denied",
    ),
    "cameraPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "Camera permission is required to scan QR codes. Please grant it in settings.",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "cancelFilterSystemApp": MessageLookupByLibrary.simpleMessage(
      "Show System Apps",
    ),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("Deselect All"),
    "categoryAi": MessageLookupByLibrary.simpleMessage("AI"),
    "categoryAll": MessageLookupByLibrary.simpleMessage("All"),
    "categoryChina": MessageLookupByLibrary.simpleMessage("China Direct"),
    "categoryCrypto": MessageLookupByLibrary.simpleMessage("Crypto"),
    "categoryDeveloper": MessageLookupByLibrary.simpleMessage("Developer"),
    "categoryGaming": MessageLookupByLibrary.simpleMessage("Gaming Center"),
    "categorySocial": MessageLookupByLibrary.simpleMessage("Social Platforms"),
    "categoryStreaming": MessageLookupByLibrary.simpleMessage("Streaming"),
    "chainAttention": MessageLookupByLibrary.simpleMessage(
      "Chain settings need attention",
    ),
    "chainChooseOtherProfile": MessageLookupByLibrary.simpleMessage(
      "Choose another profile",
    ),
    "chainChooseTarget": MessageLookupByLibrary.simpleMessage(
      "Choose a proxy or group",
    ),
    "chainEnable": MessageLookupByLibrary.simpleMessage("Enable"),
    "chainEnableDesc": MessageLookupByLibrary.simpleMessage(
      "Choose an entry from this profile and an exit proxy or group from another. After enabling, select the generated chain in a manual group; only traffic using it follows the chain. Source configs stay unchanged.",
    ),
    "chainEntry": MessageLookupByLibrary.simpleMessage("Entry"),
    "chainExit": MessageLookupByLibrary.simpleMessage("Exit"),
    "chainExitProfile": MessageLookupByLibrary.simpleMessage("Exit profile"),
    "chainIssueIncomplete": MessageLookupByLibrary.simpleMessage(
      "Choose both an entry and an exit before enabling the chain.",
    ),
    "chainIssueOtherProfile": MessageLookupByLibrary.simpleMessage(
      "Choose the exit from a different profile.",
    ),
    "chainIssueSameNode": MessageLookupByLibrary.simpleMessage(
      "Entry and exit cannot be the same proxy or group.",
    ),
    "chainIssueUnavailable": MessageLookupByLibrary.simpleMessage(
      "A selected proxy, group, or profile is unavailable. Choose again.",
    ),
    "chainNoEntry": MessageLookupByLibrary.simpleMessage("No entry choices"),
    "chainNoEntryDesc": MessageLookupByLibrary.simpleMessage(
      "The current profile has no available proxies or groups.",
    ),
    "chainNoExitChoices": MessageLookupByLibrary.simpleMessage(
      "No exit choices",
    ),
    "chainNoExitChoicesDesc": MessageLookupByLibrary.simpleMessage(
      "The selected profile has no available proxies or groups.",
    ),
    "chainNoExits": MessageLookupByLibrary.simpleMessage(
      "This profile has no available exits.",
    ),
    "chainNoOtherProfiles": MessageLookupByLibrary.simpleMessage(
      "No other profiles",
    ),
    "chainNoOtherProfilesDesc": MessageLookupByLibrary.simpleMessage(
      "The exit must come from another profile. Add one to configure it.",
    ),
    "chainNotInProfile": MessageLookupByLibrary.simpleMessage(
      "not found in this profile",
    ),
    "chainNotInSelectedProfile": MessageLookupByLibrary.simpleMessage(
      "not found in the selected profile",
    ),
    "chainTargetGroup": MessageLookupByLibrary.simpleMessage("Group"),
    "chainTargetProxy": MessageLookupByLibrary.simpleMessage("Proxy"),
    "chainTitle": MessageLookupByLibrary.simpleMessage("Chain"),
    "chasingDots": MessageLookupByLibrary.simpleMessage("Chasing Dots"),
    "checkError": MessageLookupByLibrary.simpleMessage("Check Failed"),
    "checkFailed": MessageLookupByLibrary.simpleMessage("Timeout"),
    "checkOrAddProfile": MessageLookupByLibrary.simpleMessage(
      "Please add a profile first",
    ),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("Check for Updates"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage(
      "Already on the latest version",
    ),
    "checking": MessageLookupByLibrary.simpleMessage("Checking..."),
    "chinaAdaptApplyRecommended": MessageLookupByLibrary.simpleMessage(
      "Turn on recommended",
    ),
    "chinaAdaptDnsNoteDesc": MessageLookupByLibrary.simpleMessage(
      "That switch is not part of this group: it lives in Settings → Network and only takes effect on desktop (macOS/Linux). It changes the operating system\'s DNS, not the DNS inside your profile, and does nothing on Android.",
    ),
    "chinaAdaptRecommendDesc": MessageLookupByLibrary.simpleMessage(
      "For networks in China, the recommended combination is the three interception options in this group: privacy protection, WebRTC/STUN/TURN blocking and ad blocking. Turn them on together as a starting point; each can still be adjusted on its own.",
    ),
    "chinaAdaptRecommendTitle": MessageLookupByLibrary.simpleMessage(
      "Recommended combination",
    ),
    "chinaPreset": MessageLookupByLibrary.simpleMessage(
      "China adaptation preset",
    ),
    "chinaPresetApply": MessageLookupByLibrary.simpleMessage("Apply preset"),
    "chinaPresetDesc": MessageLookupByLibrary.simpleMessage(
      "One tap applies the recommended combination for use from China. Only existing app capabilities are combined — no new rules, no new requests.",
    ),
    "chinaPresetReset": MessageLookupByLibrary.simpleMessage(
      "Restore defaults",
    ),
    "chinaPresetStateCustomized": MessageLookupByLibrary.simpleMessage(
      "Customized",
    ),
    "chinaPresetStateOff": MessageLookupByLibrary.simpleMessage("Not applied"),
    "chinaPresetStateOn": MessageLookupByLibrary.simpleMessage("Applied"),
    "circle": MessageLookupByLibrary.simpleMessage("Circle"),
    "clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "clearCacheDesc": MessageLookupByLibrary.simpleMessage(
      "Clear FakeIP and DNS cache?",
    ),
    "clearCacheTitle": MessageLookupByLibrary.simpleMessage("Clear Cache"),
    "clearData": MessageLookupByLibrary.simpleMessage("Clear Data"),
    "clearDataTipDesc": MessageLookupByLibrary.simpleMessage(
      "This operation will reset the application. Please make backups. Are you sure you want to continue?",
    ),
    "clearDataTipTitle": MessageLookupByLibrary.simpleMessage(
      "Dangerous Operation",
    ),
    "clearFilter": MessageLookupByLibrary.simpleMessage("Clear filters"),
    "clipboard": MessageLookupByLibrary.simpleMessage("Clipboard"),
    "clipboardDesc": MessageLookupByLibrary.simpleMessage(
      "Get profile link from clipboard",
    ),
    "clipboardExport": MessageLookupByLibrary.simpleMessage(
      "Export to Clipboard",
    ),
    "clipboardImport": MessageLookupByLibrary.simpleMessage(
      "Import from Clipboard",
    ),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "closeAll": MessageLookupByLibrary.simpleMessage("Close All"),
    "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
    "color": MessageLookupByLibrary.simpleMessage("Color"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("Color Schemes"),
    "columns": MessageLookupByLibrary.simpleMessage("Columns"),
    "compatible": MessageLookupByLibrary.simpleMessage("Compatible Mode"),
    "compatibleDesc": MessageLookupByLibrary.simpleMessage(
      "Enabling this mode may limit some features, but provides full Clash support",
    ),
    "concurrencyLimit": MessageLookupByLibrary.simpleMessage(
      "Concurrency Limit",
    ),
    "concurrencyLimitDesc": MessageLookupByLibrary.simpleMessage(
      "Maximum concurrent delay tests",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "congestionController": MessageLookupByLibrary.simpleMessage(
      "Congestion Controller",
    ),
    "connection": MessageLookupByLibrary.simpleMessage("Active"),
    "connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "connectionsActive": MessageLookupByLibrary.simpleMessage("Active"),
    "connectionsClosed": MessageLookupByLibrary.simpleMessage("Closed"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage(
      "View active and closed connections",
    ),
    "connectionsSort": MessageLookupByLibrary.simpleMessage("Connections Sort"),
    "connectivity": MessageLookupByLibrary.simpleMessage("Connectivity:"),
    "contactMe": MessageLookupByLibrary.simpleMessage("Contact Me"),
    "content": MessageLookupByLibrary.simpleMessage("Content"),
    "contentScheme": MessageLookupByLibrary.simpleMessage("Content"),
    "continent": MessageLookupByLibrary.simpleMessage("Continent"),
    "controlSecret": MessageLookupByLibrary.simpleMessage("Control Secret"),
    "controlSecretDesc": MessageLookupByLibrary.simpleMessage(
      "RESTful API access password",
    ),
    "controlStyle": MessageLookupByLibrary.simpleMessage("Control style"),
    "controlStyleKeycap": MessageLookupByLibrary.simpleMessage(
      "Keycap · Futuristic",
    ),
    "controlStyleLiquidGlass": MessageLookupByLibrary.simpleMessage(
      "Liquid glass",
    ),
    "copiedPackageName": MessageLookupByLibrary.simpleMessage(
      "Copied package name",
    ),
    "copiedToClipboard": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage(
      "Copy Environment Variable",
    ),
    "copyLink": MessageLookupByLibrary.simpleMessage("Copy Link"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("Copy Successful"),
    "core": MessageLookupByLibrary.simpleMessage("Core"),
    "coreCapabilityNotEffective": MessageLookupByLibrary.simpleMessage(
      "Core authorization did not take effect: the running core lacks CAP_NET_ADMIN, TUN may fail",
    ),
    "coreConnected": MessageLookupByLibrary.simpleMessage("Connected"),
    "coreInfo": MessageLookupByLibrary.simpleMessage("Core Info"),
    "coreMountNosuid": MessageLookupByLibrary.simpleMessage(
      "The core is on a filesystem mounted with nosuid, so file capabilities and setuid cannot take effect",
    ),
    "coreStatus": MessageLookupByLibrary.simpleMessage("Core Status"),
    "coreSuspended": MessageLookupByLibrary.simpleMessage("Suspended"),
    "country": MessageLookupByLibrary.simpleMessage("Country"),
    "countryOrRegion": MessageLookupByLibrary.simpleMessage("Country / Region"),
    "crashTest": MessageLookupByLibrary.simpleMessage("Crash Test"),
    "create": MessageLookupByLibrary.simpleMessage("Create"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Creation Time"),
    "cubeGrid": MessageLookupByLibrary.simpleMessage("Cube Grid"),
    "custom": MessageLookupByLibrary.simpleMessage("Custom"),
    "customDashboardTitle": MessageLookupByLibrary.simpleMessage(
      "Custom Title",
    ),
    "customScriptOptions": MessageLookupByLibrary.simpleMessage(
      "Custom Rule Switch",
    ),
    "customUrl": MessageLookupByLibrary.simpleMessage("Custom URL"),
    "cut": MessageLookupByLibrary.simpleMessage("Cut"),
    "dancingSquare": MessageLookupByLibrary.simpleMessage("Dancing Square"),
    "dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "darkIcon": MessageLookupByLibrary.simpleMessage("Dark Icon"),
    "darkIconDesc": MessageLookupByLibrary.simpleMessage(
      "Manually switch dark app icon",
    ),
    "dashboard": MessageLookupByLibrary.simpleMessage("Home"),
    "dashboardAverage": m4,
    "dashboardTotal": MessageLookupByLibrary.simpleMessage("Total"),
    "days": m5,
    "defaultGateway": MessageLookupByLibrary.simpleMessage("Gateway"),
    "defaultNameserver": MessageLookupByLibrary.simpleMessage(
      "Default Nameserver",
    ),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolve DNS servers",
    ),
    "defaultSort": MessageLookupByLibrary.simpleMessage("Default Sort"),
    "defaultText": MessageLookupByLibrary.simpleMessage("Default"),
    "delay": MessageLookupByLibrary.simpleMessage("Delay"),
    "delayAnimation": MessageLookupByLibrary.simpleMessage("Delay Animation"),
    "delayAnimationDesc": MessageLookupByLibrary.simpleMessage(
      "Customize animation during delay testing",
    ),
    "delaySort": MessageLookupByLibrary.simpleMessage("Sort by Delay"),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteMultipTip": m6,
    "deleteTip": m7,
    "deleteTunnel": MessageLookupByLibrary.simpleMessage("Delete Forwarding"),
    "desc": MessageLookupByLibrary.simpleMessage(
      "Angela Mihomo is deeply crafted on the powerful and flexible Mihomo kernel, dedicated to a superior client experience. Our vision: Connecting Open Source and AI, Accelerating Innovation",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("Destination"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage(
      "Destination GeoIP",
    ),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage(
      "Destination IP ASN",
    ),
    "details": MessageLookupByLibrary.simpleMessage("Details"),
    "detectionTip": MessageLookupByLibrary.simpleMessage(
      "Third-party API result (for reference only)",
    ),
    "developerMode": MessageLookupByLibrary.simpleMessage("Developer Mode"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "Developer mode is enabled.",
    ),
    "dialerIp4pConvert": MessageLookupByLibrary.simpleMessage(
      "Enable Dialer IP4P Conversion",
    ),
    "dialerIp4pConvertDesc": MessageLookupByLibrary.simpleMessage(
      "Enable dialer IP4P conversion",
    ),
    "direct": MessageLookupByLibrary.simpleMessage("Direct"),
    "directNameserver": MessageLookupByLibrary.simpleMessage(
      "Direct Nameserver",
    ),
    "directNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolve direct domains",
    ),
    "directNameserverFollowPolicy": MessageLookupByLibrary.simpleMessage(
      "Direct DNS Follows Policy",
    ),
    "disableQuic": MessageLookupByLibrary.simpleMessage("Disable QUIC"),
    "disableQuicDesc": MessageLookupByLibrary.simpleMessage(
      "Disable QUIC to resolve specific network issues",
    ),
    "disabled": MessageLookupByLibrary.simpleMessage("Disabled"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("Disclaimer"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "This free open-source software is for non-commercial learning and personal use only. Proxy services are independent of this software. By agreeing, you acknowledge this; otherwise, please exit.",
    ),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage(
      "New Version Available",
    ),
    "discovery": MessageLookupByLibrary.simpleMessage("New Version Found"),
    "dnsDesc": MessageLookupByLibrary.simpleMessage("DNS-related settings"),
    "dnsHijack": MessageLookupByLibrary.simpleMessage("DNS Hijack"),
    "dnsHijackDesc": MessageLookupByLibrary.simpleMessage(
      "Redirect DNS queries to internal DNS module",
    ),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNS Mode"),
    "dnsQuery": MessageLookupByLibrary.simpleMessage("DNS Lookup"),
    "dnsQueryCompare": MessageLookupByLibrary.simpleMessage("Compare"),
    "dnsQueryCompareDesc": MessageLookupByLibrary.simpleMessage(
      "Resolve with rules, system DNS and the chosen server side by side to spot pollution or routing differences",
    ),
    "dnsQueryDesc": MessageLookupByLibrary.simpleMessage(
      "Resolve with rules, system or a chosen server",
    ),
    "dnsQueryFakeIpOff": m8,
    "dnsQueryFakeIpOn": m9,
    "dnsQueryFilterBlackHit": MessageLookupByLibrary.simpleMessage(
      "in blacklist",
    ),
    "dnsQueryFilterBlackMiss": MessageLookupByLibrary.simpleMessage(
      "not in blacklist",
    ),
    "dnsQueryFilterRuleFake": MessageLookupByLibrary.simpleMessage(
      "rule says fake-ip",
    ),
    "dnsQueryFilterRuleReal": MessageLookupByLibrary.simpleMessage(
      "rule says real-ip",
    ),
    "dnsQueryFilterWhiteHit": MessageLookupByLibrary.simpleMessage(
      "in whitelist",
    ),
    "dnsQueryFilterWhiteMiss": MessageLookupByLibrary.simpleMessage(
      "not in whitelist",
    ),
    "dnsQueryHint": MessageLookupByLibrary.simpleMessage("Domain"),
    "dnsQueryHostsHit": m10,
    "dnsQueryNoRecords": MessageLookupByLibrary.simpleMessage("No records"),
    "dnsQueryNormalMode": MessageLookupByLibrary.simpleMessage(
      "Normal: returns the real IP, rules match by IP",
    ),
    "dnsQueryRedirHost": MessageLookupByLibrary.simpleMessage(
      "Redir-Host: returns the real IP, domain restored on connect",
    ),
    "dnsQueryServer": MessageLookupByLibrary.simpleMessage("DNS Server"),
    "dnsQueryServerHint": MessageLookupByLibrary.simpleMessage(
      "e.g. 1.1.1.1, https://cloudflare-dns.com/dns-query",
    ),
    "dnsQueryServerInvalid": MessageLookupByLibrary.simpleMessage(
      "Invalid DNS server",
    ),
    "dnsQueryStopped": MessageLookupByLibrary.simpleMessage(
      "Proxy is not running, \"Follow Rules\" is unavailable",
    ),
    "dnsQuerySystem": MessageLookupByLibrary.simpleMessage("System DNS"),
    "dnsQueryViaDirect": MessageLookupByLibrary.simpleMessage(
      "Via DIRECT, resolved locally by the core",
    ),
    "dnsQueryViaDirectHosts": MessageLookupByLibrary.simpleMessage(
      "Via DIRECT, connects to the Hosts address",
    ),
    "dnsQueryViaProxy": m11,
    "dnsQueryViaProxyHosts": m12,
    "dnsQueryViaReject": MessageLookupByLibrary.simpleMessage(
      "Rejected by rules",
    ),
    "dnsResolution": MessageLookupByLibrary.simpleMessage("DNS Resolution"),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage(
      "Do you want to pass",
    ),
    "domain": MessageLookupByLibrary.simpleMessage("Domain"),
    "doubleBounce": MessageLookupByLibrary.simpleMessage("Double Bounce"),
    "download": MessageLookupByLibrary.simpleMessage("Download"),
    "dozeSuspend": MessageLookupByLibrary.simpleMessage("Doze Support"),
    "dozeSuspendDesc": MessageLookupByLibrary.simpleMessage(
      "Sync with system Doze mode",
    ),
    "dualRing": MessageLookupByLibrary.simpleMessage("Dual Ring"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editTunnel": MessageLookupByLibrary.simpleMessage("Edit Forwarding"),
    "editUser": MessageLookupByLibrary.simpleMessage("Edit User"),
    "emptyTip": m13,
    "enableCrashReport": MessageLookupByLibrary.simpleMessage(
      "Crash Analytics",
    ),
    "enableCrashReportDesc": MessageLookupByLibrary.simpleMessage(
      "Upload crash logs when needed",
    ),
    "enableOverride": MessageLookupByLibrary.simpleMessage("Enable Override"),
    "enableTraySpeed": MessageLookupByLibrary.simpleMessage("Tray Speed"),
    "enableTraySpeedDesc": MessageLookupByLibrary.simpleMessage(
      "Show network speed in menu bar",
    ),
    "enabled": MessageLookupByLibrary.simpleMessage("Enabled"),
    "endpointIndependentNat": MessageLookupByLibrary.simpleMessage(
      "NAT Enhancement",
    ),
    "endpointIndependentNatConfirmDesc": MessageLookupByLibrary.simpleMessage(
      "Enabling Endpoint-Independent NAT feature may slightly degrade performance. It is recommended to enable it only if necessary and you are familiar with it.",
    ),
    "endpointIndependentNatDesc": MessageLookupByLibrary.simpleMessage(
      "Optimize UDP/P2P application experience",
    ),
    "entries": MessageLookupByLibrary.simpleMessage(" entries"),
    "exclude": MessageLookupByLibrary.simpleMessage("Hide from Recents"),
    "excludeChina": MessageLookupByLibrary.simpleMessage("Exclude China"),
    "excludeChinaDesc": MessageLookupByLibrary.simpleMessage(
      "Allow China QUIC instead of blocking all",
    ),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "Hide app from recent tasks list",
    ),
    "existsTip": m14,
    "exit": MessageLookupByLibrary.simpleMessage("Exit"),
    "expand": MessageLookupByLibrary.simpleMessage("Standard"),
    "experimental": MessageLookupByLibrary.simpleMessage("Experimental"),
    "experimentalDesc": MessageLookupByLibrary.simpleMessage(
      "Use with caution",
    ),
    "expirationTime": MessageLookupByLibrary.simpleMessage("Expiration Time"),
    "expired": MessageLookupByLibrary.simpleMessage("Expired"),
    "export": MessageLookupByLibrary.simpleMessage("Export"),
    "exportFile": MessageLookupByLibrary.simpleMessage("Export File"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("Export Logs"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("Export Successful"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("Expressive"),
    "externalController": MessageLookupByLibrary.simpleMessage(
      "External Controller",
    ),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "Control core via online port",
    ),
    "externalLink": MessageLookupByLibrary.simpleMessage("External Link"),
    "externalResources": MessageLookupByLibrary.simpleMessage(
      "External Resources",
    ),
    "fadingCircle": MessageLookupByLibrary.simpleMessage("Fading Circle"),
    "fadingCube": MessageLookupByLibrary.simpleMessage("Fading Cube"),
    "fadingFour": MessageLookupByLibrary.simpleMessage("Fading Four"),
    "fadingGrid": MessageLookupByLibrary.simpleMessage("Fading Grid"),
    "fakeIpFilterMode": MessageLookupByLibrary.simpleMessage(
      "FakeIP Filter Mode",
    ),
    "fakeIpFilterModeDesc": MessageLookupByLibrary.simpleMessage(
      "Specify FakeIP filter mode",
    ),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("FakeIP Filter"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("FakeIP Range"),
    "fakeipRangeV6": MessageLookupByLibrary.simpleMessage("FakeIPv6 Range"),
    "fakeipTtl": MessageLookupByLibrary.simpleMessage("FakeIP TTL"),
    "fallback": MessageLookupByLibrary.simpleMessage("Fallback"),
    "fallbackConcurrent": MessageLookupByLibrary.simpleMessage(
      "Fallback Concurrent",
    ),
    "fallbackConcurrentDesc": MessageLookupByLibrary.simpleMessage(
      "Query default DNS and Fallback synchronously",
    ),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage(
      "Usually offshore DNS",
    ),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("Fallback Filter"),
    "fast": MessageLookupByLibrary.simpleMessage("Fast"),
    "fcmOptimization": MessageLookupByLibrary.simpleMessage("FCM Optimization"),
    "fcmOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "Enhance FCM connection stability",
    ),
    "fcmTip": MessageLookupByLibrary.simpleMessage(
      "FCM connection and support depend on the device itself, the results are for reference only. Due to system permission reasons, you need to disable \"Allow bypass VPN\" in settings to get accurate results",
    ),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("Fidelity"),
    "file": MessageLookupByLibrary.simpleMessage("File"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("Upload profile file"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "File modified. Save changes?",
    ),
    "filterSystemApp": MessageLookupByLibrary.simpleMessage(
      "Filter System Apps",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("Find Process"),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "Enable process matching",
    ),
    "flagged": MessageLookupByLibrary.simpleMessage("Flagged"),
    "flushDnsOnNetworkChange": MessageLookupByLibrary.simpleMessage(
      "Clear DNS Cache",
    ),
    "flushDnsOnNetworkChangeDesc": MessageLookupByLibrary.simpleMessage(
      "Clear the DNS cache when the network changes",
    ),
    "foldingCube": MessageLookupByLibrary.simpleMessage("Folding Cube"),
    "followGlobalScript": MessageLookupByLibrary.simpleMessage(
      "Follow Global Script",
    ),
    "fontFamily": MessageLookupByLibrary.simpleMessage("Font"),
    "forceDnsMapping": MessageLookupByLibrary.simpleMessage(
      "Force DNS Mapping",
    ),
    "forceDnsMappingDesc": MessageLookupByLibrary.simpleMessage(
      "Force mapping DNS results to connections",
    ),
    "forceDomain": MessageLookupByLibrary.simpleMessage("Force Sniff Domain"),
    "forceGCDesc": MessageLookupByLibrary.simpleMessage(
      "Force kernel garbage collection? Experimental, use with caution.",
    ),
    "forceGCTitle": MessageLookupByLibrary.simpleMessage(
      "Force Garbage Collection",
    ),
    "formatError": MessageLookupByLibrary.simpleMessage(
      "Please check the format",
    ),
    "fourColumns": MessageLookupByLibrary.simpleMessage("4 Columns"),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("Fruit Salad"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "generalDesc": MessageLookupByLibrary.simpleMessage(
      "Modify global settings",
    ),
    "generateFromPrivateKey": MessageLookupByLibrary.simpleMessage(
      "Generate from private key",
    ),
    "generateSecret": MessageLookupByLibrary.simpleMessage("Generate"),
    "geoBuiltInResources": MessageLookupByLibrary.simpleMessage(
      "GEO Built-in Resources",
    ),
    "geoData": MessageLookupByLibrary.simpleMessage("GeoData"),
    "geodataLoader": MessageLookupByLibrary.simpleMessage("GEO Low Memory"),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "Use GEO low memory loader",
    ),
    "geodataUse": MessageLookupByLibrary.simpleMessage("GEO Load"),
    "geoipCode": MessageLookupByLibrary.simpleMessage("GeoIP Code"),
    "getOriginRules": MessageLookupByLibrary.simpleMessage("Original Rules"),
    "global": MessageLookupByLibrary.simpleMessage("Global"),
    "go": MessageLookupByLibrary.simpleMessage("Go"),
    "goDownload": MessageLookupByLibrary.simpleMessage("Download Now"),
    "harmonyFont": MessageLookupByLibrary.simpleMessage("Font Fix"),
    "harmonyFontDesc": MessageLookupByLibrary.simpleMessage(
      "Use built-in font to fix display issues",
    ),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage(
      "Cache modifications?",
    ),
    "healthCheckTimeout": MessageLookupByLibrary.simpleMessage("Timeout"),
    "healthCheckTimeoutDesc": MessageLookupByLibrary.simpleMessage(
      "Node health check timeout",
    ),
    "heapObjects": MessageLookupByLibrary.simpleMessage("Objects"),
    "highPriority": MessageLookupByLibrary.simpleMessage("High Priority"),
    "highPriorityDesc": MessageLookupByLibrary.simpleMessage(
      "Elevate app & core process priority",
    ),
    "highRefreshRate": MessageLookupByLibrary.simpleMessage(
      "High Refresh Rate",
    ),
    "highRefreshRateDesc": MessageLookupByLibrary.simpleMessage(
      "Enable max refresh rate",
    ),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage(
      "Append hosts to current config",
    ),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage("Hotkey Conflict"),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage(
      "Hotkey Management",
    ),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "Control app via keyboard",
    ),
    "hourGlass": MessageLookupByLibrary.simpleMessage("Hourglass"),
    "hours": m15,
    "httpPortSniffer": MessageLookupByLibrary.simpleMessage(
      "HTTP Port Sniffing",
    ),
    "icmpForwarding": MessageLookupByLibrary.simpleMessage("ICMP Forwarding"),
    "icmpForwardingDesc": MessageLookupByLibrary.simpleMessage(
      "Enable ICMP Ping",
    ),
    "icon": MessageLookupByLibrary.simpleMessage("Icon"),
    "iconConfiguration": MessageLookupByLibrary.simpleMessage(
      "Icon Configuration",
    ),
    "iconConfigurationDesc": MessageLookupByLibrary.simpleMessage(
      "Customize proxy group ICON icons",
    ),
    "iconStyle": MessageLookupByLibrary.simpleMessage("Icon Style"),
    "import": MessageLookupByLibrary.simpleMessage("Import"),
    "importFailed": MessageLookupByLibrary.simpleMessage("Import failed"),
    "importFile": MessageLookupByLibrary.simpleMessage("Import from File"),
    "importFromCode": MessageLookupByLibrary.simpleMessage("Import from Code"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("Import from URL"),
    "importUrl": MessageLookupByLibrary.simpleMessage("Import from URL"),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("Never Expires"),
    "init": MessageLookupByLibrary.simpleMessage("Init"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage(
      "Enter a valid hotkey",
    ),
    "installTime": MessageLookupByLibrary.simpleMessage("Install Time"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("Smart Select"),
    "internet": MessageLookupByLibrary.simpleMessage("Internet"),
    "interval": MessageLookupByLibrary.simpleMessage("Interval"),
    "intranetAndGateway": MessageLookupByLibrary.simpleMessage("LAN & Gateway"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("Local IP"),
    "invalidIpFormat": MessageLookupByLibrary.simpleMessage(
      "Invalid IP or CIDR format",
    ),
    "ipAddress": MessageLookupByLibrary.simpleMessage("IP Address"),
    "ipClickBehavior": MessageLookupByLibrary.simpleMessage("Toggle Display"),
    "ipLookup": MessageLookupByLibrary.simpleMessage("IP Lookup"),
    "ipLookupDesc": MessageLookupByLibrary.simpleMessage(
      "Your exit IPs, or look up any IP or domain",
    ),
    "ipLookupDomesticExit": MessageLookupByLibrary.simpleMessage(
      "Domestic Local IP",
    ),
    "ipLookupHint": MessageLookupByLibrary.simpleMessage("IP or domain"),
    "ipLookupInvalid": MessageLookupByLibrary.simpleMessage(
      "Enter a valid IP or domain",
    ),
    "ipLookupLocal": MessageLookupByLibrary.simpleMessage("Local Network"),
    "ipLookupMine": MessageLookupByLibrary.simpleMessage("My IP"),
    "ipLookupProxyExit": MessageLookupByLibrary.simpleMessage(
      "Default Node IP",
    ),
    "ipLookupResolveFailed": MessageLookupByLibrary.simpleMessage(
      "Unable to resolve this domain",
    ),
    "ipLookupResult": MessageLookupByLibrary.simpleMessage("Results"),
    "ipPrivacyProtection": MessageLookupByLibrary.simpleMessage(
      "Hide IP Display",
    ),
    "ipcidr": MessageLookupByLibrary.simpleMessage("IP/CIDR"),
    "iperfAddressHint": MessageLookupByLibrary.simpleMessage(
      "Server address, e.g. 192.168.1.5",
    ),
    "iperfAddressRequired": MessageLookupByLibrary.simpleMessage(
      "Enter a server address",
    ),
    "iperfAddresses": MessageLookupByLibrary.simpleMessage("This device"),
    "iperfBandwidth": MessageLookupByLibrary.simpleMessage("Send rate"),
    "iperfBidir": MessageLookupByLibrary.simpleMessage("Both"),
    "iperfClient": MessageLookupByLibrary.simpleMessage("Client"),
    "iperfCommands": MessageLookupByLibrary.simpleMessage("iperf3 commands"),
    "iperfConnecting": MessageLookupByLibrary.simpleMessage("Connecting…"),
    "iperfDirection": MessageLookupByLibrary.simpleMessage("Direction"),
    "iperfDone": MessageLookupByLibrary.simpleMessage("Test complete"),
    "iperfDuration": MessageLookupByLibrary.simpleMessage("Duration"),
    "iperfErrorBusy": MessageLookupByLibrary.simpleMessage(
      "The server is busy with another test. Try again later",
    ),
    "iperfErrorInterrupted": MessageLookupByLibrary.simpleMessage(
      "The test was interrupted",
    ),
    "iperfErrorListen": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t start the server",
    ),
    "iperfErrorPortInUse": m16,
    "iperfErrorProtocol": MessageLookupByLibrary.simpleMessage(
      "Unexpected response. The other side may not be an iPerf3 server",
    ),
    "iperfErrorRefused": MessageLookupByLibrary.simpleMessage(
      "Connection refused. Make sure the iPerf3 server is running",
    ),
    "iperfErrorServer": m17,
    "iperfErrorTimeout": MessageLookupByLibrary.simpleMessage(
      "Connection timed out. Check the address and network",
    ),
    "iperfErrorUdp": MessageLookupByLibrary.simpleMessage(
      "UDP handshake failed. It may be blocked by a firewall",
    ),
    "iperfErrorUnreachable": MessageLookupByLibrary.simpleMessage(
      "Can\'t reach the server",
    ),
    "iperfFirewallTip": MessageLookupByLibrary.simpleMessage(
      "If other devices can\'t connect, allow incoming connections for the Angela Mihomo core in your system firewall.",
    ),
    "iperfLostPackets": m18,
    "iperfNoAddress": MessageLookupByLibrary.simpleMessage(
      "No LAN address found. Make sure Wi-Fi or Ethernet is connected",
    ),
    "iperfParallel": MessageLookupByLibrary.simpleMessage("Streams"),
    "iperfPeer": MessageLookupByLibrary.simpleMessage("Peer"),
    "iperfPort": MessageLookupByLibrary.simpleMessage("Port"),
    "iperfPortInvalid": MessageLookupByLibrary.simpleMessage(
      "Enter a port between 1 and 65535",
    ),
    "iperfProtocol": MessageLookupByLibrary.simpleMessage("Protocol"),
    "iperfReady": MessageLookupByLibrary.simpleMessage(
      "Enter a server address or scan a QR code to start",
    ),
    "iperfReceive": MessageLookupByLibrary.simpleMessage("Receive"),
    "iperfResult": MessageLookupByLibrary.simpleMessage("Result"),
    "iperfRetest": MessageLookupByLibrary.simpleMessage("Test again"),
    "iperfRetransmits": MessageLookupByLibrary.simpleMessage("Retransmits"),
    "iperfRtt": MessageLookupByLibrary.simpleMessage("RTT"),
    "iperfRunning": MessageLookupByLibrary.simpleMessage("Testing"),
    "iperfScan": MessageLookupByLibrary.simpleMessage("Scan to connect"),
    "iperfScanHint": MessageLookupByLibrary.simpleMessage(
      "Scan with Angela Mihomo on another device to connect in one tap",
    ),
    "iperfScanInvalid": MessageLookupByLibrary.simpleMessage(
      "This isn\'t an iPerf3 connection QR code",
    ),
    "iperfScanned": m19,
    "iperfSeconds": m20,
    "iperfSend": MessageLookupByLibrary.simpleMessage("Send"),
    "iperfServer": MessageLookupByLibrary.simpleMessage("Server"),
    "iperfServerListening": m21,
    "iperfServerOff": MessageLookupByLibrary.simpleMessage(
      "Server is not running",
    ),
    "iperfServerOffHint": MessageLookupByLibrary.simpleMessage(
      "Once started, other devices can scan the QR code or enter this device\'s address to connect",
    ),
    "iperfServerStart": MessageLookupByLibrary.simpleMessage("Start server"),
    "iperfServerStop": MessageLookupByLibrary.simpleMessage("Stop server"),
    "iperfServerTip": MessageLookupByLibrary.simpleMessage(
      "The server only runs while this page is open and stops when you leave. The screen stays on while it runs.",
    ),
    "iperfStart": MessageLookupByLibrary.simpleMessage("Start test"),
    "iperfStreams": m22,
    "iperfTest": MessageLookupByLibrary.simpleMessage("iPerf3 Tool"),
    "iperfTestDesc": MessageLookupByLibrary.simpleMessage(
      "Measure bandwidth between devices on your LAN, compatible with iperf3",
    ),
    "iperfThroughput": MessageLookupByLibrary.simpleMessage("Throughput"),
    "iperfTransferred": MessageLookupByLibrary.simpleMessage("Data"),
    "iperfUdpUnavailable": MessageLookupByLibrary.simpleMessage(
      "The UDP port is in use, so only TCP tests are available.",
    ),
    "iperfWaiting": MessageLookupByLibrary.simpleMessage(
      "Waiting for a client",
    ),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage(
      "Enable IPv6 traffic routing",
    ),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage(
      "Allow IPv6 inbound",
    ),
    "isp": MessageLookupByLibrary.simpleMessage("ISP"),
    "itemsCount": m23,
    "just": MessageLookupByLibrary.simpleMessage("Just now"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCP keep-alive interval",
    ),
    "keepDockIcon": MessageLookupByLibrary.simpleMessage("Keep in Dock"),
    "keepDockIconDesc": MessageLookupByLibrary.simpleMessage(
      "Keep the app icon in the Dock",
    ),
    "key": MessageLookupByLibrary.simpleMessage("Key"),
    "lanSharing": MessageLookupByLibrary.simpleMessage("LAN Sharing"),
    "language": MessageLookupByLibrary.simpleMessage("Language"),
    "lastEdit": MessageLookupByLibrary.simpleMessage("Last edited"),
    "layout": MessageLookupByLibrary.simpleMessage("Layout"),
    "leftClickBehavior": MessageLookupByLibrary.simpleMessage("Left Click"),
    "light": MessageLookupByLibrary.simpleMessage("Light"),
    "limitedUnlock": MessageLookupByLibrary.simpleMessage("Originals Only"),
    "lineWrap": MessageLookupByLibrary.simpleMessage("Wrap Lines"),
    "list": MessageLookupByLibrary.simpleMessage("List"),
    "listen": MessageLookupByLibrary.simpleMessage("Listen"),
    "local": MessageLookupByLibrary.simpleMessage("Local"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Backup data locally",
    ),
    "localFile": MessageLookupByLibrary.simpleMessage("Local File"),
    "localPing": MessageLookupByLibrary.simpleMessage("Local Ping"),
    "localPingAverage": MessageLookupByLibrary.simpleMessage("Average"),
    "localPingBytes": m24,
    "localPingClosed": MessageLookupByLibrary.simpleMessage("Port closed"),
    "localPingCount": MessageLookupByLibrary.simpleMessage("Count"),
    "localPingDesc": MessageLookupByLibrary.simpleMessage(
      "Direct ICMP, TCP and UDP latency and loss test",
    ),
    "localPingDone": MessageLookupByLibrary.simpleMessage("Ping finished"),
    "localPingErrorDenied": MessageLookupByLibrary.simpleMessage(
      "ICMP is not permitted on this system. Try TCP or UDP ping",
    ),
    "localPingErrorNetwork": MessageLookupByLibrary.simpleMessage(
      "Unable to send ping packets",
    ),
    "localPingErrorResolve": MessageLookupByLibrary.simpleMessage(
      "Could not resolve the domain",
    ),
    "localPingFailed": MessageLookupByLibrary.simpleMessage("Send failed"),
    "localPingFrom": m25,
    "localPingGateway": MessageLookupByLibrary.simpleMessage("Gateway"),
    "localPingListLimit": m26,
    "localPingMax": MessageLookupByLibrary.simpleMessage("Max"),
    "localPingMin": MessageLookupByLibrary.simpleMessage("Min"),
    "localPingReady": MessageLookupByLibrary.simpleMessage(
      "Choose a target to start",
    ),
    "localPingReceived": MessageLookupByLibrary.simpleMessage("Received"),
    "localPingResolving": MessageLookupByLibrary.simpleMessage("Resolving"),
    "localPingResult": MessageLookupByLibrary.simpleMessage("Ping result"),
    "localPingRttSummary": m27,
    "localPingRunning": MessageLookupByLibrary.simpleMessage("Pinging"),
    "localPingSent": MessageLookupByLibrary.simpleMessage("Sent"),
    "localPingSize": MessageLookupByLibrary.simpleMessage("Packet size"),
    "localPingStart": MessageLookupByLibrary.simpleMessage("Start ping"),
    "localPingStats": m28,
    "localPingSummary": m29,
    "localPingTargetHint": MessageLookupByLibrary.simpleMessage(
      "Domain or IP address",
    ),
    "localPingTcpTip": MessageLookupByLibrary.simpleMessage(
      "TCP ping measures connection setup time. A refused connection also means the host is reachable",
    ),
    "localPingTimeout": MessageLookupByLibrary.simpleMessage(
      "Request timed out",
    ),
    "localPingUdpTip": MessageLookupByLibrary.simpleMessage(
      "Port 53 sends a DNS query and waits for the answer. Most other ports never reply, so a timeout does not mean the host is down",
    ),
    "localPingUnreachable": MessageLookupByLibrary.simpleMessage(
      "Destination unreachable",
    ),
    "localRecoveryDesc": MessageLookupByLibrary.simpleMessage(
      "Restore data from file",
    ),
    "locate": MessageLookupByLibrary.simpleMessage("Locate"),
    "log": MessageLookupByLibrary.simpleMessage("Log"),
    "logAiSearch": MessageLookupByLibrary.simpleMessage("AI Search"),
    "logLevel": MessageLookupByLibrary.simpleMessage("Log Level"),
    "logLevelDebugHint": m30,
    "logcat": MessageLookupByLibrary.simpleMessage("Log Capture"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage(
      "Show log capture entry",
    ),
    "logs": MessageLookupByLibrary.simpleMessage("Logs"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("View captured logs"),
    "logsTest": MessageLookupByLibrary.simpleMessage("Logs Test"),
    "loopback": MessageLookupByLibrary.simpleMessage("Loopback Unlock"),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage(
      "UWP loopback unlocking tool",
    ),
    "loopbackProtection": MessageLookupByLibrary.simpleMessage(
      "Loopback Protection",
    ),
    "loopbackProtectionDesc": MessageLookupByLibrary.simpleMessage(
      "Block loopback traffic from errors",
    ),
    "loose": MessageLookupByLibrary.simpleMessage("Loose"),
    "manualRefreshIp": MessageLookupByLibrary.simpleMessage("Refresh IP"),
    "maximize": MessageLookupByLibrary.simpleMessage("Maximize"),
    "mediaBatchAll": MessageLookupByLibrary.simpleMessage("All nodes"),
    "mediaBatchAllDesc": MessageLookupByLibrary.simpleMessage(
      "Every node, excluding DIRECT",
    ),
    "mediaBatchGroup": MessageLookupByLibrary.simpleMessage("Test"),
    "mediaBatchNoNodes": MessageLookupByLibrary.simpleMessage(
      "No nodes to test",
    ),
    "mediaBatchScope": MessageLookupByLibrary.simpleMessage(
      "Choose what to test",
    ),
    "mediaBatchSummary": m31,
    "mediaBatchTest": MessageLookupByLibrary.simpleMessage("Batch Node Test"),
    "mediaUnlock": MessageLookupByLibrary.simpleMessage("Connectivity Test"),
    "mediaUnlockColorfulIcons": MessageLookupByLibrary.simpleMessage(
      "Show colored icons by default",
    ),
    "mediaUnlockDetails": MessageLookupByLibrary.simpleMessage(
      "Connectivity Test Details",
    ),
    "mediaUnlockDisplaySettings": MessageLookupByLibrary.simpleMessage(
      "Display Settings",
    ),
    "mediaUnlockExtraDetails": MessageLookupByLibrary.simpleMessage(
      "Show more IP details",
    ),
    "mediaUnlockMiscSettings": MessageLookupByLibrary.simpleMessage(
      "Misc Settings",
    ),
    "mediaUnlockMoreStreamingPlatforms": MessageLookupByLibrary.simpleMessage(
      "More Streaming Unlock Items",
    ),
    "mediaUnlockPinnedSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Pin up to 3 items on widget",
    ),
    "mediaUnlockRefreshByCategory": MessageLookupByLibrary.simpleMessage(
      "Partially refresh based on current category",
    ),
    "mediaUnlockRefreshOnNodeChange": MessageLookupByLibrary.simpleMessage(
      "Auto refresh on node change",
    ),
    "mediaUnlockSelectLimit": MessageLookupByLibrary.simpleMessage(
      "You can select up to 3 items",
    ),
    "mediaUnlocked": MessageLookupByLibrary.simpleMessage("Unlocked"),
    "memoryAndRuntime": MessageLookupByLibrary.simpleMessage(
      "Memory & Runtime",
    ),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("Memory"),
    "memoryInfoDesc": MessageLookupByLibrary.simpleMessage(
      "The current memory information value displayed is the dynamic stack memory usage of the core during runtime, not the complete APP memory statistics, for reference only.",
    ),
    "messageTest": MessageLookupByLibrary.simpleMessage("Message Test"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage(
      "This is a message.",
    ),
    "mihomoCoreVersion": MessageLookupByLibrary.simpleMessage(
      "Mihomo core version",
    ),
    "min": MessageLookupByLibrary.simpleMessage("Min"),
    "minimize": MessageLookupByLibrary.simpleMessage("Minimize"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("Minimize on Exit"),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "Override default exit behavior",
    ),
    "minutes": m32,
    "mixedPort": MessageLookupByLibrary.simpleMessage("Mixed Port"),
    "mode": MessageLookupByLibrary.simpleMessage("Mode"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("Monochrome"),
    "months": m33,
    "more": MessageLookupByLibrary.simpleMessage("More"),
    "moreIpInfo": MessageLookupByLibrary.simpleMessage("More IP Information"),
    "mrsCopyRawLink": MessageLookupByLibrary.simpleMessage(
      "Copy as GitHub Raw link",
    ),
    "mrsLookup": MessageLookupByLibrary.simpleMessage("MRS Lookup"),
    "mrsLookupDesc": MessageLookupByLibrary.simpleMessage(
      "Find the GEODATA / RULE-SET rule sets for a domain or IP",
    ),
    "mrsLookupHint": MessageLookupByLibrary.simpleMessage("Domain or IP"),
    "mrsMissing": MessageLookupByLibrary.simpleMessage(
      "Bundled BundleMRS not found",
    ),
    "mrsNoMatch": MessageLookupByLibrary.simpleMessage("No rule set matched"),
    "mrsPrepareFailed": MessageLookupByLibrary.simpleMessage(
      "Failed to load rule sets",
    ),
    "mrsReferenced": MessageLookupByLibrary.simpleMessage("In use"),
    "mrsResolveDns": MessageLookupByLibrary.simpleMessage(
      "Resolve domains with DNS rules",
    ),
    "mrsResolveDnsDesc": MessageLookupByLibrary.simpleMessage(
      "When on, domains are resolved to IPs with the current DNS config and the IPs are matched too",
    ),
    "mrsRules": m34,
    "mrsVia": m35,
    "name": MessageLookupByLibrary.simpleMessage("Name"),
    "nameSort": MessageLookupByLibrary.simpleMessage("Sort by Name"),
    "nameserver": MessageLookupByLibrary.simpleMessage("Nameserver"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolve domain names",
    ),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage(
      "Nameserver Policy",
    ),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "Specify domain-specific nameservers",
    ),
    "natCopyResult": MessageLookupByLibrary.simpleMessage("Copy Result"),
    "natDescBlocked": MessageLookupByLibrary.simpleMessage(
      "No STUN reply. UDP may be blocked by a firewall, your ISP or the outbound node.",
    ),
    "natDescCone": MessageLookupByLibrary.simpleMessage(
      "Most P2P and online games work fine. This server can\'t tell exactly which of NAT1–3 you have; try another server for a precise result.",
    ),
    "natDescFullCone": MessageLookupByLibrary.simpleMessage(
      "NAT1: any external host can reach you. Best for P2P, gaming and voice calls.",
    ),
    "natDescOpen": MessageLookupByLibrary.simpleMessage(
      "No NAT in between. Peers can reach you directly, which is ideal for P2P and gaming.",
    ),
    "natDescPortRestricted": MessageLookupByLibrary.simpleMessage(
      "NAT3: only the exact address and port you contacted can reply. Some P2P or gaming may need a relay.",
    ),
    "natDescRestricted": MessageLookupByLibrary.simpleMessage(
      "NAT2: only addresses you contacted can reply. Most P2P and games work well.",
    ),
    "natDescSymmetric": MessageLookupByLibrary.simpleMessage(
      "NAT4: every destination gets a different mapped port. P2P is hard and usually needs a relay.",
    ),
    "natDescUnknown": MessageLookupByLibrary.simpleMessage(
      "Unable to determine the NAT type.",
    ),
    "natErrorUnavailable": MessageLookupByLibrary.simpleMessage(
      "Unable to reach the STUN server",
    ),
    "natErrorUnsupported": MessageLookupByLibrary.simpleMessage(
      "The selected outbound does not support UDP",
    ),
    "natExternalIp": MessageLookupByLibrary.simpleMessage("External IP"),
    "natExternalPort": MessageLookupByLibrary.simpleMessage("External Port"),
    "natFiltering": MessageLookupByLibrary.simpleMessage("Filtering"),
    "natLocalIp": MessageLookupByLibrary.simpleMessage("Local IP"),
    "natMapping": MessageLookupByLibrary.simpleMessage("Mapping"),
    "natMappingAddress": MessageLookupByLibrary.simpleMessage(
      "Address-dependent",
    ),
    "natMappingAddressPort": MessageLookupByLibrary.simpleMessage(
      "Address and port-dependent",
    ),
    "natMappingDependent": MessageLookupByLibrary.simpleMessage(
      "Destination-dependent",
    ),
    "natMappingIndependent": MessageLookupByLibrary.simpleMessage(
      "Endpoint-independent",
    ),
    "natPhaseBinding": MessageLookupByLibrary.simpleMessage("Binding"),
    "natPhaseFiltering": MessageLookupByLibrary.simpleMessage("Filtering"),
    "natPhaseMapping": MessageLookupByLibrary.simpleMessage("Mapping"),
    "natPortPreserve": MessageLookupByLibrary.simpleMessage(
      "Port Preservation",
    ),
    "natPreserved": MessageLookupByLibrary.simpleMessage("Preserved"),
    "natProxyTip": MessageLookupByLibrary.simpleMessage(
      "Through a proxy, the result reflects the outbound node side NAT, not your local network.",
    ),
    "natRandomized": MessageLookupByLibrary.simpleMessage("Randomized"),
    "natReady": MessageLookupByLibrary.simpleMessage(
      "Tap the button below to start",
    ),
    "natResult": MessageLookupByLibrary.simpleMessage("Result"),
    "natRetest": MessageLookupByLibrary.simpleMessage("Detect Again"),
    "natServer": MessageLookupByLibrary.simpleMessage("STUN Server"),
    "natServerCustom": MessageLookupByLibrary.simpleMessage("Custom Server"),
    "natServerHint": MessageLookupByLibrary.simpleMessage(
      "host:port, e.g. stun.example.com:3478",
    ),
    "natServerInvalid": MessageLookupByLibrary.simpleMessage(
      "Enter a valid host:port",
    ),
    "natStart": MessageLookupByLibrary.simpleMessage("Start Detection"),
    "natTest": MessageLookupByLibrary.simpleMessage("NAT Detection"),
    "natTestDesc": MessageLookupByLibrary.simpleMessage(
      "Check NAT type, external address and UDP connectivity",
    ),
    "natType": MessageLookupByLibrary.simpleMessage("NAT Type"),
    "natTypeBlocked": MessageLookupByLibrary.simpleMessage("UDP Blocked"),
    "natTypeCone": MessageLookupByLibrary.simpleMessage("Cone NAT"),
    "natTypeFullCone": MessageLookupByLibrary.simpleMessage("Full Cone NAT"),
    "natTypeOpen": MessageLookupByLibrary.simpleMessage("Open Internet"),
    "natTypePortRestricted": MessageLookupByLibrary.simpleMessage(
      "Port Restricted Cone NAT",
    ),
    "natTypeRestricted": MessageLookupByLibrary.simpleMessage(
      "Restricted Cone NAT",
    ),
    "natTypeSymmetric": MessageLookupByLibrary.simpleMessage("Symmetric NAT"),
    "natTypeUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "navBarHapticFeedback": MessageLookupByLibrary.simpleMessage(
      "Motion Feedback",
    ),
    "navBarHapticFeedbackDesc": MessageLookupByLibrary.simpleMessage(
      "Bottom navigation bar animation and haptic feedback",
    ),
    "navConnections": MessageLookupByLibrary.simpleMessage("Connections"),
    "navTools": MessageLookupByLibrary.simpleMessage("More"),
    "network": MessageLookupByLibrary.simpleMessage("Network"),
    "networkDesc": MessageLookupByLibrary.simpleMessage(
      "Modify network-related settings",
    ),
    "networkDetection": MessageLookupByLibrary.simpleMessage("Network"),
    "networkErrorRetryLater": MessageLookupByLibrary.simpleMessage(
      "Network error, please try again later",
    ),
    "networkFix": MessageLookupByLibrary.simpleMessage("Network Fix"),
    "networkFixDesc": MessageLookupByLibrary.simpleMessage(
      "Fix system network globe icon issue",
    ),
    "networkMatch": MessageLookupByLibrary.simpleMessage("Network Match"),
    "networkMatchHint": MessageLookupByLibrary.simpleMessage(
      "Enter IP, CIDR or Gateway:IP/CIDR",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("Network Speed"),
    "networkSpeedNotification": MessageLookupByLibrary.simpleMessage(
      "Speed in Notification",
    ),
    "networkSpeedNotificationDesc": MessageLookupByLibrary.simpleMessage(
      "Show speed and subscription info in notification bar",
    ),
    "networkType": MessageLookupByLibrary.simpleMessage("Network Type"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("Neutral"),
    "newLogsCount": m36,
    "noAnimation": MessageLookupByLibrary.simpleMessage("Default"),
    "noBackupFileFound": MessageLookupByLibrary.simpleMessage(
      "No backup file found",
    ),
    "noData": MessageLookupByLibrary.simpleMessage("No Data"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("No Hotkeys"),
    "noIcon": MessageLookupByLibrary.simpleMessage("No Icon"),
    "noInfo": MessageLookupByLibrary.simpleMessage("No Info"),
    "noMatchedLogs": MessageLookupByLibrary.simpleMessage("No matching logs"),
    "noMoreInfoDesc": MessageLookupByLibrary.simpleMessage("No more info"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("No Network"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("No Network App"),
    "noProxy": MessageLookupByLibrary.simpleMessage("No Proxy"),
    "noProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Please create or add a valid profile",
    ),
    "noResolve": MessageLookupByLibrary.simpleMessage("No Resolve"),
    "noStatusAvailable": MessageLookupByLibrary.simpleMessage("No Status"),
    "noUsageData": MessageLookupByLibrary.simpleMessage("No usage data"),
    "nodeExclusion": MessageLookupByLibrary.simpleMessage("Node Exclusion"),
    "nodeExclusionDesc": MessageLookupByLibrary.simpleMessage(
      "Exclude all matched nodes",
    ),
    "nodeExclusionPlaceholder": MessageLookupByLibrary.simpleMessage(
      "HK|Hong Kong|🇭🇰",
    ),
    "none": MessageLookupByLibrary.simpleMessage("None"),
    "notRecommended": MessageLookupByLibrary.simpleMessage("Not Recommended"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "Current proxy group cannot be selected.",
    ),
    "notUnlocked": MessageLookupByLibrary.simpleMessage("Not Unlocked"),
    "notificationHighPriority": MessageLookupByLibrary.simpleMessage(
      "High Priority",
    ),
    "notificationHighPriorityDesc": MessageLookupByLibrary.simpleMessage(
      "Foreground high-priority notification",
    ),
    "notificationHighPriorityTip": MessageLookupByLibrary.simpleMessage(
      "High-priority notifications can alleviate background core keep-alive issues on some customized systems. If your VPN service is currently running normally, it is recommended to keep this option disabled. Are you sure you want to enable it?",
    ),
    "ntp": MessageLookupByLibrary.simpleMessage("NTP"),
    "ntpDesc": MessageLookupByLibrary.simpleMessage("Use NTP time service"),
    "ntpInterval": MessageLookupByLibrary.simpleMessage("Update Interval"),
    "ntpPort": MessageLookupByLibrary.simpleMessage("Port"),
    "ntpServer": MessageLookupByLibrary.simpleMessage("Server"),
    "ntpStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "ntpStatusDesc": MessageLookupByLibrary.simpleMessage(
      "Enable NTP time service",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "No profile. Please add one.",
    ),
    "nullTip": m37,
    "numberRangeInvalid": m38,
    "numberTip": m39,
    "oneColumn": MessageLookupByLibrary.simpleMessage("1 Column"),
    "onlinePanel": MessageLookupByLibrary.simpleMessage("Online Panel"),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("Icon Only"),
    "onlyOtherApps": MessageLookupByLibrary.simpleMessage(
      "Third-Party Apps Only",
    ),
    "onlyShow": m40,
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage(
      "Proxy Traffic Only",
    ),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Only record proxy traffic",
    ),
    "openDashboard": MessageLookupByLibrary.simpleMessage("Open Zashboard"),
    "openRouterAdmin": MessageLookupByLibrary.simpleMessage("Open Gateway"),
    "openSettings": MessageLookupByLibrary.simpleMessage("Open Settings"),
    "operatorOrAsn": MessageLookupByLibrary.simpleMessage("Organization / ASN"),
    "options": MessageLookupByLibrary.simpleMessage("Options"),
    "organizationDomain": MessageLookupByLibrary.simpleMessage(
      "Organization / Domain",
    ),
    "other": MessageLookupByLibrary.simpleMessage("Other"),
    "otherContributors": MessageLookupByLibrary.simpleMessage(
      "Other Contributors (Random Order)",
    ),
    "otherSettings": MessageLookupByLibrary.simpleMessage("Enhanced Tools"),
    "otherSettingsDesc": MessageLookupByLibrary.simpleMessage(
      "Modify enhanced tool settings",
    ),
    "outboundMode": MessageLookupByLibrary.simpleMessage("Outbound Mode"),
    "override": MessageLookupByLibrary.simpleMessage("Override"),
    "overrideDesc": MessageLookupByLibrary.simpleMessage(
      "Override proxy configurations",
    ),
    "overrideDestination": MessageLookupByLibrary.simpleMessage(
      "Override Destination",
    ),
    "overrideDestinationDesc": MessageLookupByLibrary.simpleMessage(
      "Override destination with sniffed result",
    ),
    "overrideDns": MessageLookupByLibrary.simpleMessage("Override DNS"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "Override profile\'s DNS settings",
    ),
    "overrideExperimental": MessageLookupByLibrary.simpleMessage(
      "Override Experimental",
    ),
    "overrideExperimentalDesc": MessageLookupByLibrary.simpleMessage(
      "Override profile\'s Experimental settings",
    ),
    "overrideNtp": MessageLookupByLibrary.simpleMessage("Override NTP"),
    "overrideNtpDesc": MessageLookupByLibrary.simpleMessage(
      "Override profile\'s NTP settings",
    ),
    "overrideOriginRules": MessageLookupByLibrary.simpleMessage(
      "Override Original Rules",
    ),
    "overrideSniffer": MessageLookupByLibrary.simpleMessage("Override Sniffer"),
    "overrideSnifferDesc": MessageLookupByLibrary.simpleMessage(
      "Override profile\'s Sniffer settings",
    ),
    "overrideTestUrl": MessageLookupByLibrary.simpleMessage("Override Config"),
    "overrideTunnel": MessageLookupByLibrary.simpleMessage("Override Tunnel"),
    "overrideTunnelDesc": MessageLookupByLibrary.simpleMessage(
      "Override profile\'s Tunnel settings",
    ),
    "packageListPermissionDenied": MessageLookupByLibrary.simpleMessage(
      "Permission denied. Cannot access app list.",
    ),
    "packageListPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Permission to access installed apps is required. Grant now?",
    ),
    "palette": MessageLookupByLibrary.simpleMessage("Palette"),
    "parsePureIp": MessageLookupByLibrary.simpleMessage("Parse Pure IP"),
    "parsePureIpDesc": MessageLookupByLibrary.simpleMessage(
      "Parse pure IP connections",
    ),
    "password": MessageLookupByLibrary.simpleMessage("Password"),
    "paste": MessageLookupByLibrary.simpleMessage("Paste"),
    "patrolActionFlushDns": MessageLookupByLibrary.simpleMessage(
      "Flush DNS and FakeIP caches",
    ),
    "patrolActionReloadConfig": MessageLookupByLibrary.simpleMessage(
      "Reload the configuration",
    ),
    "patrolActionTestNodes": MessageLookupByLibrary.simpleMessage(
      "Retest all nodes",
    ),
    "patrolActionUpdateSubscription": MessageLookupByLibrary.simpleMessage(
      "Update the subscription now",
    ),
    "patrolAdviceChainHopDown": MessageLookupByLibrary.simpleMessage(
      "Retest all nodes. If the hop stays down, pick a different hop in the chain proxy settings.",
    ),
    "patrolAdviceChainIncomplete": MessageLookupByLibrary.simpleMessage(
      "Open the chain proxy settings and choose both the entry and the exit hop — that choice is yours, so patrol does not pick for you.",
    ),
    "patrolAdviceConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "Reload the configuration. If you did not edit it by hand, re-update the subscription to fetch a clean copy.",
    ),
    "patrolAdviceConfigUnavailable": MessageLookupByLibrary.simpleMessage(
      "Start the service, then come back — the check runs by itself.",
    ),
    "patrolAdviceFetch": MessageLookupByLibrary.simpleMessage(
      "Update the subscription again — the button below does exactly that, with the previous file kept as a snapshot in case the new one does not verify.",
    ),
    "patrolAdviceFetchHttp": MessageLookupByLibrary.simpleMessage(
      "If the status persists, the link itself is the problem: get a fresh subscription link from your provider and replace it.",
    ),
    "patrolAdviceFetchProxy": MessageLookupByLibrary.simpleMessage(
      "Start (or restart) the service, then update again. If the core is running and it still fails, run the live probes to see which hop breaks.",
    ),
    "patrolAdviceFetchTls": MessageLookupByLibrary.simpleMessage(
      "Check the device clock first — TLS rejects skewed time — then update again. If it persists, the provider\'s certificate is at fault.",
    ),
    "patrolAdviceLogConnection": MessageLookupByLibrary.simpleMessage(
      "Retest all nodes to separate dead nodes from a bad path. If most fail too, check the device network itself.",
    ),
    "patrolAdviceLogDns": MessageLookupByLibrary.simpleMessage(
      "Flush the DNS and FakeIP caches, then try again. If lookups still fail, the probes on this page show whether DNS answers at all.",
    ),
    "patrolAdviceLogRule": MessageLookupByLibrary.simpleMessage(
      "Reload the configuration so rule data is fetched and applied again.",
    ),
    "patrolAdviceLogTimeout": MessageLookupByLibrary.simpleMessage(
      "Retest all nodes and prefer a responsive one. Timeouts on every node point at the local network, not the nodes.",
    ),
    "patrolAdviceNodesNoData": MessageLookupByLibrary.simpleMessage(
      "Retest all nodes to get a first health reading.",
    ),
    "patrolAdviceNodesSomeDown": MessageLookupByLibrary.simpleMessage(
      "Retest all nodes and keep using the working ones. Dead entries usually recover, or are replaced on the next subscription update.",
    ),
    "patrolAdviceNodesWidespread": MessageLookupByLibrary.simpleMessage(
      "Check the device network and that the core is running, then retest. If the list itself went stale, updating the subscription helps too.",
    ),
    "patrolAdviceSubExpired": MessageLookupByLibrary.simpleMessage(
      "Renew the subscription with your provider, then update. The node list will not refresh until then.",
    ),
    "patrolAdviceSubNever": MessageLookupByLibrary.simpleMessage(
      "Update the subscription now. If it fails, this page shows exactly where.",
    ),
    "patrolAdviceSubNoProfile": MessageLookupByLibrary.simpleMessage(
      "Add or select a subscription on the profiles page first.",
    ),
    "patrolAdviceSubStale": MessageLookupByLibrary.simpleMessage(
      "Update the subscription now to refresh the node list.",
    ),
    "patrolAllGood": MessageLookupByLibrary.simpleMessage(
      "Everything looks good",
    ),
    "patrolAttentionNeeded": m41,
    "patrolCauseChainHopDown": MessageLookupByLibrary.simpleMessage(
      "One hop of the chain proxy failed its last test, so the whole two-hop path is down even if each side looks fine on its own.",
    ),
    "patrolCauseChainIncomplete": MessageLookupByLibrary.simpleMessage(
      "Chain proxy is switched on but an entry or exit hop is not chosen, so the chain cannot carry any traffic.",
    ),
    "patrolCauseConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "The core rejected the current configuration. The exact complaint is in the evidence below; until it validates, this config cannot run as-is.",
    ),
    "patrolCauseConfigUnavailable": MessageLookupByLibrary.simpleMessage(
      "The full config check needs the service running, so it has not run yet. Nothing says the config is broken — it is simply unchecked.",
    ),
    "patrolCauseLogConnection": MessageLookupByLibrary.simpleMessage(
      "Connections are failing while dialing out. Several in a row usually mean the network path or the chosen nodes — not the sites themselves.",
    ),
    "patrolCauseLogDns": MessageLookupByLibrary.simpleMessage(
      "Name lookups are failing: the app asks for a site\'s address and gets no answer. Until DNS answers, nothing downstream can connect.",
    ),
    "patrolCauseLogRule": MessageLookupByLibrary.simpleMessage(
      "Rule data (rule sets, geo data) is failing to load or apply, so traffic that depends on those rules cannot be routed as configured.",
    ),
    "patrolCauseLogTimeout": MessageLookupByLibrary.simpleMessage(
      "Connections start but never finish in time — the path is too slow or congested, or the far end is not responding.",
    ),
    "patrolCauseNodesNoData": MessageLookupByLibrary.simpleMessage(
      "No node has been speed-tested yet, so there is no evidence any of them works.",
    ),
    "patrolCauseNodesSomeDown": MessageLookupByLibrary.simpleMessage(
      "Some nodes failed their last speed test. The rest still work — this is single-node trouble, not an outage.",
    ),
    "patrolCauseNodesWidespread": MessageLookupByLibrary.simpleMessage(
      "Most tested nodes are down at once. Single nodes do not fail in packs — this points at the device network, the core, or the subscription itself.",
    ),
    "patrolCauseSubExpired": MessageLookupByLibrary.simpleMessage(
      "The subscription itself has expired at the provider, so updates stop and the node list freezes as it was.",
    ),
    "patrolCauseSubNever": MessageLookupByLibrary.simpleMessage(
      "This subscription has never been updated successfully, so there is no usable node list from it yet.",
    ),
    "patrolCauseSubNoProfile": MessageLookupByLibrary.simpleMessage(
      "No subscription is selected, so there is nothing to check, update or fix yet.",
    ),
    "patrolCauseSubStale": MessageLookupByLibrary.simpleMessage(
      "This subscription has not been refreshed for a long time. Node lists go stale quietly — entries die one by one until little still works.",
    ),
    "patrolChainHopDown": MessageLookupByLibrary.simpleMessage(
      "One chain hop looks down",
    ),
    "patrolChainIncomplete": MessageLookupByLibrary.simpleMessage(
      "Entry or exit is not selected yet",
    ),
    "patrolChainOff": MessageLookupByLibrary.simpleMessage(
      "Chain proxy is off",
    ),
    "patrolChainOn": MessageLookupByLibrary.simpleMessage("Chain proxy is on"),
    "patrolConfigChecking": MessageLookupByLibrary.simpleMessage(
      "Checking config…",
    ),
    "patrolConfigInvalid": MessageLookupByLibrary.simpleMessage(
      "Config check failed",
    ),
    "patrolConfigUnavailable": MessageLookupByLibrary.simpleMessage(
      "Start the service to run the full config check",
    ),
    "patrolConfigValid": MessageLookupByLibrary.simpleMessage(
      "Config check passed",
    ),
    "patrolDetailAdvice": MessageLookupByLibrary.simpleMessage("What to do"),
    "patrolDetailAi": MessageLookupByLibrary.simpleMessage("AI deep-dive"),
    "patrolDetailAiDesc": MessageLookupByLibrary.simpleMessage(
      "Send this problem\'s redacted diagnosis to your configured AI for ranked causes, impact and next steps. The local diagnosis above stays fully usable without it.",
    ),
    "patrolDetailBasis": MessageLookupByLibrary.simpleMessage(
      "What this is based on",
    ),
    "patrolDetailMeasured": MessageLookupByLibrary.simpleMessage(
      "Confirmed by live probes just now",
    ),
    "patrolDetailProbes": MessageLookupByLibrary.simpleMessage("Live probes"),
    "patrolDetailProbesAllOk": MessageLookupByLibrary.simpleMessage(
      "Every probe passed just now — the failure no longer reproduces. Updating again should work.",
    ),
    "patrolDetailProbesDesc": MessageLookupByLibrary.simpleMessage(
      "Re-walks the exact path a subscription update takes, step by step, right now — measured, not guessed.",
    ),
    "patrolDetailProbing": MessageLookupByLibrary.simpleMessage("Probing…"),
    "patrolDetailRaw": MessageLookupByLibrary.simpleMessage("Raw info"),
    "patrolDetailRepro": MessageLookupByLibrary.simpleMessage(
      "Check it yourself",
    ),
    "patrolDetailRunProbes": MessageLookupByLibrary.simpleMessage(
      "Run live probes",
    ),
    "patrolDetailWhy": MessageLookupByLibrary.simpleMessage("Why it happened"),
    "patrolFactCore": MessageLookupByLibrary.simpleMessage("Core"),
    "patrolFactCoreRunning": MessageLookupByLibrary.simpleMessage("Running"),
    "patrolFactCoreStopped": MessageLookupByLibrary.simpleMessage("Stopped"),
    "patrolFactHost": MessageLookupByLibrary.simpleMessage("Subscription host"),
    "patrolFactHttpStatus": MessageLookupByLibrary.simpleMessage("HTTP status"),
    "patrolFactMode": MessageLookupByLibrary.simpleMessage("Mode"),
    "patrolFactNodes": MessageLookupByLibrary.simpleMessage("Nodes"),
    "patrolFactOccurrences": m42,
    "patrolFactRecordedError": MessageLookupByLibrary.simpleMessage(
      "Recorded error",
    ),
    "patrolFactSample": MessageLookupByLibrary.simpleMessage("Log evidence"),
    "patrolFactTime": MessageLookupByLibrary.simpleMessage("Time"),
    "patrolFactWindow": m43,
    "patrolFix": MessageLookupByLibrary.simpleMessage("Fix"),
    "patrolFixApplied": MessageLookupByLibrary.simpleMessage(
      "Fix applied and verified",
    ),
    "patrolFixCancelled": MessageLookupByLibrary.simpleMessage("Fix cancelled"),
    "patrolFixConfirmDesc": MessageLookupByLibrary.simpleMessage(
      "The patrol report is rebuilt right after to verify the result. If a subscription update does not verify, the previous profile file is restored automatically.",
    ),
    "patrolFixConfirmTitle": MessageLookupByLibrary.simpleMessage(
      "Run this fix?",
    ),
    "patrolFixFailed": MessageLookupByLibrary.simpleMessage(
      "The fix did not go through",
    ),
    "patrolFixRolledBack": MessageLookupByLibrary.simpleMessage(
      "Fix did not verify — previous state restored",
    ),
    "patrolFixRunning": MessageLookupByLibrary.simpleMessage("Fix running…"),
    "patrolFixTrustSession": MessageLookupByLibrary.simpleMessage(
      "Don\'t ask again this session (low-risk fixes only)",
    ),
    "patrolLogConnection": MessageLookupByLibrary.simpleMessage(
      "Connection failures",
    ),
    "patrolLogDns": MessageLookupByLibrary.simpleMessage("DNS failures"),
    "patrolLogRule": MessageLookupByLibrary.simpleMessage("Rule problems"),
    "patrolLogTimeouts": MessageLookupByLibrary.simpleMessage("Timeouts"),
    "patrolMeasuredStage": m44,
    "patrolNoProblems": MessageLookupByLibrary.simpleMessage(
      "No problems found",
    ),
    "patrolNodesNoData": MessageLookupByLibrary.simpleMessage(
      "No speed-test data yet",
    ),
    "patrolNodesSomeDown": MessageLookupByLibrary.simpleMessage(
      "Some nodes are unavailable",
    ),
    "patrolNodesUnavailable": MessageLookupByLibrary.simpleMessage(
      "Unavailable",
    ),
    "patrolNodesUntested": MessageLookupByLibrary.simpleMessage("Untested"),
    "patrolNodesWidespread": MessageLookupByLibrary.simpleMessage(
      "Most nodes are unreachable — likely a network or subscription problem, not a single bad node",
    ),
    "patrolNodesWorking": MessageLookupByLibrary.simpleMessage("Working"),
    "patrolOutcomeApplied": MessageLookupByLibrary.simpleMessage("Applied"),
    "patrolOutcomeFailed": MessageLookupByLibrary.simpleMessage("Failed"),
    "patrolOutcomeRolledBack": MessageLookupByLibrary.simpleMessage(
      "Rolled back",
    ),
    "patrolOutcomeUndone": MessageLookupByLibrary.simpleMessage("Undone"),
    "patrolProbeDirect": MessageLookupByLibrary.simpleMessage("Direct fetch"),
    "patrolProbeDns": MessageLookupByLibrary.simpleMessage("DNS resolution"),
    "patrolProbeProxy": MessageLookupByLibrary.simpleMessage(
      "Fetch the way the app does",
    ),
    "patrolProbeProxyPort": MessageLookupByLibrary.simpleMessage(
      "Core proxy port",
    ),
    "patrolProbeSkipped": MessageLookupByLibrary.simpleMessage(
      "Not run — an earlier step already failed",
    ),
    "patrolProbeTcp": MessageLookupByLibrary.simpleMessage("TCP connection"),
    "patrolProbeTls": MessageLookupByLibrary.simpleMessage("TLS handshake"),
    "patrolRecheck": MessageLookupByLibrary.simpleMessage("Recheck"),
    "patrolRecordUndo": MessageLookupByLibrary.simpleMessage("Undo"),
    "patrolRecords": MessageLookupByLibrary.simpleMessage("Repair history"),
    "patrolRecordsEmpty": MessageLookupByLibrary.simpleMessage(
      "No repairs yet",
    ),
    "patrolReproConfig": MessageLookupByLibrary.simpleMessage(
      "This check re-runs every time the patrol page opens or the service state changes.",
    ),
    "patrolReproFetch": MessageLookupByLibrary.simpleMessage(
      "Tap Update on the subscription — if it still fails, the same failure is recorded again.",
    ),
    "patrolReproLogs": MessageLookupByLibrary.simpleMessage(
      "Use any failing node once and matching lines appear under Logs.",
    ),
    "patrolReproNodes": MessageLookupByLibrary.simpleMessage(
      "Run a speed test from the proxies page and compare the counts.",
    ),
    "patrolSectionCore": MessageLookupByLibrary.simpleMessage("Core & config"),
    "patrolSectionLink": MessageLookupByLibrary.simpleMessage("Mode & chain"),
    "patrolSectionLogs": MessageLookupByLibrary.simpleMessage("Log problems"),
    "patrolSectionNodes": MessageLookupByLibrary.simpleMessage("Node health"),
    "patrolSectionSubscription": MessageLookupByLibrary.simpleMessage(
      "Subscription",
    ),
    "patrolStageBadContent": MessageLookupByLibrary.simpleMessage(
      "The address answered, but what came back was empty or not a usable configuration, so the update was refused to protect the working profile.",
    ),
    "patrolStageDns": MessageLookupByLibrary.simpleMessage(
      "The subscription\'s domain name could not be resolved to an address. The request died at the very first step, before any connection existed.",
    ),
    "patrolStageHttp": m45,
    "patrolStageNameBadContent": MessageLookupByLibrary.simpleMessage(
      "the returned content",
    ),
    "patrolStageNameDns": MessageLookupByLibrary.simpleMessage(
      "DNS resolution",
    ),
    "patrolStageNameHttp": MessageLookupByLibrary.simpleMessage(
      "the server\'s answer",
    ),
    "patrolStageNameProxy": MessageLookupByLibrary.simpleMessage(
      "the core proxy hop",
    ),
    "patrolStageNameTcp": MessageLookupByLibrary.simpleMessage(
      "the connection",
    ),
    "patrolStageNameTimeout": MessageLookupByLibrary.simpleMessage(
      "waiting for an answer",
    ),
    "patrolStageNameTls": MessageLookupByLibrary.simpleMessage(
      "the TLS handshake",
    ),
    "patrolStageProxy": MessageLookupByLibrary.simpleMessage(
      "The fetch never got past your own core: while the core runs, subscription updates go through its local proxy port, and that hop refused or dropped the connection. The internet path was never reached.",
    ),
    "patrolStageTcp": MessageLookupByLibrary.simpleMessage(
      "The name resolved, but the server would not accept a connection — refused, reset, or unreachable at the network level.",
    ),
    "patrolStageTimeout": MessageLookupByLibrary.simpleMessage(
      "The fetch started and then stalled until it timed out. Nothing came back in time — a congested path or an unresponsive server.",
    ),
    "patrolStageTls": MessageLookupByLibrary.simpleMessage(
      "The connection opened, but the secure (TLS) handshake failed — the certificate or the encrypted greeting was rejected.",
    ),
    "patrolStageUnknown": MessageLookupByLibrary.simpleMessage(
      "The recorded error does not carry enough detail to name the failing step. Run the live probes below — they re-walk the same path and pin down where it breaks.",
    ),
    "patrolSubExpired": MessageLookupByLibrary.simpleMessage(
      "Subscription expired",
    ),
    "patrolSubLastUpdated": MessageLookupByLibrary.simpleMessage(
      "Last updated",
    ),
    "patrolSubNeverUpdated": MessageLookupByLibrary.simpleMessage(
      "Never updated",
    ),
    "patrolSubNoProfile": MessageLookupByLibrary.simpleMessage(
      "No profile selected",
    ),
    "patrolSubStale": MessageLookupByLibrary.simpleMessage(
      "Update overdue — refresh it manually once",
    ),
    "patrolSubUpdateFailed": MessageLookupByLibrary.simpleMessage(
      "The last update failed",
    ),
    "patrolVersion": MessageLookupByLibrary.simpleMessage("Version"),
    "pianoWave": MessageLookupByLibrary.simpleMessage("Piano Wave"),
    "pin": MessageLookupByLibrary.simpleMessage("Pin"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "Please bind WebDAV",
    ),
    "pleaseCloseSystemProxyFirst": MessageLookupByLibrary.simpleMessage(
      "Please close System Proxy first",
    ),
    "pleaseCloseTunFirst": MessageLookupByLibrary.simpleMessage(
      "Please close TUN first",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "Please enter a script name",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "Please enter the admin password",
    ),
    "pleaseUploadFile": MessageLookupByLibrary.simpleMessage(
      "Please upload a file",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "Please upload a valid QR code",
    ),
    "port": MessageLookupByLibrary.simpleMessage("Port"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage(
      "Please enter a different port",
    ),
    "portTip": m46,
    "pouringHourGlass": MessageLookupByLibrary.simpleMessage(
      "Pouring Hourglass",
    ),
    "pouringHourGlassRefined": MessageLookupByLibrary.simpleMessage(
      "Refined Hourglass",
    ),
    "powerSwitch": MessageLookupByLibrary.simpleMessage("Power"),
    "preferH3Desc": MessageLookupByLibrary.simpleMessage(
      "Prioritize DoH HTTP/3",
    ),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("Press a key"),
    "preview": MessageLookupByLibrary.simpleMessage("Preview"),
    "privateIp": MessageLookupByLibrary.simpleMessage(
      "Private / LAN IP Address",
    ),
    "profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "profileAndRules": MessageLookupByLibrary.simpleMessage("Profile & Rules"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("Please enter a valid interval"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("Please enter update interval"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "Profile modified. Disable auto-update?",
    ),
    "profileImportFailed": m47,
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter a profile name",
    ),
    "profileParseErrorDesc": MessageLookupByLibrary.simpleMessage(
      "Profile parse error",
    ),
    "profileSwitchFailed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t switch profiles. The current profile is unchanged; check it and try again",
    ),
    "profileSwitchFailedRollback": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t switch to the new profile, so the previous profile was restored",
    ),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter a valid URL",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "Please enter a profile URL",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("Profiles"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("Profile Sorting"),
    "progress": MessageLookupByLibrary.simpleMessage("Progress"),
    "project": MessageLookupByLibrary.simpleMessage("Project"),
    "providers": MessageLookupByLibrary.simpleMessage("Providers"),
    "provinceAndCity": MessageLookupByLibrary.simpleMessage("Province / City"),
    "proxies": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesCount": MessageLookupByLibrary.simpleMessage("Proxies"),
    "proxiesSetting": MessageLookupByLibrary.simpleMessage("Proxy Settings"),
    "proxyChains": MessageLookupByLibrary.simpleMessage("Proxy Chains"),
    "proxyDelayNotTested": MessageLookupByLibrary.simpleMessage("Not tested"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("Proxy Group"),
    "proxyGroupsCount": MessageLookupByLibrary.simpleMessage("Proxy Groups"),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage("Proxy Nameserver"),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "Resolve proxy node domains",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("Proxy Port"),
    "proxyPortDesc": MessageLookupByLibrary.simpleMessage(
      "Set the Clash listening port",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("Proxy Providers"),
    "proxyProvidersCount": MessageLookupByLibrary.simpleMessage(
      "Proxy Providers",
    ),
    "pulse": MessageLookupByLibrary.simpleMessage("Pulse"),
    "pulsingGrid": MessageLookupByLibrary.simpleMessage("Pulsing Grid"),
    "pumpingHeart": MessageLookupByLibrary.simpleMessage("Pumping Heart"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("Pure Black Mode"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QR Code"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage(
      "Scan QR code to import profile",
    ),
    "quicGoDisableEcn": MessageLookupByLibrary.simpleMessage(
      "Disable QUIC ECN",
    ),
    "quicGoDisableEcnDesc": MessageLookupByLibrary.simpleMessage(
      "Disable QUIC ECN",
    ),
    "quicGoDisableGso": MessageLookupByLibrary.simpleMessage(
      "Disable QUIC GSO",
    ),
    "quicGoDisableGsoDesc": MessageLookupByLibrary.simpleMessage(
      "Disable QUIC GSO",
    ),
    "quicPortSniffer": MessageLookupByLibrary.simpleMessage(
      "QUIC Port Sniffing",
    ),
    "quickResponse": MessageLookupByLibrary.simpleMessage("Quick Response"),
    "quickResponseDesc": MessageLookupByLibrary.simpleMessage(
      "Disconnect on network change (WiFi/Mobile)",
    ),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("Rainbow"),
    "realTimeSpeed": MessageLookupByLibrary.simpleMessage("Real-time Speed"),
    "reclaimableMemory": MessageLookupByLibrary.simpleMessage("Reclaimable"),
    "recovery": MessageLookupByLibrary.simpleMessage("Restore"),
    "recoveryAll": MessageLookupByLibrary.simpleMessage("Restore All Data"),
    "recoveryDecryptedTip": MessageLookupByLibrary.simpleMessage(
      "Decrypted and restored with the current password",
    ),
    "recoveryProfiles": MessageLookupByLibrary.simpleMessage(
      "Restore Profiles Only",
    ),
    "recoveryStrategy": MessageLookupByLibrary.simpleMessage(
      "Recovery Strategy",
    ),
    "recoveryStrategyDesc_compatible": MessageLookupByLibrary.simpleMessage(
      "Keep local items, merge backup by ID",
    ),
    "recoveryStrategyDesc_override": MessageLookupByLibrary.simpleMessage(
      "Clear local items and replace with backup",
    ),
    "recoveryStrategy_compatible": MessageLookupByLibrary.simpleMessage(
      "Compatible",
    ),
    "recoveryStrategy_override": MessageLookupByLibrary.simpleMessage(
      "Override",
    ),
    "recoverySuccess": MessageLookupByLibrary.simpleMessage(
      "Restore Successful",
    ),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redir Port"),
    "redo": MessageLookupByLibrary.simpleMessage("Redo"),
    "refreshAppList": MessageLookupByLibrary.simpleMessage("Refresh App List"),
    "refreshAppListConfirm": MessageLookupByLibrary.simpleMessage(
      "Refresh the app list?",
    ),
    "regExp": MessageLookupByLibrary.simpleMessage("RegExp"),
    "relatedSettings": MessageLookupByLibrary.simpleMessage("Related Settings"),
    "remote": MessageLookupByLibrary.simpleMessage("Remote"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "Backup data to WebDAV",
    ),
    "remoteDestination": MessageLookupByLibrary.simpleMessage(
      "Remote Destination",
    ),
    "remoteRecoveryDesc": MessageLookupByLibrary.simpleMessage(
      "Restore data from WebDAV",
    ),
    "remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "rename": MessageLookupByLibrary.simpleMessage("Rename"),
    "replace": MessageLookupByLibrary.simpleMessage("Replace"),
    "replaceAll": MessageLookupByLibrary.simpleMessage("Replace All"),
    "request": MessageLookupByLibrary.simpleMessage("Request"),
    "requests": MessageLookupByLibrary.simpleMessage("Recent"),
    "reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "resetIconCache": MessageLookupByLibrary.simpleMessage("Reset Icon Cache"),
    "resetIconCacheDesc": MessageLookupByLibrary.simpleMessage(
      "Reset the local icon cache? This is safe, the app will fetch icons from their remote links again automatically.",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to reset?",
    ),
    "resources": MessageLookupByLibrary.simpleMessage("External Resources"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage(
      "View external resources and rule sets",
    ),
    "respectRules": MessageLookupByLibrary.simpleMessage("Respect Rules"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "DNS connections follow Rules",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("Restart"),
    "restartApp": MessageLookupByLibrary.simpleMessage("Restart App"),
    "restartCoreDesc": MessageLookupByLibrary.simpleMessage(
      "Manually restart the core?",
    ),
    "restartCoreTitle": MessageLookupByLibrary.simpleMessage("Restart Core"),
    "restartTip": MessageLookupByLibrary.simpleMessage(
      "Restart TUN for changes to take effect",
    ),
    "restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "rightClickBehavior": MessageLookupByLibrary.simpleMessage("Right Click"),
    "ring": MessageLookupByLibrary.simpleMessage("Ring"),
    "ripple": MessageLookupByLibrary.simpleMessage("Ripple"),
    "rotatingCircle": MessageLookupByLibrary.simpleMessage("Rotating Circle"),
    "rotatingPlain": MessageLookupByLibrary.simpleMessage("Rotating Plain"),
    "routeTrace": MessageLookupByLibrary.simpleMessage("Route Trace"),
    "routeTraceChain": MessageLookupByLibrary.simpleMessage("Proxy Chain"),
    "routeTraceCheckedRules": MessageLookupByLibrary.simpleMessage(
      "Checked Rules",
    ),
    "routeTraceDesc": MessageLookupByLibrary.simpleMessage(
      "See how the core resolves and matches a domain or IP",
    ),
    "routeTraceDns": MessageLookupByLibrary.simpleMessage("DNS Resolution"),
    "routeTraceDnsBy": m48,
    "routeTraceDnsIp": MessageLookupByLibrary.simpleMessage(
      "The target is an IP, no resolution needed",
    ),
    "routeTraceDnsSkipped": MessageLookupByLibrary.simpleMessage(
      "No IP resolution was needed while matching",
    ),
    "routeTraceFinal": MessageLookupByLibrary.simpleMessage("Final Outbound"),
    "routeTraceHint": MessageLookupByLibrary.simpleMessage("Domain, IP or URL"),
    "routeTraceHostsHit": m49,
    "routeTraceInput": MessageLookupByLibrary.simpleMessage("Target"),
    "routeTraceModeDirect": MessageLookupByLibrary.simpleMessage(
      "Direct mode: all traffic goes direct",
    ),
    "routeTraceModeGlobal": MessageLookupByLibrary.simpleMessage(
      "Global mode: all traffic uses GLOBAL",
    ),
    "routeTraceNoMatch": MessageLookupByLibrary.simpleMessage(
      "No rule matched, using DIRECT",
    ),
    "routeTraceRules": MessageLookupByLibrary.simpleMessage("Rule Matching"),
    "routeTraceRulesSummary": m50,
    "routeTraceRulesTotal": m51,
    "routeTraceSkipMissing": MessageLookupByLibrary.simpleMessage(
      "Skipped, target not found",
    ),
    "routeTraceSkipPass": MessageLookupByLibrary.simpleMessage(
      "Skipped by PASS",
    ),
    "routeTraceSkipUdp": MessageLookupByLibrary.simpleMessage(
      "Skipped, no UDP support",
    ),
    "routeTraceStopped": MessageLookupByLibrary.simpleMessage(
      "Proxy is not running, route trace is unavailable",
    ),
    "routeTraceTrigger": MessageLookupByLibrary.simpleMessage("Triggered DNS"),
    "routeTraceTruncated": MessageLookupByLibrary.simpleMessage(
      "Only the first 3000 rules are shown",
    ),
    "routeTraceUdpUnsupported": MessageLookupByLibrary.simpleMessage(
      "This outbound does not support UDP",
    ),
    "routeTraceViewRules": MessageLookupByLibrary.simpleMessage(
      "View checked rules",
    ),
    "rule": MessageLookupByLibrary.simpleMessage("Rule"),
    "ruleName": MessageLookupByLibrary.simpleMessage("Rule Name"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("Rule Providers"),
    "ruleProvidersCount": MessageLookupByLibrary.simpleMessage(
      "Rule Providers",
    ),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("Rule Target"),
    "rulesCount": MessageLookupByLibrary.simpleMessage("Rules"),
    "runTime": MessageLookupByLibrary.simpleMessage("Uptime"),
    "runningMode": MessageLookupByLibrary.simpleMessage("Running Mode"),
    "runtimeConfig": MessageLookupByLibrary.simpleMessage("Runtime Config"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("Save changes?"),
    "saveSuccess": MessageLookupByLibrary.simpleMessage("Saved"),
    "saveTip": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to save?",
    ),
    "script": MessageLookupByLibrary.simpleMessage("Override Script"),
    "scriptDesc": MessageLookupByLibrary.simpleMessage(
      "Configure JavaScript override scripts",
    ),
    "scriptNotUsed": MessageLookupByLibrary.simpleMessage(
      "Do Not Use a Script",
    ),
    "scriptOtherOptions": MessageLookupByLibrary.simpleMessage(
      "Other Settings",
    ),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "seconds": MessageLookupByLibrary.simpleMessage("Seconds"),
    "secretCopied": MessageLookupByLibrary.simpleMessage(
      "Secret copied to clipboard",
    ),
    "selectAll": MessageLookupByLibrary.simpleMessage("Select All"),
    "selectBackupVersion": MessageLookupByLibrary.simpleMessage(
      "Select Backup Version",
    ),
    "selected": MessageLookupByLibrary.simpleMessage("Selected"),
    "selectedCountTitle": m52,
    "serviceReady": MessageLookupByLibrary.simpleMessage("Service Ready"),
    "serviceRunning": MessageLookupByLibrary.simpleMessage("Service Running"),
    "setcapFailedFallback": MessageLookupByLibrary.simpleMessage(
      "Could not grant file capabilities, falling back to setuid",
    ),
    "setcapNotInstalledFallback": MessageLookupByLibrary.simpleMessage(
      "setcap is not installed, falling back to setuid",
    ),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "sharedAddress": MessageLookupByLibrary.simpleMessage("Shared Address"),
    "show": MessageLookupByLibrary.simpleMessage("Show"),
    "showHiddenItems": MessageLookupByLibrary.simpleMessage(
      "Show Hidden Items",
    ),
    "showMenu": MessageLookupByLibrary.simpleMessage("Open Menu"),
    "showPanel": MessageLookupByLibrary.simpleMessage("Show Window"),
    "showStartSwitch": MessageLookupByLibrary.simpleMessage("Linkage Switch"),
    "showStartSwitchDesc": MessageLookupByLibrary.simpleMessage(
      "Show standalone switch on homepage",
    ),
    "shrink": MessageLookupByLibrary.simpleMessage("Compact"),
    "sidebarFlyout": MessageLookupByLibrary.simpleMessage("Hover Panel"),
    "sidebarFlyoutDelay": MessageLookupByLibrary.simpleMessage("Trigger Delay"),
    "sidebarFlyoutDesc": MessageLookupByLibrary.simpleMessage(
      "Show sidebar settings hover card",
    ),
    "sidebarFlyoutEntries": MessageLookupByLibrary.simpleMessage("Entries"),
    "sidebarFlyoutOutsideTools": MessageLookupByLibrary.simpleMessage(
      "Only show outside the “Tools” page",
    ),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("Silent Launch"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Start in the background",
    ),
    "size": MessageLookupByLibrary.simpleMessage("Size"),
    "skipDomain": MessageLookupByLibrary.simpleMessage("Skip Domain"),
    "skipDstAddress": MessageLookupByLibrary.simpleMessage(
      "Skip Destination IP",
    ),
    "skipLocalAuth": MessageLookupByLibrary.simpleMessage(
      "Skip Local Authentication",
    ),
    "skipLocalAuthDesc": MessageLookupByLibrary.simpleMessage(
      "Allow local access without credentials",
    ),
    "skipSrcAddress": MessageLookupByLibrary.simpleMessage("Skip Source IP"),
    "slow": MessageLookupByLibrary.simpleMessage("Slow"),
    "smartAutoStop": MessageLookupByLibrary.simpleMessage("Smart Auto-Stop"),
    "smartAutoStopDesc": MessageLookupByLibrary.simpleMessage(
      "Stop VPN on specific networks",
    ),
    "smartAutoStopServiceRunning": MessageLookupByLibrary.simpleMessage(
      "Smart Auto-Stop running",
    ),
    "smartDelayLaunch": MessageLookupByLibrary.simpleMessage("Smart Delay"),
    "smartDelayLaunchDesc": MessageLookupByLibrary.simpleMessage(
      "Launch after network connected",
    ),
    "sniffer": MessageLookupByLibrary.simpleMessage("Sniffer"),
    "snifferAddressHint": MessageLookupByLibrary.simpleMessage(
      "One address per line",
    ),
    "snifferDesc": MessageLookupByLibrary.simpleMessage(
      "Modify domain sniffer config",
    ),
    "snifferDomainHint": MessageLookupByLibrary.simpleMessage(
      "One domain per line",
    ),
    "snifferPorts": MessageLookupByLibrary.simpleMessage("Ports"),
    "snifferPortsHint": MessageLookupByLibrary.simpleMessage(
      "e.g.: 80, 8080-8880",
    ),
    "snifferStatus": MessageLookupByLibrary.simpleMessage("Status"),
    "snifferStatusDesc": MessageLookupByLibrary.simpleMessage(
      "Enable Sniffer service",
    ),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socks Port"),
    "sort": MessageLookupByLibrary.simpleMessage("Sort"),
    "source": MessageLookupByLibrary.simpleMessage("Source"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("Source IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("Special Proxy"),
    "specialRules": MessageLookupByLibrary.simpleMessage("Special Rules"),
    "speedTest": MessageLookupByLibrary.simpleMessage("Speed Test"),
    "speedTestAgain": MessageLookupByLibrary.simpleMessage("Test Again"),
    "speedTestChangeOutbound": MessageLookupByLibrary.simpleMessage(
      "Change Outbound",
    ),
    "speedTestClearHistoryTip": MessageLookupByLibrary.simpleMessage(
      "Clear all speed test history?",
    ),
    "speedTestConnecting": MessageLookupByLibrary.simpleMessage("Connecting"),
    "speedTestConnections": MessageLookupByLibrary.simpleMessage("Connections"),
    "speedTestConnectionsDesc": m53,
    "speedTestCoreStopped": MessageLookupByLibrary.simpleMessage(
      "Not started · Direct test",
    ),
    "speedTestCredit": MessageLookupByLibrary.simpleMessage(
      "Speed test servers are provided by public third parties. Special thanks to Apple, Cloudflare and Speedtest by Ookla.",
    ),
    "speedTestDataUsed": MessageLookupByLibrary.simpleMessage("Data Used"),
    "speedTestDuration": MessageLookupByLibrary.simpleMessage("Test Duration"),
    "speedTestErrorBlocked": MessageLookupByLibrary.simpleMessage(
      "Speed test unavailable",
    ),
    "speedTestErrorBlockedDesc": m54,
    "speedTestErrorNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "Check whether the outbound is available, then retry.",
    ),
    "speedTestErrorRejected": MessageLookupByLibrary.simpleMessage(
      "Blocked by rules",
    ),
    "speedTestErrorRejectedDesc": MessageLookupByLibrary.simpleMessage(
      "The current rules route the test domain to REJECT. Choose another outbound and retry.",
    ),
    "speedTestErrorTimeout": MessageLookupByLibrary.simpleMessage(
      "Speed test timed out",
    ),
    "speedTestErrorUnavailable": MessageLookupByLibrary.simpleMessage(
      "Cannot reach the speed test service",
    ),
    "speedTestExitNode": MessageLookupByLibrary.simpleMessage("Exit Node"),
    "speedTestFollowRules": MessageLookupByLibrary.simpleMessage(
      "Follow Rules",
    ),
    "speedTestHistory": MessageLookupByLibrary.simpleMessage("Test History"),
    "speedTestHistoryEmpty": MessageLookupByLibrary.simpleMessage(
      "No test history yet",
    ),
    "speedTestHistoryRetention": MessageLookupByLibrary.simpleMessage(
      "Kept for 14 days",
    ),
    "speedTestJitter": MessageLookupByLibrary.simpleMessage("Jitter"),
    "speedTestLoadedLatency": MessageLookupByLibrary.simpleMessage(
      "Loaded Latency",
    ),
    "speedTestManual": MessageLookupByLibrary.simpleMessage("Manual"),
    "speedTestMobileDataTip": MessageLookupByLibrary.simpleMessage(
      "You are on mobile data. One test may use hundreds of MB. Continue?",
    ),
    "speedTestMultiThread": MessageLookupByLibrary.simpleMessage("Multi"),
    "speedTestOutbound": MessageLookupByLibrary.simpleMessage("Outbound"),
    "speedTestPacketLoss": MessageLookupByLibrary.simpleMessage("Packet Loss"),
    "speedTestProbing": MessageLookupByLibrary.simpleMessage(
      "Detecting outbound…",
    ),
    "speedTestProtocol": MessageLookupByLibrary.simpleMessage("Protocol"),
    "speedTestProtocolDesc": MessageLookupByLibrary.simpleMessage(
      "HTTP/3 runs over QUIC (UDP); if unavailable it falls back to HTTP/2, and to HTTP/1.1 if HTTP/2 is unavailable too",
    ),
    "speedTestProtocolFallback": m55,
    "speedTestQuality": MessageLookupByLibrary.simpleMessage("Network Quality"),
    "speedTestReady": MessageLookupByLibrary.simpleMessage("Ready"),
    "speedTestRealtime": MessageLookupByLibrary.simpleMessage(
      "Realtime Throughput",
    ),
    "speedTestResponsiveness": MessageLookupByLibrary.simpleMessage(
      "Responsiveness",
    ),
    "speedTestRoute": MessageLookupByLibrary.simpleMessage("Route Rule"),
    "speedTestServer": MessageLookupByLibrary.simpleMessage("Test Server"),
    "speedTestServerAutoDesc": MessageLookupByLibrary.simpleMessage(
      "Automatically select Speedtest server",
    ),
    "speedTestSettings": MessageLookupByLibrary.simpleMessage(
      "Speed Test Settings",
    ),
    "speedTestSingleThread": MessageLookupByLibrary.simpleMessage("Single"),
    "speedTestStart": MessageLookupByLibrary.simpleMessage("Start Test"),
    "speedTestStreams": m56,
    "speedTestSwitchProvider": m57,
    "speedTestUseSystemDns": MessageLookupByLibrary.simpleMessage(
      "Resolve with System DNS",
    ),
    "speedTestUseSystemDnsDesc": MessageLookupByLibrary.simpleMessage(
      "When enabled, the selected speed test server is always resolved with system DNS, which can help in some cases",
    ),
    "spinningCircle": MessageLookupByLibrary.simpleMessage("Spinning Circle"),
    "spinningLines": MessageLookupByLibrary.simpleMessage("Spinning Lines"),
    "squareCircle": MessageLookupByLibrary.simpleMessage("Square Circle"),
    "stackMode": MessageLookupByLibrary.simpleMessage("Stack Mode"),
    "standard": MessageLookupByLibrary.simpleMessage("Standard"),
    "start": MessageLookupByLibrary.simpleMessage("Start"),
    "startSwitchOffLabel": MessageLookupByLibrary.simpleMessage(
      "Text when off",
    ),
    "startSwitchOnLabel": MessageLookupByLibrary.simpleMessage("Text when on"),
    "startSwitchOutlined": MessageLookupByLibrary.simpleMessage("Outlined"),
    "startSwitchPersonalized": MessageLookupByLibrary.simpleMessage(
      "Personalized Display",
    ),
    "startSwitchStyle": MessageLookupByLibrary.simpleMessage("Style"),
    "startSwitchTonal": MessageLookupByLibrary.simpleMessage("Tonal"),
    "startTest": MessageLookupByLibrary.simpleMessage("Delay Test"),
    "startVpn": MessageLookupByLibrary.simpleMessage("Starting..."),
    "status": MessageLookupByLibrary.simpleMessage("Status"),
    "statusDesc": MessageLookupByLibrary.simpleMessage(
      "Uses system DNS when disabled",
    ),
    "stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("Stopping..."),
    "storeFix": MessageLookupByLibrary.simpleMessage("Store Fix"),
    "storeFixDesc": MessageLookupByLibrary.simpleMessage(
      "Fix Play Store download issues",
    ),
    "strictRoute": MessageLookupByLibrary.simpleMessage("Strict Route"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "Use TUN strict routing mode",
    ),
    "style": MessageLookupByLibrary.simpleMessage("Style"),
    "subRule": MessageLookupByLibrary.simpleMessage("Sub Rule"),
    "submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "success": MessageLookupByLibrary.simpleMessage("Success"),
    "switchLabel": MessageLookupByLibrary.simpleMessage("Switch"),
    "switchToDomesticIp": MessageLookupByLibrary.simpleMessage(
      "Get Domestic IP",
    ),
    "sync": MessageLookupByLibrary.simpleMessage("Sync"),
    "syncAll": MessageLookupByLibrary.simpleMessage("Sync All"),
    "syncDelayAnimation": MessageLookupByLibrary.simpleMessage(
      "Sync animation to other pages",
    ),
    "syncFailed": MessageLookupByLibrary.simpleMessage("Sync Failed"),
    "system": MessageLookupByLibrary.simpleMessage("System"),
    "systemApp": MessageLookupByLibrary.simpleMessage("System App"),
    "systemDns": MessageLookupByLibrary.simpleMessage("DNS"),
    "systemExplicitAdapt": MessageLookupByLibrary.simpleMessage(
      "Adaptive path",
    ),
    "systemExplicitAdaptDesc": MessageLookupByLibrary.simpleMessage(
      "If traffic stalls, check immediately and only switch the manual group carrying it. Two failures on different check addresses are required, then stuck connections are released. Automatic groups can no longer fall back to direct. The subscription is not edited.",
    ),
    "systemExplicitApplyState": MessageLookupByLibrary.simpleMessage(
      "Settings application unconfirmed",
    ),
    "systemExplicitApplyUnconfirmed": m58,
    "systemExplicitBlockAds": MessageLookupByLibrary.simpleMessage("Block ads"),
    "systemExplicitBlockAdsDesc": MessageLookupByLibrary.simpleMessage(
      "Off by default. Rejects ad domains via the Mihomo GEOSITE category-ads-all category. Replaces only same-category ad rules in the profile; unrelated rules remain.",
    ),
    "systemExplicitBlockTunUdp": MessageLookupByLibrary.simpleMessage(
      "Block all UDP inside VPN",
    ),
    "systemExplicitBlockTunUdpDesc": MessageLookupByLibrary.simpleMessage(
      "Off by default. Drops IPv4/IPv6 UDP entering this app’s TUN, including UDP DNS, regardless of routing mode. Calls, video, QUIC, games and DNS may fail. TCP/TLS, disguised traffic and traffic outside the VPN are not covered; inactive when VPN is stopped.",
    ),
    "systemExplicitBlockWebRtc": MessageLookupByLibrary.simpleMessage(
      "Block WebRTC/STUN/TURN",
    ),
    "systemExplicitBlockWebRtcDesc": MessageLookupByLibrary.simpleMessage(
      "Off by default. Rejects hostnames containing stun/turn and Google STUN by domain, plus UDP 3478-3480, 5349-5355 and 19302-19305. May disrupt calls; disguised traffic is not covered, so it cannot block all WebRTC.",
    ),
    "systemExplicitChinaDirect": MessageLookupByLibrary.simpleMessage(
      "China IPs and domains direct",
    ),
    "systemExplicitChinaDirectDesc": MessageLookupByLibrary.simpleMessage(
      "Uses Mihomo GEOIP/GEOSITE China rules. Replaces only same-category China IP/domain rules; unrelated rules remain.",
    ),
    "systemExplicitChinaDnsDirect": MessageLookupByLibrary.simpleMessage(
      "China public DNS direct (privacy exception)",
    ),
    "systemExplicitChinaDnsDirectDesc": MessageLookupByLibrary.simpleMessage(
      "Off by default. Listed Chinese public DNS endpoints bypass the proxy and may expose queries to the local network/provider. China-direct can also match these endpoints even if this switch is off.",
    ),
    "systemExplicitDirectExceptionModeDesc":
        MessageLookupByLibrary.simpleMessage(
          "China direct, public DNS direct and LAN direct only work in rule mode; they contradict global/direct routing. Switching restores your saved choices. Interception options work in every mode and are unaffected.",
        ),
    "systemExplicitExceptionsInactive": MessageLookupByLibrary.simpleMessage(
      "Direct exceptions are not active in this mode",
    ),
    "systemExplicitExceptionsInactiveDesc":
        MessageLookupByLibrary.simpleMessage(
          "China direct, public DNS direct and LAN direct only apply in rule mode. Interception options (privacy, WebRTC, ads) stay active in every mode.",
        ),
    "systemExplicitInactive": MessageLookupByLibrary.simpleMessage(
      "Routing options are not active",
    ),
    "systemExplicitInactiveDesc": MessageLookupByLibrary.simpleMessage(
      "The current mode bypasses these rules. Saved choices resume in rule mode; notification privacy remains enabled.",
    ),
    "systemExplicitInterceptionActive": MessageLookupByLibrary.simpleMessage(
      "Interception is active in this mode",
    ),
    "systemExplicitInterceptionActiveDesc":
        MessageLookupByLibrary.simpleMessage(
          "Privacy, WebRTC and ad blocking keep working in global/direct mode.",
        ),
    "systemExplicitIntro": MessageLookupByLibrary.simpleMessage(
      "Applied after scripts and the profile without editing it. Routing options pause in global or direct mode and saved choices resume in rule mode.",
    ),
    "systemExplicitLanDirect": MessageLookupByLibrary.simpleMessage(
      "LAN IPs and domains direct",
    ),
    "systemExplicitLanDirectDesc": MessageLookupByLibrary.simpleMessage(
      "Matches private, loopback and link-local ranges plus .local, .lan and home.arpa; direct traffic bypasses proxies.",
    ),
    "systemExplicitLastSwitch": MessageLookupByLibrary.simpleMessage(
      "Last switch",
    ),
    "systemExplicitLimits": MessageLookupByLibrary.simpleMessage(
      "DNS and VPN-disconnect limits",
    ),
    "systemExplicitLimitsDesc": MessageLookupByLibrary.simpleMessage(
      "DNS is handled only for traffic routed through this app’s TUN and core DNS hijack. System VPN exclusions/bypass and app-encrypted DoH/DoT are not universally covered. VPN-disconnect lockdown must be enabled in Android system VPN settings (“Always-on” and “Block connections without VPN”, if offered); this app cannot enforce that system lock.",
    ),
    "systemExplicitNoneYet": MessageLookupByLibrary.simpleMessage("None yet"),
    "systemExplicitPrivacy": MessageLookupByLibrary.simpleMessage("Privacy"),
    "systemExplicitPrivacyDesc": MessageLookupByLibrary.simpleMessage(
      "Hides the profile name in notifications and blocks local discovery.",
    ),
    "systemExplicitRuleModeDesc": MessageLookupByLibrary.simpleMessage(
      "This option needs rule mode. Switching restores saved explicit routing choices.",
    ),
    "systemExplicitRuleModeNotApplied": MessageLookupByLibrary.simpleMessage(
      "Rule mode was not applied; option not enabled.",
    ),
    "systemExplicitRuleModeTitle": MessageLookupByLibrary.simpleMessage(
      "Switch to rule mode?",
    ),
    "systemExplicitSubtitle": MessageLookupByLibrary.simpleMessage(
      "Adaptive path, privacy, China direct",
    ),
    "systemExplicitSwitch": MessageLookupByLibrary.simpleMessage("Switch"),
    "systemExplicitTitle": MessageLookupByLibrary.simpleMessage(
      "System options",
    ),
    "systemFont": MessageLookupByLibrary.simpleMessage("System Font"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("System Proxy"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage("Set system proxy"),
    "tab": MessageLookupByLibrary.simpleMessage("Tab"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP Concurrent"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage(
      "Allow concurrent TCP connections",
    ),
    "testAllDelay": MessageLookupByLibrary.simpleMessage("Test all groups"),
    "testUrl": MessageLookupByLibrary.simpleMessage("Test URL"),
    "testing": MessageLookupByLibrary.simpleMessage("Testing"),
    "textScale": MessageLookupByLibrary.simpleMessage("Text Scaling"),
    "theme": MessageLookupByLibrary.simpleMessage("Theme"),
    "themeColor": MessageLookupByLibrary.simpleMessage("Theme Color"),
    "themeDesc": MessageLookupByLibrary.simpleMessage(
      "Set theme color options",
    ),
    "themeMode": MessageLookupByLibrary.simpleMessage("Theme Mode"),
    "threeBounce": MessageLookupByLibrary.simpleMessage("Three Bounce"),
    "threeColumns": MessageLookupByLibrary.simpleMessage("3 Columns"),
    "threeInOut": MessageLookupByLibrary.simpleMessage("Three In Out"),
    "tight": MessageLookupByLibrary.simpleMessage("Compact"),
    "time": MessageLookupByLibrary.simpleMessage("Time"),
    "tip": MessageLookupByLibrary.simpleMessage("Tip"),
    "titleTooLong": MessageLookupByLibrary.simpleMessage(
      "Title is too long, maximum 20 characters supported",
    ),
    "tlsPortSniffer": MessageLookupByLibrary.simpleMessage("TLS Port Sniffing"),
    "toggle": MessageLookupByLibrary.simpleMessage("Toggle"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("Tonal Spot"),
    "tooManyRules": MessageLookupByLibrary.simpleMessage("Max 5 rules allowed"),
    "toolConnectivityDesc": MessageLookupByLibrary.simpleMessage(
      "Check common services, with per-node batch testing",
    ),
    "toolHistoryClear": MessageLookupByLibrary.simpleMessage("Clear history"),
    "toolSpeedTestDesc": MessageLookupByLibrary.simpleMessage(
      "Measure download, upload and latency",
    ),
    "toolbox": MessageLookupByLibrary.simpleMessage("Toolbox"),
    "toolboxDesc": MessageLookupByLibrary.simpleMessage(
      "Network diagnostics, debugging and utilities",
    ),
    "toolboxEditTip": MessageLookupByLibrary.simpleMessage(
      "Tap a card to change its size, long-press and drag to rearrange",
    ),
    "toolboxEditTipDesktop": MessageLookupByLibrary.simpleMessage(
      "Click a card to change its size, drag to rearrange",
    ),
    "toolboxEditTipTv": MessageLookupByLibrary.simpleMessage(
      "Select a card and press OK to change its size",
    ),
    "tools": MessageLookupByLibrary.simpleMessage("Tools"),
    "totalTraffic": MessageLookupByLibrary.simpleMessage("Total Traffic"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxy Port"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("Traffic Usage"),
    "trayClickBehavior": MessageLookupByLibrary.simpleMessage(
      "Tray Click Behavior",
    ),
    "trayEnhancement": MessageLookupByLibrary.simpleMessage("Tray Enhancement"),
    "trayEnhancementDesc": MessageLookupByLibrary.simpleMessage(
      "Control proxy groups via tray menu",
    ),
    "trayIconInvert": MessageLookupByLibrary.simpleMessage("Invert Tray Icon"),
    "trayIconInvertDesc": MessageLookupByLibrary.simpleMessage(
      "Invert the current tray icon color",
    ),
    "tryManualRefresh": MessageLookupByLibrary.simpleMessage(
      "Please try manual refresh",
    ),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage(
      "Use TUN to take over device traffic",
    ),
    "tunEnableRequireAdmin": MessageLookupByLibrary.simpleMessage(
      "Enabling the TUN virtual network adapter requires Administrator or ROOT privileges.",
    ),
    "tunVirtualAddress": MessageLookupByLibrary.simpleMessage(
      "TUN Virtual Network Adapter",
    ),
    "tunnel": MessageLookupByLibrary.simpleMessage("Tunnel"),
    "tunnelAddress": MessageLookupByLibrary.simpleMessage("Listen Address"),
    "tunnelAddressHint": MessageLookupByLibrary.simpleMessage(
      "e.g.: 127.0.0.1:6553",
    ),
    "tunnelDesc": MessageLookupByLibrary.simpleMessage(
      "Use traffic forwarding tunnel",
    ),
    "tunnelList": MessageLookupByLibrary.simpleMessage("Forwarding List"),
    "tunnelNetwork": MessageLookupByLibrary.simpleMessage("Network Protocol"),
    "tunnelNetworkHint": MessageLookupByLibrary.simpleMessage("e.g.: tcp, udp"),
    "tunnelProxy": MessageLookupByLibrary.simpleMessage("Proxy Name"),
    "tunnelProxyHint": MessageLookupByLibrary.simpleMessage(
      "e.g.: proxy (optional)",
    ),
    "tunnelTarget": MessageLookupByLibrary.simpleMessage("Target Address"),
    "tunnelTargetHint": MessageLookupByLibrary.simpleMessage(
      "e.g.: 114.114.114.114:53",
    ),
    "tvScanImport": MessageLookupByLibrary.simpleMessage("Scan / LAN Import"),
    "tvScanImportDesc": MessageLookupByLibrary.simpleMessage(
      "Scan QR or push profile to TV via LAN",
    ),
    "tvScanManualUrl": MessageLookupByLibrary.simpleMessage(
      "Or enter directly in phone browser:",
    ),
    "tvScanNoNetwork": MessageLookupByLibrary.simpleMessage(
      "No available LAN detected, please check Wi-Fi",
    ),
    "tvScanStep1": MessageLookupByLibrary.simpleMessage(
      "Ensure phone and TV are on the same Wi-Fi network",
    ),
    "tvScanStep2": MessageLookupByLibrary.simpleMessage(
      "Scan the QR code with a supported camera or browser",
    ),
    "tvScanStep3": MessageLookupByLibrary.simpleMessage(
      "Paste subscription URL or upload profile on the webpage and push",
    ),
    "tvScanSuccess": MessageLookupByLibrary.simpleMessage(
      "Profile received, importing...",
    ),
    "tvScanWaiting": MessageLookupByLibrary.simpleMessage(
      "Waiting for profile from phone...",
    ),
    "twoColumns": MessageLookupByLibrary.simpleMessage("2 Columns"),
    "unableToUpdateCurrentProfileDesc": MessageLookupByLibrary.simpleMessage(
      "Unable to update current profile",
    ),
    "unauthorized": MessageLookupByLibrary.simpleMessage("Unauthorized"),
    "undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("Unified Delay"),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "Exclude handshake delays from testing",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "unlocked": MessageLookupByLibrary.simpleMessage("Completed"),
    "unnamed": MessageLookupByLibrary.simpleMessage("Unnamed"),
    "unpin": MessageLookupByLibrary.simpleMessage("Unpin"),
    "update": MessageLookupByLibrary.simpleMessage("Update"),
    "updateChecksumMismatch": MessageLookupByLibrary.simpleMessage(
      "The downloaded file failed SHA-256 verification and was deleted. Nothing was installed.",
    ),
    "updateDesktopNote": MessageLookupByLibrary.simpleMessage(
      "In-app install is not available on this platform yet; opening the release page.",
    ),
    "updateDirectNote": MessageLookupByLibrary.simpleMessage(
      "The core is not running, so this download goes direct instead of through the local proxy.",
    ),
    "updateInstallLaunch": MessageLookupByLibrary.simpleMessage(
      "The installer is starting. The app will close so the update can replace its files.",
    ),
    "updateInstallPermissionNote": MessageLookupByLibrary.simpleMessage(
      "Android may ask to allow installs from this app (the REQUEST_INSTALL_PACKAGES permission, used only for updates). Some phones\' security scanners warn about any self-update — this file is handed to the installer only after its SHA-256 matches the release\'s SHA256SUMS.",
    ),
    "updateNoMatchingAsset": MessageLookupByLibrary.simpleMessage(
      "No installer for this device was found in this release. Opening the release page instead.",
    ),
    "updateProgressTitle": MessageLookupByLibrary.simpleMessage(
      "Downloading update",
    ),
    "updateSumsMissing": MessageLookupByLibrary.simpleMessage(
      "This release has no verifiable SHA256SUMS entry for the installer, so an in-app download cannot be verified. Opening the release page instead.",
    ),
    "updateTime": MessageLookupByLibrary.simpleMessage("Update Time"),
    "upload": MessageLookupByLibrary.simpleMessage("Upload"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage("Get profile via URL"),
    "urlTip": m59,
    "useGlobalScriptOverride": MessageLookupByLibrary.simpleMessage(
      "Script Override",
    ),
    "useHosts": MessageLookupByLibrary.simpleMessage("Use Hosts"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("Use System Hosts"),
    "userAuth": MessageLookupByLibrary.simpleMessage("User Authentication"),
    "userAuthEmpty": MessageLookupByLibrary.simpleMessage(
      "No authentication configured, LAN connections do not require credentials",
    ),
    "username": MessageLookupByLibrary.simpleMessage("Username"),
    "usernameCannotContainColon": MessageLookupByLibrary.simpleMessage(
      "Username cannot contain colons",
    ),
    "value": MessageLookupByLibrary.simpleMessage("Value"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("Vibrant"),
    "view": MessageLookupByLibrary.simpleMessage("View"),
    "viewDetailedIpData": MessageLookupByLibrary.simpleMessage(
      "View Detailed IP Data",
    ),
    "vpnDesc": MessageLookupByLibrary.simpleMessage("VPN-related settings"),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "Route traffic via VpnService",
    ),
    "vpnSystemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "Attach HTTP proxy to VpnService",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage(
      "Restart VPN to apply changes",
    ),
    "wakelock": MessageLookupByLibrary.simpleMessage("Wakelock"),
    "wakelockDescription": MessageLookupByLibrary.simpleMessage(
      "Keeps the screen on and app active in the background without requiring special CPU wakelock permissions.",
    ),
    "wanderingCubes": MessageLookupByLibrary.simpleMessage("Wandering Cubes"),
    "wave": MessageLookupByLibrary.simpleMessage("Wave"),
    "waveSpinner": MessageLookupByLibrary.simpleMessage("Wave Spinner"),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage(
      "WebDAV Configuration",
    ),
    "whitelist": MessageLookupByLibrary.simpleMessage("Whitelist"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("Whitelist Mode"),
    "writeToSystem": MessageLookupByLibrary.simpleMessage("Write to System"),
    "writeToSystemDesc": MessageLookupByLibrary.simpleMessage(
      "Requires administrator privileges",
    ),
    "xattrUnsupportedFallback": MessageLookupByLibrary.simpleMessage(
      "The filesystem does not support file capabilities, falling back to setuid",
    ),
    "years": m60,
  };
}
