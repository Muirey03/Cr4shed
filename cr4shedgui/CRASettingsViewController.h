#import <FRPreferences.framework/Headers/FRPrefs.h>

@interface FRPreferences (Internal)
-(instancetype)initTableWithSections:(NSArray*)sections;
@end

@interface CRASettingsViewController : FRPreferences
+(instancetype)newSettingsController;
@end