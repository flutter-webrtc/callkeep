import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart'
    show
        AlertDialog,
        BuildContext,
        Navigator,
        Text,
        TextButton,
        Widget,
        showDialog;
import 'package:flutter/services.dart' show MethodCall, MethodChannel;

import 'actions.dart';
import 'event.dart';

bool get isIOS => Platform.isIOS;
bool get supportConnectionService =>
    !isIOS && int.parse(Platform.version) >= 23;

class FlutterCallkeep extends EventManager {
  factory FlutterCallkeep() {
    return _instance;
  }
  FlutterCallkeep._internal() {
    _event.setMethodCallHandler(eventListener);
  }
  static final FlutterCallkeep _instance = FlutterCallkeep._internal();
  static const MethodChannel _channel = MethodChannel('FlutterCallKeep.Method');
  static const MethodChannel _event = MethodChannel('FlutterCallKeep.Event');
  BuildContext? _context;

  Future<void> setup(BuildContext? context, Map<String, dynamic> options,
      {bool backgroundMode = false}) async {
    _context = context;
    if (!isIOS) {
      await _setupAndroid(
          options['android'] as Map<String, dynamic>, backgroundMode);
      return;
    }
    await _setupIOS(options['ios'] as Map<String, dynamic>);
  }

  Future<void> registerPhoneAccount() async {
    if (isIOS) {
      return;
    }
    return _channel
        .invokeMethod<void>('registerPhoneAccount', <String, dynamic>{});
  }

  Future<void> registerAndroidEvents() async {
    if (isIOS) {
      return;
    }
    return _channel.invokeMethod<void>('registerEvents', <String, dynamic>{});
  }

  Future<bool> hasDefaultPhoneAccount(
      BuildContext context, Map<String, dynamic> options) async {
    _context = context;
    if (!isIOS) {
      return await _hasDefaultPhoneAccount(options);
    }

    // return true on iOS because we don't want to block the endUser
    return true;
  }

  Future<bool?> _checkDefaultPhoneAccount() async {
    return await _channel
        .invokeMethod<bool>('checkDefaultPhoneAccount', <String, dynamic>{});
  }

  Future<bool> _hasDefaultPhoneAccount(Map<String, dynamic> options) async {
    final hasDefault = await _checkDefaultPhoneAccount();
    final shouldOpenAccounts = await _alert(options, hasDefault);
    if (shouldOpenAccounts) {
      await _openPhoneAccounts();
      return true;
    }
    return false;
  }

  Future<void> displayIncomingCall(String uuid, String handle,
      {String localizedCallerName = '',
      String handleType = 'number',
      bool hasVideo = false}) async {
    if (!isIOS) {
      await _channel.invokeMethod<void>(
          'displayIncomingCall', <String, dynamic>{
        'uuid': uuid,
        'handle': handle,
        'localizedCallerName': localizedCallerName
      });
      return;
    }
    await _channel.invokeMethod<void>('displayIncomingCall', <String, dynamic>{
      'uuid': uuid,
      'handle': handle,
      'handleType': handleType,
      'hasVideo': hasVideo,
      'localizedCallerName': localizedCallerName
    });
  }

  Future<void> answerIncomingCall(String uuid) async {
    if (!isIOS) {
      await _channel.invokeMethod<void>(
          'answerIncomingCall', <String, dynamic>{'uuid': uuid});
    }
  }

  Future<void> startCall(String uuid, String number, String callerName,
      {String handleType = 'number', bool hasVideo = false}) async {
    if (!isIOS) {
      await _channel.invokeMethod<void>('startCall', <String, dynamic>{
        'uuid': uuid,
        'number': number,
        'callerName': callerName
      });
      return;
    }
    await _channel.invokeMethod<void>('startCall', <String, dynamic>{
      'uuid': uuid,
      'number': number,
      'callerName': callerName,
      'handleType': handleType,
      'hasVideo': hasVideo
    });
  }

  Future<void> reportConnectingOutgoingCallWithUUID(String uuid) async {
    //only available on iOS
    if (isIOS) {
      await _channel.invokeMethod<void>('reportConnectingOutgoingCallWithUUID',
          <String, dynamic>{'uuid': uuid});
    }
  }

  Future<void> reportConnectedOutgoingCallWithUUID(String uuid) async {
    //only available on iOS
    if (isIOS) {
      await _channel.invokeMethod<void>('reportConnectedOutgoingCallWithUUID',
          <String, dynamic>{'uuid': uuid});
    }
  }

  Future<void> reportEndCallWithUUID(String uuid, int reason) async =>
      await _channel.invokeMethod<void>('reportEndCallWithUUID',
          <String, dynamic>{'uuid': uuid, 'reason': reason});

