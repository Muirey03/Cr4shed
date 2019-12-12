#import <FRPreferences.framework/Headers/FRPrefs.h>

@interface FRPreferences (Internal)
-(instancetype)initTableWithSections:(NSArray*)sections;
@end

@class HBPreferences;
@interface CRASettingsViewController : FRPreferences
+(instancetype)newSettingsController;
-(void)updatePrefsWithKey:(NSString*)key value:(id)value;
@end