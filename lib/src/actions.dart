import 'package:callkeep/src/call.dart';

import 'event.dart';

class CallKeepDidReceiveStartCallAction extends EventType {
  CallKeepDidReceiveStartCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callData = CallData.fromMap(arguments);
  final CallData callData;
}

class CallKeepPerformAnswerCallAction extends EventType {
  CallKeepPerformAnswerCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callData = CallData.fromMap(arguments);
  final CallData callData;
}

class CallKeepShowIncomingCallAction extends EventType {
  CallKeepShowIncomingCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callData = CallData.fromMap(arguments);
  final CallData callData;
}

class CallKeepPerformEndCallAction extends EventType {
  CallKeepPerformEndCallAction.fromMap(Map<dynamic, dynamic> arguments)
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
  CallKeepDidDisplayIncomingCall.fromMap(Map<dynamic, dynamic> arguments)
      : callData = CallData.fromMap(arguments);
  final CallData callData;
}

class CallKeepDidPerformSetMutedCallAction extends EventType {
  CallKeepDidPerformSetMutedCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        muted = arguments['muted'];
  final String? callUUID;
  final bool? muted;
}

class CallKeepDidToggleHoldAction extends EventType {
  CallKeepDidToggleHoldAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        hold = arguments['hold'];
  final String? callUUID;
  final bool? hold;
}

class CallKeepDidPerformDTMFAction extends EventType {
  CallKeepDidPerformDTMFAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'],
        digits = arguments['digits'];
  final String? callUUID;
  final String? digits;
}

class CallKeepProviderReset extends EventType {
  CallKeepProviderReset();
}

class CallKeepCheckReachability extends EventType {
  CallKeepCheckReachability();
}

class CallKeepDidLoadWithEvents extends EventType {
  CallKeepDidLoadWithEvents();
}

class CallKeepPushKitToken extends EventType {
  CallKeepPushKitToken.fromMap(Map<dynamic, dynamic> arguments)
      : token = arguments['token'];
  final String? token;
}

class CallKeepPerformRejectCallAction extends EventType {
  const CallKeepPerformRejectCallAction({this.callUUID});
  CallKeepPerformRejectCallAction.fromMap(Map<dynamic, dynamic> arguments)
      : callUUID = arguments['callUUID'];
  final String? callUUID;
}
