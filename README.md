# callkeep

[![Financial Contributors on Open Collective](https://opencollective.com/flutter-webrtc/all/badge.svg?label=financial+contributors)](https://opencollective.com/flutter-webrtc) [![pub package](https://img.shields.io/pub/v/callkeep.svg)](https://pub.dartlang.org/packages/callkeep) [![slack](https://img.shields.io/badge/join-us%20on%20slack-gray.svg?longCache=true&logo=slack&colorB=brightgreen)](https://join.slack.com/t/flutterwebrtc/shared_invite/zt-q83o7y1s-FExGLWEvtkPKM8ku_F8cEQ)

* iOS CallKit and Android ConnectionService for Flutter
* Support FCM and PushKit

> Keep in mind Callkit is banned in China, so if you want your app in the chinese AppStore consider include a basic alternative for notifying calls (ex. FCM notifications with sound).

## Introduction

Callkeep acts as an intermediate between your call system (RTC, VOIP...) and the user, offering a native calling interface for handling your app calls.

This allows you (for example) answering calls when your device is locked even if your app is killed.


## Initial setup

Basic configuration. In Android a popup is displayed before start requesting some permissions for working properly.

```dart
final callSetup = <String, dynamic>{
  'ios': {
    'appName': 'CallKeepDemo',
  },
  'android': {
    'alertTitle': 'Permissions required',
    'alertDescription':
    'This application needs to access your phone accounts',
    'cancelButton': 'Cancel',
    'okButton': 'ok',
  },
};

callKeep.setup(callSetup);
```

This configuration should be defined when your application wakes up, but keep in mind this alert will appear if you aren't granting the needed permissions yet.

A clean alternative is to control by yourself the required permissions when your application wakes up, and only invoke the `setup()` method if those permissions are granted.

## Events

Callkeep offers some events for handle native actions during a call.

These events are quite crucial because acts as an intermediate between the native calling UI and your calling presenter (or controller or manager).

What does it mean? 

Assuming your application already implements some calling system (RTC, Voip, or whatever) with its own calling UI, you are using some basic controls:

> before implementing `callkeep`

- Hang up -> `presenter.hangUp()`
- Microphone switcher -> `presenter.microSwitch()`

> after implementing `callkeep`

- Hang up -> `callkeep.endCall(call_uuid)`
- Microphone switcher -> `callKeep.setMutedCall(uuid, true / false)`

Then you handle the action:

```dart
Function(CallKeepPerformAnswerCallAction) answerAction = (event) async {
    print('CallKeepPerformAnswerCallAction ${event.callUUID}');
    // notify to your call presenter / controller / manager the answer action
};

Function(CallKeepPerformEndCallAction) endAction = (event) async {
    print('CallKeepPerformEndCallAction ${event.callUUID}');
    // notify to your call presenter / controller / manager the end action
};

Function(CallKeepDidPerformSetMutedCallAction) setMuted = (event) async {
    print('CallKeepDidPerformSetMutedCallAction ${event.callUUID}');
    // notify to your call presenter / controller / manager the muted switch action
};

Function(CallKeepDidToggleHoldAction) onHold = (event) async {
    print('CallKeepDidToggleHoldAction ${event.callUUID}');
    // notify to your call presenter / controller / manager the hold switch action
};
```

```dart
callKeep.on(CallKeepDidToggleHoldAction(), onHold);
callKeep.on(CallKeepPerformAnswerCallAction(), answerAction);
callKeep.on(CallKeepPerformEndCallAction(), endAction);
callKeep.on(CallKeepDidPerformSetMutedCallAction(), setMuted);
```

## Display incoming calls in foreground, background or terminate state

The incoming call concept we are looking for is firing a display incoming call action when "something" is received in our app.

I've tested this concept with FCM and works pretty fine.

```dart
final FlutterCallkeep _callKeep = FlutterCallkeep();
bool _callKeepStarted = false;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (!_callKeepStarted) {
    try {
      await _callKeep.setup(callSetup);
      _callKeepStarted = true;
    } catch (e) {
      print(e);
    }
  }
  
  // then process your remote message looking for some call uuid
  // and display any incoming call
}
```

Displaying incoming calls is really simple if you are receiving FCM messages (or whatever). This sample shows how to show and close any incoming call:

> Notice that getting data from the payload can be done as you want, this is a sample.

```dart
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

extension RemoteMessageExt on RemoteMessage {
  Map<String, dynamic> getContent() {
    return jsonDecode(this.data["content"]);
  }

  Map<String, dynamic> payload() {
    var content = getContent()["payload"];
    return content;
  }
}
```

```dart
Future<void> showIncomingCall(
  BuildContext context,
  RemoteMessage remoteMessage,
  FlutterCallkeep callKeep,
) async {
  var callerIdFrom = remoteMessage.payload()[MessageManager.CALLER_ID_FROM] as String;
  var callerName = remoteMessage.payload()[MessageManager.CALLER_NAME] as String;
  var uuid = remoteMessage.payload()[MessageManager.CALLER_UUID] as String;
  var hasVideo = remoteMessage.payload()[MessageManager.CALLER_VIDEO] == "true";
  
  callKeep.on(CallKeepDidToggleHoldAction(), onHold);
  callKeep.on(CallKeepPerformAnswerCallAction(), answerAction);
  callKeep.on(CallKeepPerformEndCallAction(), endAction);
  callKeep.on(CallKeepDidPerformSetMutedCallAction(), setMuted);

  print('backgroundMessage: displayIncomingCall ($uuid)');

  bool hasPhoneAccount = await callKeep.hasPhoneAccount();
  if (!hasPhoneAccount) {
    hasPhoneAccount = await callKeep.hasDefaultPhoneAccount(context, callSetup["android"]);
  }

  if (!hasPhoneAccount) {
    return;
  }

  await callKeep.displayIncomingCall(uuid, callerIdFrom, localizedCallerName: callerName, hasVideo: hasVideo);
  callKeep.backToForeground();
}

Future<void> closeIncomingCall(
  RemoteMessage remoteMessage,
  FlutterCallkeep callKeep,
) async {
  var uuid = remoteMessage.payload()[MessageManager.CALLER_UUID] as String;
  print('backgroundMessage: closeIncomingCall ($uuid)');
  bool hasPhoneAccount = await callKeep.hasPhoneAccount();
  if (!hasPhoneAccount) {
    return;
  }
  await callKeep.endAllCalls();
}
```

## Push Payload

```json
{
    "uuid": "xxxxx-xxxxx-xxxxx-xxxxx",
    "caller_id": "+8618612345678",
    "caller_name": "hello",
    "caller_id_type": "number", 
    "has_video": false
}
```

## push test tool

Please refer to the [Push Toolkit](/tools/) to test callkeep offline push.
