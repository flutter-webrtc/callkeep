import 'package:callkeep/src/call.dart';

import 'event.dart';

class CallKeepDidReceiveStartCallAction extends EventType {
  const CallKeepDidReceiveStartCallAction({this.callData});
  CallKeepDidReceiveStartCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callData = CallData.fromMap(arguments);
  final CallData? callData;
}

class CallKeepPerformAnswerCallAction extends EventType {
  const CallKeepPerformAnswerCallAction({this.callData});
  CallKeepPerformAnswerCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callData = CallData.fromMap(arguments);
  final CallData? callData;
}

class CallKeepPerformEndCallAction extends EventType {
  const CallKeepPerformEndCallAction({this.callUUID});
  CallKeepPerformEndCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'];
  final String? callUUID;
}

class CallKeepPerformRejectCallAction extends EventType {
  const CallKeepPerformRejectCallAction({this.callUUID});
  CallKeepPerformRejectCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'];
  final String? callUUID;
}

class CallKeepDidActivateAudioSession extends EventType {
  const CallKeepDidActivateAudioSession();
}

class CallKeepDidDeactivateAudioSession extends EventType {
  const CallKeepDidDeactivateAudioSession();
}

class CallKeepDidDisplayIncomingCall extends EventType {
  const CallKeepDidDisplayIncomingCall({
    this.callUUID,
    this.handle,
    this.localizedCallerName,
    this.hasVideo,
    this.fromPushKit,
    this.payload,
  });
  CallKeepDidDisplayIncomingCall.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        handle = arguments['handle'],
        localizedCallerName = arguments['localizedCallerName'],
        hasVideo = arguments['hasVideo'],
        fromPushKit = arguments['fromPushKit'],
        payload = arguments['payload'];
  final String? callUUID;
  final String? handle;
  final String? localizedCallerName;
  final bool? hasVideo;
  final bool? fromPushKit;
  final Map<dynamic, dynamic>? payload;
}

class CallKeepDidPerformSetMutedCallAction extends EventType {
  const CallKeepDidPerformSetMutedCallAction({this.callUUID, this.muted});
  CallKeepDidPerformSetMutedCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        muted = arguments['muted'];
  final String? callUUID;
  final bool? muted;
}

class CallKeepDidToggleHoldAction extends EventType {
  const CallKeepDidToggleHoldAction({this.callUUID, this.hold});
  CallKeepDidToggleHoldAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        hold = arguments['hold'];
  final String? callUUID;
  final bool? hold;
}

class CallKeepDidPerformDTMFAction extends EventType {
  const CallKeepDidPerformDTMFAction({this.callUUID, this.digits});
  CallKeepDidPerformDTMFAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        digits = arguments['digits'];
  final String? callUUID;
  final String? digits;
}

class CallKeepProviderReset extends EventType {
  const CallKeepProviderReset();
}

class CallKeepCheckReachability extends EventType {
  const CallKeepCheckReachability();
}

class CallKeepDidLoadWithEvents extends EventType {
  const CallKeepDidLoadWithEvents();
}

class CallKeepPushKitToken extends EventType {
  const CallKeepPushKitToken({this.token});
  CallKeepPushKitToken.fromMap(Map<dynamic, dynamic> arguments)
      : token = arguments['token'];
  final String? token;
}
