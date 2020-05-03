#import "CRABlacklistViewController.h"
#import <Cephei/HBPreferences.h>
#import <sharedutils.h>

@implementation CRABlacklistCell
-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)reuseIdentifier
{
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{	
		_textField = [[UITextField alloc] initWithFrame:CGRectZero];
		_textField.delegate = self;
		_textField.placeholder = @"Process name (Case-sensitive)";

		_textField.translatesAutoresizingMaskIntoConstraints = NO;
		[self.contentView addSubview:_textField];
		[_textField.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15.].active = YES;
		[_textField.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
		[_textField.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
		[_textField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
	}
	return self;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField
{
	[textField resignFirstResponder];
	return YES;
}

-(void)textFieldDidEndEditing:(UITextField*)textField
{
	_textChangedCallback(_textField.text);
}
@end

@implementation CRABlacklistViewController

-(instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		self.title = @"Blacklist";
		UIBarButtonItem* plusButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(plusButtonAction)];
		self.navigationItem.rightBarButtonItem = plusButton;

		//CR4BlacklistDidChangeNotificationName
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadBlacklist) name:CR4BlacklistDidChangeNotificationName object:nil];
	
		self.tableView.editing = YES;
		self.tableView.allowsSelection = NO;
	}
	return self;
}

-(void)reloadBlacklist
{
	_blacklist = [[sharedPreferences() objectForKey:kProcessBlacklist] mutableCopy];
	_blacklist = _blacklist ?: [NSMutableArray new];
	[self.tableView reloadData];
}

-(void)updatePreferences
{
	[sharedPreferences() setObject:[_blacklist copy] forKey:kProcessBlacklist];
}

-(void)plusButtonAction
{
	[_blacklist addObject:@""];
	[self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_blacklist.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(void)loadView
{
	[super loadView];

	//load blacklist:
	[self reloadBlacklist];
}

-(void)viewDidAppear:(BOOL)arg1
{
	[super viewDidAppear:arg1];
	self.navigationController.interactivePopGestureRecognizer.delegate = self;
	self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

#pragma mark - Table View Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _blacklist.count;
}

-(NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Blacklisted Processes";
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	CRABlacklistCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BlacklistCell"];
	if (!cell)
		cell = [[CRABlacklistCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BlacklistCell"];
	
	cell.textField.text = _blacklist[indexPath.row];
	cell.textChangedCallback = ^(NSString* text) {
		_blacklist[indexPath.row] = text;
		[self updatePreferences];
	};
	return cell;
}

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	[_blacklist removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self updatePreferences];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
