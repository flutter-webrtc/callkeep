//
//  CallKeep.m
//  CallKeep
//
//  Copyright 2016-2019 The CallKeep Authors (see the AUTHORS file)
//  SPDX-License-Identifier: ISC, MIT
//
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>

#import "CallKeep.h"

static NSString *const CallKeepHandleStartCallNotification = @"CallKeepHandleStartCallNotification";
static NSString *const CallKeepDidReceiveStartCallAction = @"CallKeepDidReceiveStartCallAction";
static NSString *const CallKeepPerformAnswerCallAction = @"CallKeepPerformAnswerCallAction";
static NSString *const CallKeepPerformEndCallAction = @"CallKeepPerformEndCallAction";
static NSString *const CallKeepDidActivateAudioSession = @"CallKeepDidActivateAudioSession";
static NSString *const CallKeepDidDeactivateAudioSession = @"CallKeepDidDeactivateAudioSession";
static NSString *const CallKeepDidDisplayIncomingCall = @"CallKeepDidDisplayIncomingCall";
static NSString *const CallKeepDidPerformSetMutedCallAction = @"CallKeepDidPerformSetMutedCallAction";
static NSString *const CallKeepPerformPlayDTMFCallAction = @"CallKeepDidPerformDTMFAction";
static NSString *const CallKeepDidToggleHoldAction = @"CallKeepDidToggleHoldAction";
static NSString *const CallKeepProviderReset = @"CallKeepProviderReset";
static NSString *const CallKeepCheckReachability = @"CallKeepCheckReachability";
static NSString *const CallKeepDidLoadWithEvents = @"CallKeepDidLoadWithEvents";
static NSString *const CallKeepPushKitToken = @"CallKeepPushKitToken";

@implementation CallKeep
{
    NSOperatingSystemVersion _version;
    bool _hasListeners;
    NSMutableArray *_delayedEvents;
}

