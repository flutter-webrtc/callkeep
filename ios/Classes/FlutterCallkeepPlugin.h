#import <Flutter/Flutter.h>

@interface FlutterCallkeepPlugin : NSObject<FlutterPlugin>
+ (instancetype)sharedInstance;
+ (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options NS_AVAILABLE_IOS(9_0);
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler;
@end
