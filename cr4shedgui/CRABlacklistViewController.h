@interface CRABlacklistCell : UITableViewCell <UITextFieldDelegate>
@property (nonatomic, readonly) UITextField* textField;
@property (nonatomic, copy) void(^textChangedCallback)(NSString*);
@end

@interface CRABlacklistViewController : UITableViewController <UIGestureRecognizerDelegate>
{
	NSMutableArray<NSString*>* _blacklist;
}
-(void)reloadBlacklist;
-(void)updatePreferences;
@end