- (FlutterMethodChannel *)eventChannel
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setEventChannel:(FlutterMethodChannel *)eventChannel
{
    objc_setAssociatedObject(self, @selector(eventChannel), eventChannel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static CXProvider* sharedProvider;

- (instancetype)init
{
#ifdef DEBUG
    NSLog(@"[CallKeep][init]");
#endif
    if (self = [super init]) {
        _delayedEvents = [NSMutableArray array];
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone {
    static CallKeep *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"[CallKeep][dealloc]");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.callKeepProvider != nil) {
        [self.callKeepProvider invalidate];
    }
    sharedProvider = nil;
}

- (BOOL)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    NSDictionary* argsMap = call.arguments;
    if ([@"setup" isEqualToString:method]) {
        [self setup:argsMap[@"options"]];
        result(nil);
    } else if ([@"displayIncomingCall" isEqualToString:method]) {
        [self displayIncomingCall:argsMap[@"uuid"] handle:argsMap[@"handle"] handleType:argsMap[@"handleType"] hasVideo:[argsMap[@"hasVideo"] boolValue] localizedCallerName:argsMap[@"localizedCallerName"]];
        result(nil);
    }
    else if ([@ "startCall" isEqualToString:method]) {
        [self startCall:argsMap[@"uuid"] handle:argsMap[@"number"] contactIdentifier:argsMap[@"callerName"] handleType:argsMap[@"handleType"] video:[argsMap[@"hasVideo"] boolValue]];
        result(nil);
    }
    else if ([@"isCallActive" isEqualToString:method]) {
        result(@([self isCallActive:argsMap[@"uuid"]]));
    }
    else if ([@"endCall" isEqualToString:method]) {
        [self endCall:argsMap[@"uuid"]];
        result(nil);
    }
    else if ([@"endAllCalls" isEqualToString:method]) {
        [self endAllCalls];
        result(nil);
    }
    else if ([@ "setOnHold" isEqualToString:method]) {
        [self setOnHold:argsMap[@"uuid"] shouldHold:[argsMap[@"hold"] boolValue]];
        result(nil);
    }
    else if ([@ "reportEndCallWithUUID" isEqualToString:method]) {
        [self reportEndCallWithUUID:argsMap[@"uuid"] reason:[argsMap[@"reason"] intValue]];
        result(nil);
    }
    else if ([@"setMutedCall" isEqualToString:method]) {
        [self setMutedCall:argsMap[@"uuid"] muted:[argsMap[@"muted"] boolValue]];
        result(nil);
    }
    else if ([@ "sendDTMF" isEqualToString:method]) {
        [self sendDTMF:argsMap[@"uuid"] dtmf:argsMap[@"key"]];
        result(nil);
    }
    else if ([@ "updateDisplay" isEqualToString:method]) {
        [self updateDisplay:argsMap[@"uuid"] displayName:argsMap[@"displayName"] uri:argsMap[@"handle"]];
        result(nil);
    }
    else if([@ "checkIfBusy" isEqualToString:method]){
        [self checkIfBusyWithResult:result];
    }
    else if([@ "checkSpeaker" isEqualToString:method]){
        [self checkSpeakerResult:result];
    }
    else if ([@"reportConnectingOutgoingCallWithUUID" isEqualToString:method]) {
        [self reportConnectingOutgoingCallWithUUID:argsMap[@"uuid"]];
    }
    else if ([@"reportConnectedOutgoingCallWithUUID" isEqualToString:method]) {
        [self reportConnectedOutgoingCallWithUUID:argsMap[@"uuid"]];
    }
    else if([@"reportUpdatedCall" isEqualToString:method]){
        [self reportUpdatedCall:argsMap[@"uuid"] contactIdentifier:argsMap[@"localizedCallerName"]];
        result(nil);
    }
    else {
        return NO;
    }
    return YES;
}

- (void)startObserving
{
    _hasListeners = YES;
    if ([_delayedEvents count] > 0) {
        [self sendEventWithName:CallKeepDidLoadWithEvents body:_delayedEvents];
    }
}

- (void)stopObserving
{
    _hasListeners = FALSE;
}

- (void)sendEventWithName:(NSString *)name body:(id)body {
   [self.eventChannel invokeMethod:name arguments:body];
}

- (void)sendEventWithNameWrapper:(NSString *)name body:(id)body {
    [self sendEventWithName:name body:body];
}

+ (void)initCallKitProvider {
    if (sharedProvider == nil) {
        NSDictionary *settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"CallKeepSettings"];
        sharedProvider = [[CXProvider alloc] initWithConfiguration:[CallKeep getProviderConfiguration:settings]];
    }
}

-(void)setup:(NSDictionary *)options
{
#ifdef DEBUG
    NSLog(@"[CallKeep][setup] options = %@", options);
#endif
    _version = [[[NSProcessInfo alloc] init] operatingSystemVersion];
    self.callKeepCallController = [[CXCallController alloc] init];
    NSDictionary *settings = [[NSMutableDictionary alloc] initWithDictionary:options];
    // Store settings in NSUserDefault
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:@"CallKeepSettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [CallKeep initCallKitProvider];
    
    self.callKeepProvider = sharedProvider;
    [self.callKeepProvider setDelegate:self queue:nil];
    [self voipRegistration];
}

#pragma mark - PushKit