  /*
   * Android explicitly states we reject a call
   * On iOS we just notify of an endCall
   */
  Future<void> rejectCall(String uuid) async {
    if (!isIOS) {
      await _channel
          .invokeMethod<void>('rejectCall', <String, dynamic>{'uuid': uuid});
    } else {
      await _channel
          .invokeMethod<void>('endCall', <String, dynamic>{'uuid': uuid});
    }
  }

  Future<bool> isCallActive(String uuid) async {
    var resp = await _channel
        .invokeMethod<bool>('isCallActive', <String, dynamic>{'uuid': uuid});
    if (resp != null) {
      return resp;
    }
    return false;
  }

  Future<List<String>> activeCalls() async {
    var resp = await _channel
        .invokeMethod<List<Object>?>('activeCalls', <String, dynamic>{});
    if (resp != null) {
      var uuids = <String>[];
      resp.forEach((element) {
        if (element is String) uuids.add(element);
      });
      return uuids;
    }
    return [];
  }

  Future<void> endCall(String uuid) async => await _channel
      .invokeMethod<void>('endCall', <String, dynamic>{'uuid': uuid});

  Future<void> endAllCalls() async =>
      await _channel.invokeMethod<void>('endAllCalls', <String, dynamic>{});

  FutureOr<bool> hasPhoneAccount() async {
    if (isIOS) {
      return true;
    }
    var resp = await _channel
        .invokeMethod<bool>('hasPhoneAccount', <String, dynamic>{});
    if (resp != null) {
      return resp;
    }
    return false;
  }

  Future<bool> hasOutgoingCall() async {
    if (isIOS) {
      return true;
    }
    var resp = await _channel
        .invokeMethod<bool>('hasOutgoingCall', <String, dynamic>{});
    if (resp != null) {
      return resp;
    }
    return false;
  }

  Future<void> setMutedCall(String uuid, bool shouldMute) async =>
      await _channel.invokeMethod<void>(
          'setMutedCall', <String, dynamic>{'uuid': uuid, 'muted': shouldMute});

  Future<void> sendDTMF(String uuid, String key) async =>
      await _channel.invokeMethod<void>(
          'sendDTMF', <String, dynamic>{'uuid': uuid, 'key': key});

  Future<void> checkIfBusy() async => isIOS
      ? await _channel.invokeMethod<void>('checkIfBusy', <String, dynamic>{})
      : throw Exception('CallKeep.checkIfBusy was called from unsupported OS');

  Future<void> checkSpeaker() async => isIOS
      ? await _channel.invokeMethod<void>('checkSpeaker', <String, dynamic>{})
      : throw Exception('CallKeep.checkSpeaker was called from unsupported OS');

  Future<void> setAvailable(String state) async {
    if (isIOS) {
      return;
    }
    // Tell android that we are able to make outgoing calls
    await _channel
        .invokeMethod<void>('setAvailable', <String, dynamic>{'state': state});
  }

  Future<void> setCurrentCallActive(String callUUID) async {
    if (isIOS) {
      return;
    }

    await _channel.invokeMethod<void>(
        'setCurrentCallActive', <String, dynamic>{'uuid': callUUID});
  }

  Future<void> updateDisplay(String uuid,
          {required String displayName, required String handle}) async =>
      await _channel.invokeMethod<void>('updateDisplay', <String, dynamic>{
        'uuid': uuid,
        'displayName': displayName,
        'handle': handle
      });

  Future<void> setOnHold(String uuid, bool shouldHold) async =>
      await _channel.invokeMethod<void>(
          'setOnHold', <String, dynamic>{'uuid': uuid, 'hold': shouldHold});

  Future<void> setReachable() async {
    if (isIOS) {
      return;
    }
    await _channel.invokeMethod<void>('setReachable', <String, dynamic>{});
  }

  // @deprecated
  Future<void> reportUpdatedCall(
      String uuid, String localizedCallerName) async {
    print(
        'CallKeep.reportUpdatedCall is deprecated, use CallKeep.updateDisplay instead');

    return isIOS
        ? await _channel.invokeMethod<void>(
            'reportUpdatedCall', <String, dynamic>{
            'uuid': uuid,
            'localizedCallerName': localizedCallerName
          })
        : throw Exception(
            'CallKeep.reportUpdatedCall was called from unsupported OS');
  }

  Future<bool> backToForeground() async {
    if (isIOS) {
      return false;
    }
    var resp = await _channel
        .invokeMethod<bool>('backToForeground', <String, dynamic>{});
    if (resp != null) {
      return resp;
    }
    return false;
  }

