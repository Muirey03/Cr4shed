@interface NSTask : NSObject
@property (copy) NSURL* executableURL;
@property (copy) NSArray* arguments;
@property (retain) id standardOutput;
-(void)launch;
-(void)waitUntilExit;
@end

NSString* outputOfCommand(NSString* cmd, NSArray<NSString*>* args);
NSString* packageForFile(NSString* file);
NSString* controlFieldForPackage(NSString* package, NSString* field);