-(void)voipRegistration
{
    PKPushRegistry* voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    voipRegistry.delegate = self;
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type {
    const unsigned *tokenBytes = [pushCredentials.token bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                      ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                      ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                      ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    
    NSLog(@"\n[VoIP Token]: %@\n\n",hexToken);
    
    [self sendEventWithNameWrapper:CallKeepPushKitToken body:@{ @"token": hexToken }];
}

- (NSString *)createUUID {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidObject);
    CFRelease(uuidObject);
    return [uuidStr lowercaseString];
}


- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(nonnull void (^)(void))completion {
    // Process the received push
    NSLog(@"didReceiveIncomingPushWithPayload payload = %@", payload.type);
    /* payload example.
    {
        "uuid": "xxxxx-xxxxx-xxxxx-xxxxx",
        "caller_id": "+8618612345678",
        "caller_name": "hello",
        "caller_id_type": "number",
        "has_video": false,
    }
    */

    NSDictionary *dic = payload.dictionaryPayload;

    if (dic[@"aps"] != nil) {
        NSLog(@"Do not use the 'alert' format for push type %@.", payload.type);
        if(completion != nil) {
            completion();
        }
        return;
    }

    NSString *uuid = dic[@"uuid"];
    NSString *callerId = dic[@"caller_id"];
    NSString *callerName = dic[@"caller_name"];
    BOOL hasVideo = [dic[@"has_video"] boolValue];
    NSString *callerIdType = dic[@"caller_id_type"];
   

    if( uuid == nil) {
        uuid = [self createUUID];
    }

    //NSDictionary *extra = payload.dictionaryPayload[@"extra"];

    [CallKeep reportNewIncomingCall:uuid
                             handle:callerId
                         handleType:callerIdType
                           hasVideo:hasVideo
                localizedCallerName:callerName
                        fromPushKit:YES
                            payload:dic
              withCompletionHandler:completion];
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    [self pushRegistry:registry didReceiveIncomingPushWithPayload:payload forType:type withCompletionHandler:^(){
        NSLog(@"[CallKeep] received");
    }];
}


-(void) checkIfBusyWithResult:(FlutterResult)result
{
#ifdef DEBUG
    NSLog(@"[CallKeep][checkIfBusy]");
#endif
    result(@(self.callKeepCallController.callObserver.calls.count > 0));
}

-(void) checkSpeakerResult:(FlutterResult)result
{
#ifdef DEBUG
    NSLog(@"[CallKeep][checkSpeaker]");
#endif
    NSString *output = [AVAudioSession sharedInstance].currentRoute.outputs.count > 0 ? [AVAudioSession sharedInstance].currentRoute.outputs[0].portType : nil;
    result(@([output isEqualToString:@"Speaker"]));
}

#pragma mark - CXCallController call actions

// Display the incoming call to the user
-(void) displayIncomingCall:(NSString *)uuidString
                     handle:(NSString *)handle
                 handleType:(NSString *)handleType
                   hasVideo:(BOOL)hasVideo
        localizedCallerName:(NSString * _Nullable)localizedCallerName
{
    [CallKeep reportNewIncomingCall: uuidString handle:handle handleType:handleType hasVideo:hasVideo localizedCallerName:localizedCallerName fromPushKit: NO payload:nil withCompletionHandler:nil];
}

-(void) startCall:(NSString *)uuidString
           handle:(NSString *)handle
contactIdentifier:(NSString * _Nullable)contactIdentifier
       handleType:(NSString *)handleType
            video:(BOOL)video
{
#ifdef DEBUG
    NSLog(@"[CallKeep][startCall] uuidString = %@", uuidString);
#endif
    int _handleType = [CallKeep getHandleType:handleType];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXHandle *callHandle = [[CXHandle alloc] initWithType:_handleType value:handle];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
    [startCallAction setVideo:video];
    [startCallAction setContactIdentifier:contactIdentifier];
    
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];
    
    [self requestTransaction:transaction];
}

-(void) endCall:(NSString *)uuidString
{
#ifdef DEBUG
    NSLog(@"[CallKeep][endCall] uuidString = %@", uuidString);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
    
    [self requestTransaction:transaction];
}

-(void) endAllCalls
{
#ifdef DEBUG
    NSLog(@"[CallKeep][endAllCalls] calls = %@", self.callKeepCallController.callObserver.calls);
#endif
    for (CXCall *call in self.callKeepCallController.callObserver.calls) {
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:call.UUID];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
        [self requestTransaction:transaction];
    }
}

