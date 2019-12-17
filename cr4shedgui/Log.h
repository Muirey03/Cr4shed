@interface Log : NSObject
@property (nonatomic, readonly) NSString* path;
@property (nonatomic, readonly) NSDate* date;
@property (nonatomic, readonly) NSString* processName;
@property (nonatomic, readonly) NSString* dateName;
@property (nonatomic, readonly) NSString* contents;
@property (nonatomic, readonly) NSDictionary* info;
-(instancetype)initWithPath:(NSString*)path;
@end