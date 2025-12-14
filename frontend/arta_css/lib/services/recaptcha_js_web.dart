// Web implementation using dart:js_interop

import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('window.location.hostname')
external String get _jsHostname;

String getCurrentHost() {
  return _jsHostname;
}

@JS('executeRecaptcha')
external JSPromise<JSString> _jsExecuteRecaptcha(JSString action);

@JS('showRecaptchaBadge')
external void _jsShowRecaptchaBadge();

@JS('hideRecaptchaBadge')
external void _jsHideRecaptchaBadge();

Future<String?> executeRecaptcha(String action) async {
  try {
    final result = await _jsExecuteRecaptcha(action.toJS).toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('RecaptchaService: JS interop error: $e');
    return null;
  }
}

void showRecaptchaBadge() {
  try {
    _jsShowRecaptchaBadge();
  } catch (_) {
    // Silent fail
  }
}

void hideRecaptchaBadge() {
  try {
    _jsHideRecaptchaBadge();
  } catch (_) {
    // Silent fail
  }
}