-(void) setOnHold:(NSString *)uuidString shouldHold:(BOOL)shouldHold
{
#ifdef DEBUG
    NSLog(@"[CallKeep][setOnHold] uuidString = %@, shouldHold = %d", uuidString, shouldHold);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXSetHeldCallAction *setHeldCallAction = [[CXSetHeldCallAction alloc] initWithCallUUID:uuid onHold:shouldHold];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:setHeldCallAction];
    
    [self requestTransaction:transaction];
}

-(void) reportConnectingOutgoingCallWithUUID:(NSString *)uuidString
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    [self.callKeepProvider reportOutgoingCallWithUUID:uuid startedConnectingAtDate:[NSDate date]];
}

-(void) reportConnectedOutgoingCallWithUUID:(NSString *)uuidString
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    [self.callKeepProvider reportOutgoingCallWithUUID:uuid connectedAtDate:[NSDate date]];
}

-(void) reportEndCallWithUUID:(NSString *)uuidString reason:(int)reason
{
    [CallKeep endCallWithUUID: uuidString reason:reason];
}

-(void) updateDisplay:(NSString *)uuidString displayName:(NSString *)displayName uri:(NSString *)uri
{
#ifdef DEBUG
    NSLog(@"[CallKeep][updateDisplay] uuidString = %@ displayName = %@ uri = %@", uuidString, displayName, uri);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:uri];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.localizedCallerName = displayName;
    callUpdate.remoteHandle = callHandle;
    [self.callKeepProvider reportCallWithUUID:uuid updated:callUpdate];
}

-(void) setMutedCall:(NSString *)uuidString muted:(BOOL)muted
{
#ifdef DEBUG
    NSLog(@"[CallKeep][setMutedCall] muted = %i", muted);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXSetMutedCallAction *setMutedAction = [[CXSetMutedCallAction alloc] initWithCallUUID:uuid muted:muted];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:setMutedAction];
    [self requestTransaction:transaction];
}

-(void) sendDTMF:(NSString *)uuidString dtmf:(NSString *)key
{
#ifdef DEBUG
    NSLog(@"[CallKeep][sendDTMF] key = %@", key);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXPlayDTMFCallAction *dtmfAction = [[CXPlayDTMFCallAction alloc] initWithCallUUID:uuid digits:key type:CXPlayDTMFCallActionTypeHardPause];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:dtmfAction];
    
    [self requestTransaction:transaction];
}

-(BOOL) isCallActive:(NSString *)uuidString
{
#ifdef DEBUG
    NSLog(@"[CallKeep][isCallActive] uuid = %@", uuidString);
#endif
    return [CallKeep isCallActive: uuidString];
}

- (void)requestTransaction:(CXTransaction *)transaction
{
#ifdef DEBUG
    NSLog(@"[CallKeep][requestTransaction] transaction = %@", transaction);
#endif
    if (self.callKeepCallController == nil) {
        self.callKeepCallController = [[CXCallController alloc] init];
    }
    [self.callKeepCallController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"[CallKeep][requestTransaction] Error requesting transaction (%@): (%@)", transaction.actions, error);
        } else {
            NSLog(@"[CallKeep][requestTransaction] Requested transaction successfully");
            // CXStartCallAction
            if ([[transaction.actions firstObject] isKindOfClass:[CXStartCallAction class]]) {
                CXStartCallAction *startCallAction = [transaction.actions firstObject];
                CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
                callUpdate.remoteHandle = startCallAction.handle;
                callUpdate.hasVideo = startCallAction.video;
                callUpdate.localizedCallerName = startCallAction.contactIdentifier;
                callUpdate.supportsDTMF = YES;
                callUpdate.supportsHolding = YES;
                callUpdate.supportsGrouping = NO;
                callUpdate.supportsUngrouping = NO;
                [self.callKeepProvider reportCallWithUUID:startCallAction.callUUID updated:callUpdate];
            }
        }
    }];
}

+ (BOOL)isCallActive:(NSString *)uuidString
{
    CXCallObserver *callObserver = [[CXCallObserver alloc] init];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    
    for(CXCall *call in callObserver.calls){
        NSLog(@"[CallKeep] isCallActive %@ %d ?", call.UUID, [call.UUID isEqual:uuid]);
        if([call.UUID isEqual:[[NSUUID alloc] initWithUUIDString:uuidString]] && !call.hasConnected){
            return true;
        }
    }
    return false;
}

