@interface Log : NSObject
@property (nonatomic, copy) NSString* path;
@property (nonatomic, readonly) NSDate* date;
-(instancetype)initWithPath:(NSString*)path;
@end