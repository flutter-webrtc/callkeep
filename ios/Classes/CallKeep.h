//
//  CallKeep.h
//  CallKeep
//
//  Copyright 2016-2019 The CallKeep Authors (see the AUTHORS file)
//  SPDX-License-Identifier: ISC, MIT
//
#import <Flutter/Flutter.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CallKit/CallKit.h>
#import <Intents/Intents.h>
#import <PushKit/PushKit.h>

@interface CallKeep: NSObject<CXProviderDelegate, PKPushRegistryDelegate>
@property (nonatomic, strong, nullable) CXCallController *callKeepCallController;
@property (nonatomic, strong, nullable) CXProvider *callKeepProvider;
@property (nonatomic, strong, nullable) FlutterMethodChannel* eventChannel;

- (BOOL)handleMethodCall:(FlutterMethodCall* _Nonnull)call result:(FlutterResult _Nonnull )result;

+ (BOOL)application:(UIApplication * _Nonnull)application
            openURL:(NSURL * _Nonnull)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> * _Nonnull)options NS_AVAILABLE_IOS(9_0);

+ (BOOL)application:(UIApplication * _Nonnull)application
continueUserActivity:(NSUserActivity * _Nonnull)userActivity
  restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler;

+ (void)reportNewIncomingCall:(NSString * _Nonnull)uuidString
                       handle:(NSString * _Nonnull)handle
                   handleType:(NSString * _Nonnull)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
                      payload:(NSDictionary * _Nullable)payload;

+ (void)reportNewIncomingCall:(NSString * _Nonnull)uuidString
                       handle:(NSString * _Nonnull)handle
                   handleType:(NSString * _Nonnull)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
                      payload:(NSDictionary * _Nullable)payload
        withCompletionHandler:(void (^_Nullable)(void))completion;

+ (void)endCallWithUUID:(NSString * _Nonnull)uuidString
                 reason:(int)reason;

+ (BOOL)isCallActive:(NSString * _Nonnull)uuidString;

@end
