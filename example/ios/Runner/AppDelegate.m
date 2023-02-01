#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <CallKeep.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    [CallKeep setDelegate:self];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    return [CallKeep application:application
                        continueUserActivity:userActivity
                        restorationHandler:restorationHandler];
}

- (nonnull NSDictionary *)mapPushPayload:(NSDictionary * _Nonnull)payload {
    NSLog(@"Mapper called with %@", [payload description]);
    return payload;
}

@end
