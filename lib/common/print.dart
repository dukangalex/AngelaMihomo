import 'package:angelamihomo/enum/enum.dart';
import 'package:angelamihomo/models/models.dart';
import 'package:angelamihomo/state.dart';
import 'package:cupertino_ui/cupertino_ui.dart';

class CommonPrint {
  static CommonPrint? _instance;

  CommonPrint._internal();

  factory CommonPrint() {
    _instance ??= CommonPrint._internal();
    return _instance!;
  }

  void log(String? text) => _dispatch(text, LogLevel.info);

  void debug(String? text) => _dispatch(text, LogLevel.debug);

  void warn(String? text) => _dispatch(text, LogLevel.warning);

  void error(String? text) => _dispatch(text, LogLevel.error);

  void _dispatch(String? text, LogLevel level) {
    final safeText = redactSensitiveText(text ?? '');
    debugPrint('[APP] $safeText');
    if (!globalState.isInit) {
      return;
    }
    globalState.appController.addLog(Log.app(safeText, level: level));
  }
}

final commonPrint = CommonPrint();
