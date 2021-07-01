# callkeep

[![Financial Contributors on Open Collective](https://opencollective.com/flutter-webrtc/all/badge.svg?label=financial+contributors)](https://opencollective.com/flutter-webrtc) [![pub package](https://img.shields.io/pub/v/callkeep.svg)](https://pub.dartlang.org/packages/callkeep) [![slack](https://img.shields.io/badge/join-us%20on%20slack-gray.svg?longCache=true&logo=slack&colorB=brightgreen)](https://join.slack.com/t/flutterwebrtc/shared_invite/zt-q83o7y1s-FExGLWEvtkPKM8ku_F8cEQ)

* iOS CallKit and Android ConnectionService for Flutter
* Support FCM and PushKit

> Callkit banned in China

### Introduction

Callkeep acts as an intermediate between your call system (RTC, VOIP...) and the user, offering a native calling interface for handling your app calls.

This allows you (for example) answering calls when your device is locked even if your app is killed.


### Initial setup

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

### Events

Callkeep offers some events for handle native actions during a call.

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

### Display incoming calls in foreground, background or terminate state

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



## push payload

```json
{
    "uuid": "xxxxx-xxxxx-xxxxx-xxxxx",
    "caller_id": "+8618612345678",
    "caller_name": "hello",
    "caller_id_type": "number", 
    "has_video": false,
}
```

## push test tool

Please refer to the [Push Toolkit](/tools/) to test callkeep offline push.
