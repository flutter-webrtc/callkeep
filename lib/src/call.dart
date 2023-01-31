class CallData {
  const CallData(
    this.callUUID,
    this.handle,
    this.name,
    this.additionalData,
  );

  factory CallData.fromMap(Map<dynamic, dynamic> arguments) {
    final callUUID = arguments['callUUID'];
    final handle = arguments['handle'];
    final name = arguments['name'];
    final additionalData = arguments['additionalData'];
    return CallData(callUUID, handle, name, Map.from(additionalData));
  }

  final String callUUID;
  final String handle;
  final String name;
  final Map<String, dynamic> additionalData;
}
