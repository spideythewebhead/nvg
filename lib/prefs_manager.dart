import 'package:file_manager/fse_view_type.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kFseViewType = 'option_fse_view_type';
const _kShowHidden = 'option_show_hidden';

class PrefsManager extends ChangeNotifier {
  static PrefsManager get instance => _instance!;
  static PrefsManager? _instance;

  static Future<PrefsManager> init() async {
    PrefsManager? instance = _instance;

    if (instance == null) {
      instance = PrefsManager();
      await instance._init();
    }

    return _instance = instance;
  }

  late final SharedPreferences _sharedPrefs;

  late FseViewType _fseViewType;
  FseViewType get fseViewType => _fseViewType;

  late bool _showHidden;
  bool get showHidden => _showHidden;

  Future<void> _init() async {
    _sharedPrefs = await SharedPreferences.getInstance();

    _fseViewType = FseViewType.values[_sharedPrefs.getInt(_kFseViewType) ?? 0];
    _showHidden = _sharedPrefs.getBool(_kShowHidden) ?? false;
  }

  void changeFseViewType(FseViewType type) {
    try {
      _sharedPrefs.setInt(_kFseViewType, type.index);
      _fseViewType = type;
      notifyListeners();
    } catch (_) {}
  }

  void changeShowHidden(bool show) {
    try {
      _sharedPrefs.setBool(_kShowHidden, show);
      _showHidden = show;
      notifyListeners();
    } catch (_) {}
  }
}