+ (void)endCallWithUUID:(NSString *)uuidString
                 reason:(int)reason
{
#ifdef DEBUG
    NSLog(@"[CallKeep][reportEndCallWithUUID] uuidString = %@ reason = %d", uuidString, reason);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    switch (reason) {
        case 1:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonFailed];
            break;
        case 2:
        case 6:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonRemoteEnded];
            break;
        case 3:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonUnanswered];
            break;
        case 4:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonAnsweredElsewhere];
            break;
        case 5:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonDeclinedElsewhere];
            break;
        default:
            break;
    }
}

+ (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(NSString *)handle
                   handleType:(NSString *)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
                      payload:(NSDictionary * _Nullable)payload
{
    [CallKeep reportNewIncomingCall:uuidString handle:handle handleType:handleType hasVideo:hasVideo localizedCallerName:localizedCallerName fromPushKit:fromPushKit payload:payload withCompletionHandler:nil];
}

+ (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(NSString *)handle
                   handleType:(NSString *)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
                      payload:(NSDictionary * _Nullable)payload
        withCompletionHandler:(void (^_Nullable)(void))completion
{
#ifdef DEBUG
    NSLog(@"[CallKeep][reportNewIncomingCall] uuidString = %@", uuidString);
#endif
    int _handleType = [CallKeep getHandleType:handleType];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = [[CXHandle alloc] initWithType:_handleType value:handle];
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = YES;
    callUpdate.supportsGrouping = NO;
    callUpdate.supportsUngrouping = NO;
    callUpdate.hasVideo = hasVideo;
    callUpdate.localizedCallerName = localizedCallerName;
    
    [CallKeep initCallKitProvider];
    [sharedProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError * _Nullable error) {
        CallKeep *callKeep = [CallKeep allocWithZone: nil];
        [callKeep sendEventWithNameWrapper:CallKeepDidDisplayIncomingCall body:@{
            @"error": error && error.localizedDescription ? error.localizedDescription : @"",
            @"callUUID": uuidString,
            @"handle": handle,
            @"localizedCallerName": localizedCallerName ? localizedCallerName : @"",
            @"hasVideo": @(hasVideo),
            @"fromPushKit": @(fromPushKit),
            @"payload": payload ? payload : @"",
        }];
        if (error == nil) {
            // Workaround per https://forums.developer.apple.com/message/169511
            if ([callKeep lessThanIos10_2]) {
                [callKeep configureAudioSession];
            }
        }
        if (completion != nil) {
            completion();
        }
    }];
}

+ (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(NSString *)handle
                   handleType:(NSString *)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
{
    [CallKeep reportNewIncomingCall: uuidString handle:handle handleType:handleType hasVideo:hasVideo localizedCallerName:localizedCallerName fromPushKit: fromPushKit payload:nil withCompletionHandler:nil];
}

- (BOOL)lessThanIos10_2
{
    if (_version.majorVersion < 10) {
        return YES;
    } else if (_version.majorVersion > 10) {
        return NO;
    } else {
        return _version.minorVersion < 2;
    }
}

+ (int)getHandleType:(NSString *)handleType
{
    int _handleType;
    if ([handleType isEqualToString:@"generic"]) {
        _handleType = CXHandleTypeGeneric;
    } else if ([handleType isEqualToString:@"number"]) {
        _handleType = CXHandleTypePhoneNumber;
    } else if ([handleType isEqualToString:@"email"]) {
        _handleType = CXHandleTypeEmailAddress;
    } else {
        _handleType = CXHandleTypeGeneric;
    }
    return _handleType;
}

+ (CXProviderConfiguration *)getProviderConfiguration:(NSDictionary*)settings
{
#ifdef DEBUG
    NSLog(@"[CallKeep][getProviderConfiguration]");
#endif
    NSString *appName = @"Unknown App";
    if (settings != nil) {
        appName = settings[@"appName"];
    }
    CXProviderConfiguration *providerConfiguration = [[CXProviderConfiguration alloc] initWithLocalizedName:appName];
    providerConfiguration.supportsVideo = YES;
    providerConfiguration.maximumCallGroups = 3;
    providerConfiguration.maximumCallsPerCallGroup = 1;
    if(settings[@"handleType"]){
        int _handleType = [CallKeep getHandleType:settings[@"handleType"]];
        providerConfiguration.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:_handleType], nil];
    }else{
        providerConfiguration.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypePhoneNumber], nil];
    }
    if (settings[@"supportsVideo"]) {
        providerConfiguration.supportsVideo = [settings[@"supportsVideo"] boolValue];
    }
    if (settings[@"maximumCallGroups"]) {
        providerConfiguration.maximumCallGroups = [settings[@"maximumCallGroups"] integerValue];
    }
    if (settings[@"maximumCallsPerCallGroup"]) {
        providerConfiguration.maximumCallsPerCallGroup = [settings[@"maximumCallsPerCallGroup"] integerValue];
    }
    if (settings[@"imageName"]) {
        providerConfiguration.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:settings[@"imageName"]]);
    }
    if (settings[@"ringtoneSound"]) {
        providerConfiguration.ringtoneSound = settings[@"ringtoneSound"];
    }
    if (@available(iOS 11.0, *)) {
        if (settings[@"includesCallsInRecents"]) {
            providerConfiguration.includesCallsInRecents = [settings[@"includesCallsInRecents"] boolValue];
        }
    }
    return providerConfiguration;
}