  Future<void> _setupIOS(Map<String, dynamic> options) async {
    if (options['appName'] == null) {
      throw Exception('CallKeep.setup: option "appName" is required');
    }
    if (options['appName'] is String == false) {
      throw Exception(
          'CallKeep.setup: option "appName" should be of type "string"');
    }
    return await _channel
        .invokeMethod<void>('setup', <String, dynamic>{'options': options});
  }

  Future<bool> _setupAndroid(
      Map<String, dynamic> options, bool backgroundMode) async {
    await _channel.invokeMethod<void>('setup', {'options': options});

    if (backgroundMode) {
      return true;
    }

    final additionalPermissions = options['additionalPermissions'] ?? [];
    final showAccountAlert = await _checkPhoneAccountPermission(
        additionalPermissions.cast<String>() as List<String>);
    final shouldOpenAccounts = await _alert(options, showAccountAlert);

    if (shouldOpenAccounts) {
      await _openPhoneAccounts();
      return true;
    }
    return false;
  }

  Future<void> openPhoneAccounts() => _openPhoneAccounts();

  Future<void> _openPhoneAccounts() async {
    if (!Platform.isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('openPhoneAccounts', <String, dynamic>{});
  }

  Future<bool> _checkPhoneAccountPermission(
      List<String>? optionalPermissions) async {
    if (!Platform.isAndroid) {
      return true;
    }
    var resp = await _channel
        .invokeMethod<bool>('checkPhoneAccountPermission', <String, dynamic>{
      'optionalPermissions': optionalPermissions ?? [],
    });
    if (resp != null) {
      return resp;
    }
    return false;
  }

  Future<bool> _alert(
      Map<String, dynamic> options, bool? showAccountAlert) async {
    if (_context == null ||
        (showAccountAlert != null && showAccountAlert == false)) {
      return false;
    }
    var resp = await _showAlertDialog(
        _context!,
        options['alertTitle'] as String,
        options['alertDescription'] as String,
        options['cancelButton'] as String,
        options['okButton'] as String);
    if (resp != null) {
      return resp;
    }
    return false;
  }

  Future<bool?> _showAlertDialog(BuildContext context, String? alertTitle,
      String? alertDescription, String? cancelButton, String? okButton) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(alertTitle ?? 'Permissions required'),
        content: Text(alertDescription ??
            'This application needs to access your phone accounts'),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: Text(cancelButton ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: Text(okButton ?? 'ok'),
          ),
        ],
      ),
    );
  }

  Future<void> setForegroundServiceSettings(
      Map<String, String> settings) async {
    if (isIOS) {
      return;
    }
    await _channel.invokeMethod<void>('foregroundService', <String, dynamic>{
      'settings': {'foregroundService': settings}
    });
  }

  Future<void> eventListener(MethodCall call) async {
    print('[CallKeep] INFO: received event "${call.method}" ${call.arguments}');
    final data = call.arguments as Map<dynamic, dynamic>;
    switch (call.method) {
      case 'CallKeepDidReceiveStartCallAction':
        emit(CallKeepDidReceiveStartCallAction.fromMap(data));
        break;
      case 'CallKeepPerformAnswerCallAction':
        emit(CallKeepPerformAnswerCallAction.fromMap(data));
        break;
      case 'CallKeepPerformEndCallAction':
        emit(CallKeepPerformEndCallAction.fromMap(data));
        break;
      case 'CallKeepDidActivateAudioSession':
        emit(CallKeepDidActivateAudioSession());
        break;
      case 'CallKeepDidDeactivateAudioSession':
        emit(CallKeepDidDeactivateAudioSession());
        break;
      case 'CallKeepDidDisplayIncomingCall':
        emit(CallKeepDidDisplayIncomingCall.fromMap(data));
        break;
      case 'CallKeepDidPerformSetMutedCallAction':
        emit(CallKeepDidPerformSetMutedCallAction.fromMap(data));
        break;
      case 'CallKeepDidToggleHoldAction':
        emit(CallKeepDidToggleHoldAction.fromMap(data));
        break;
      case 'CallKeepDidPerformDTMFAction':
        emit(CallKeepDidPerformDTMFAction.fromMap(data));
        break;
      case 'CallKeepProviderReset':
        emit(CallKeepProviderReset());
        break;
      case 'CallKeepCheckReachability':
        emit(CallKeepCheckReachability());
        break;
      case 'CallKeepDidLoadWithEvents':
        emit(CallKeepDidLoadWithEvents());
        break;
      case 'CallKeepPushKitToken':
        emit(CallKeepPushKitToken.fromMap(data));
        break;
    }
  }
}
