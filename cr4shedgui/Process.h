@interface Process : NSObject
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSDate* latestDate;
@property (nonatomic, retain) NSMutableArray<NSString*>* logs;
@end
