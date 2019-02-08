#import "CRAProcViewController.h"
#import "Process.h"
#import "CRALogController.h"

@implementation CRAProcViewController
-(id)initWithProcess:(Process*)arg1
{
    self = [self init];
    if (self)
    {
        _proc = arg1;
        [_proc.logs sortUsingComparator:^NSComparisonResult(NSString* a, NSString* b) {
            NSString* path1 = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", a];
    		NSDictionary* fileAttribs1 = [[NSFileManager defaultManager] attributesOfItemAtPath:path1 error:nil];
    		NSDate* first = [fileAttribs1 objectForKey:NSFileCreationDate];

            NSString* path2 = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", b];
            NSDictionary* fileAttribs2 = [[NSFileManager defaultManager] attributesOfItemAtPath:path2 error:nil];
    		NSDate* second = [fileAttribs2 objectForKey:NSFileCreationDate];
    	    return [second compare:first];
    	}];
    }
    return self;
}

-(void)loadView
{
	[super loadView];

	self.title = _proc.name;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

	//remove extra separators
	self.tableView.tableFooterView = [UIView new];
}

-(void)viewDidAppear:(BOOL)arg1
{
    [super viewDidAppear:arg1];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Table View Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _proc.logs.count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
	}
    NSString* logName = _proc.logs[indexPath.row];
    NSArray<NSString*>* comp = [logName componentsSeparatedByString:@"@"];
    logName = comp.count > 1 ? comp[1] : comp[0];
    logName = [logName stringByDeletingPathExtension];
    logName = [logName stringByReplacingOccurrencesOfString:@"-" withString:@"/"];
    logName = [logName stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    cell.textLabel.text = logName;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.row == 0)
    {
        if (_proc.logs.count > 1)
        {
            //get new latestDate
            NSString* newPath = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", _proc.logs[1]];
            NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:newPath error:nil];
            _proc.latestDate = [fileAttribs objectForKey:NSFileCreationDate];
        }
    }
    NSString* path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", _proc.logs[indexPath.row]];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	[_proc.logs removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    CRALogController* logVC = [[CRALogController alloc] initWithLog:_proc.logs[indexPath.row]];
	[self.navigationController pushViewController:logVC animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
