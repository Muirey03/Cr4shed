@interface MRYIPCCenter : NSObject
@property (nonatomic, readonly) NSString* centerName;
+(instancetype)centerNamed:(NSString*)name;
-(void)addTarget:(id)target action:(SEL)action;
//asynchronously call a void method
-(void)callExternalVoidMethod:(SEL)method withArguments:(NSDictionary*)args;
//synchronously call a method and recieve the return value
-(id)callExternalMethod:(SEL)method withArguments:(NSDictionary*)args;
//asynchronously call a method and receive the return value in the completion handler
-(void)callExternalMethod:(SEL)method withArguments:(NSDictionary*)args completion:(void(^)(id))completionHandler;

//deprecated
-(void)registerMethod:(SEL)selector withTarget:(id)target;
@end
