#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <CallKeep.h>
#import <PushKit/PushKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    // Override point for customization after application launch.
    [self voipRegistration];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler {
    return [CallKeep application:application
                        continueUserActivity:userActivity
                        restorationHandler:restorationHandler];
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
}

- (NSString *)createUUID
{
    // Create universally unique identifier (object)
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
   
    // Get the string representation of CFUUID object.
    NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
   
    // If needed, here is how to get a representation in bytes, returned as a structure
    // typedef struct {
    //   UInt8 byte0;
    //   UInt8 byte1;
    //   …
    //   UInt8 byte15;
    // } CFUUIDBytes;
    CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuidObject);
   
    CFRelease(uuidObject);
   
    return [uuidStr lowercaseString];
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
    // Process the received push
    NSLog(@"didReceiveIncomingPushWithPayload payload = %@", payload.type);
    /* payload example.
     {
         "callkeep": {
             "title": "Incoming Call",
             "number": "+86186123456789"
         },
         "badge": {
             "badge": "0"
         }
     }
    */
    NSDictionary *dic = payload.dictionaryPayload[@"callkeep"];
    NSString *number = dic[@"number"];
    
    [CallKeep reportNewIncomingCall:[self createUUID]
                             handle:number
                         handleType:@"number"
                           hasVideo:NO
                localizedCallerName:@"hello"
                        fromPushKit:YES
                            payload:payload.dictionaryPayload
              withCompletionHandler:^(){
            
        }];
}

@end