- (void)configureAudioSession
{
#ifdef DEBUG
    NSLog(@"[CallKeep][configureAudioSession] Activating audio session");
#endif
    
    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];
    
    [audioSession setMode:AVAudioSessionModeVoiceChat error:nil];
    
    double sampleRate = 44100.0;
    [audioSession setPreferredSampleRate:sampleRate error:nil];
    
    NSTimeInterval bufferDuration = .005;
    [audioSession setPreferredIOBufferDuration:bufferDuration error:nil];
    [audioSession setActive:TRUE error:nil];
}

+ (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options NS_AVAILABLE_IOS(9_0)
{
#ifdef DEBUG
    NSLog(@"[CallKeep][application:openURL]");
#endif
    /*
     NSString *handle = [url startCallHandle];
     if (handle != nil && handle.length > 0 ){
     NSDictionary *userInfo = @{
     @"handle": handle,
     @"video": @NO
     };
     [[NSNotificationCenter defaultCenter] postNotificationName:CallKeepHandleStartCallNotification
     object:self
     userInfo:userInfo];
     return YES;
     }
     return NO;
     */
    return YES;
}

+ (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler
{
#ifdef DEBUG
    NSLog(@"[CallKeep][application:continueUserActivity]");
#endif
    INInteraction *interaction = userActivity.interaction;
    INPerson *contact;
    NSString *handle;
    BOOL isAudioCall;
    BOOL isVideoCall;
    
    //HACK TO AVOID XCODE 10 COMPILE CRASH
    //REMOVE ON NEXT MAJOR RELEASE OF CALLKIT
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    //XCode 11
    // iOS 13 returns an INStartCallIntent userActivity type
    if (@available(iOS 13, *)) {
        INStartCallIntent *intent = (INStartCallIntent*)interaction.intent;
        // callCapability is not available on iOS > 13.2, but it is in 13.1 weirdly...
        if ([intent respondsToSelector:@selector(callCapability)]) {
            isAudioCall = intent.callCapability == INCallCapabilityAudioCall;
            isVideoCall = intent.callCapability == INCallCapabilityVideoCall;
        } else {
            isAudioCall = [userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier];
            isVideoCall = [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier];
        }
    } else {
#endif
        //XCode 10 and below
        isAudioCall = [userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier];
        isVideoCall = [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier];
        //HACK TO AVOID XCODE 10 COMPILE CRASH
        //REMOVE ON NEXT MAJOR RELEASE OF CALLKIT
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    }
#endif
    
    if (isAudioCall) {
        INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
        contact = [startAudioCallIntent.contacts firstObject];
    } else if (isVideoCall) {
        INStartVideoCallIntent *startVideoCallIntent = (INStartVideoCallIntent *)interaction.intent;
        contact = [startVideoCallIntent.contacts firstObject];
    }
    
    if (contact != nil) {
        handle = contact.personHandle.value;
    }
    
    if (handle != nil && handle.length > 0 ){
        NSDictionary *userInfo = @{
            @"handle": handle,
            @"video": @(isVideoCall)
        };
        
        CallKeep *callKeep = [CallKeep allocWithZone: nil];
        [callKeep sendEventWithNameWrapper:CallKeepDidReceiveStartCallAction body:userInfo];
        return YES;
    }
    return NO;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider{
#ifdef DEBUG
    NSLog(@"[CallKeep][providerDidReset]");
#endif
    //this means something big changed, so tell the JS. The JS should
    //probably respond by hanging up all calls.
    [self sendEventWithNameWrapper:CallKeepProviderReset body:@{}];
}

// Starting outgoing call
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:performStartCallAction]");
#endif
    //do this first, audio sessions are flakey
    [self configureAudioSession];
    //tell the JS to actually make the call
    [self sendEventWithNameWrapper:CallKeepDidReceiveStartCallAction body:@{ @"callUUID": [action.callUUID.UUIDString lowercaseString], @"handle": action.handle.value }];
    [action fulfill];
}

// Update call contact info
// @deprecated
-(void) reportUpdatedCall:(NSString *)uuidString contactIdentifier:(NSString *)contactIdentifier
{
#ifdef DEBUG
    NSLog(@"[CallKeep][reportUpdatedCall] contactIdentifier = %@", contactIdentifier);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.localizedCallerName = contactIdentifier;
    
    [self.callKeepProvider reportCallWithUUID:uuid updated:callUpdate];
}

// Answering incoming call
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:performAnswerCallAction]");
#endif
    [self configureAudioSession];
    [self sendEventWithNameWrapper:CallKeepPerformAnswerCallAction body:@{ @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

// Ending incoming call
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:performEndCallAction]");
#endif
    [self sendEventWithNameWrapper:CallKeepPerformEndCallAction body:@{ @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

-(void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:performSetHeldCallAction]");
#endif
    
    [self sendEventWithNameWrapper:CallKeepDidToggleHoldAction body:@{ @"hold": @(action.onHold), @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:performPlayDTMFCallAction]");
#endif
    [self sendEventWithNameWrapper:CallKeepPerformPlayDTMFCallAction body:@{ @"digits": action.digits, @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

-(void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:performSetMutedCallAction]");
#endif
    
    [self sendEventWithNameWrapper:CallKeepDidPerformSetMutedCallAction body:@{ @"muted": @(action.muted), @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:timedOutPerformingAction]");
#endif
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:didActivateAudioSession]");
#endif
    NSDictionary *userInfo
    = @{
        AVAudioSessionInterruptionTypeKey: [NSNumber numberWithInt:AVAudioSessionInterruptionTypeEnded],
        AVAudioSessionInterruptionOptionKey: [NSNumber numberWithInt:AVAudioSessionInterruptionOptionShouldResume]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:AVAudioSessionInterruptionNotification object:nil userInfo:userInfo];
    
    [self configureAudioSession];
    [self sendEventWithNameWrapper:CallKeepDidActivateAudioSession body:@{}];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession
{
#ifdef DEBUG
    NSLog(@"[CallKeep][CXProviderDelegate][provider:didDeactivateAudioSession]");
#endif
    [self sendEventWithNameWrapper:CallKeepDidDeactivateAudioSession body:@{}];
}

@end
