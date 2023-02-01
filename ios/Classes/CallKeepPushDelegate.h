#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CallKeepPushDelegate <NSObject>

- (NSDictionary*)mapPushPayload:(NSDictionary* _Nonnull)payload;

@end

NS_ASSUME_NONNULL_END
