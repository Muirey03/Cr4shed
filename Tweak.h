@import Foundation;

@interface Cr4shedServer : NSObject
+(instancetype)sharedInstance;
-(NSDictionary*)sendNotification:(NSDictionary*)userInfo;
-(NSDictionary*)writeString:(NSDictionary*)userInfo;
@end