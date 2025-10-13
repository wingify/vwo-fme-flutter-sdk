import 'package:flutter/services.dart';
import 'package:vwo_fme_flutter_sdk/vwo.dart';

class FmeConfig {

  static const _methodChannel = MethodChannel('vwo_fme_flutter_sdk');

  /// Sets the session data for the current FME session.
  ///
  /// [sessionData] is a map containing session information.
  /// It must contain a 'sessionId' key with a Long value.
  static Future<bool> setSessionData(Map<String, dynamic> sessionData) async {
    try {
      await _methodChannel.invokeMethod('setSessionData', sessionData);
      return true;
    } catch (e) {
      String details;
      if (e is PlatformException) {
        details = e.message ?? '';
      } else {
        details = e.toString();
      }
      VWO.logMessage('VWO: Failed to set session data $details');
      return false;
    }
  }
}