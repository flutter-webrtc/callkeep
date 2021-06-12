# callkeep

[![Financial Contributors on Open Collective](https://opencollective.com/flutter-webrtc/all/badge.svg?label=financial+contributors)](https://opencollective.com/flutter-webrtc) [![pub package](https://img.shields.io/pub/v/callkeep.svg)](https://pub.dartlang.org/packages/callkeep) [![slack](https://img.shields.io/badge/join-us%20on%20slack-gray.svg?longCache=true&logo=slack&colorB=brightgreen)](https://join.slack.com/t/flutterwebrtc/shared_invite/zt-q83o7y1s-FExGLWEvtkPKM8ku_F8cEQ)

* iOS CallKit and Android ConnectionService for Flutter
* Support FCM and PushKit

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
