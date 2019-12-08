#import "CRAProcViewController.h"
#import "Process.h"
#import "CRALogController.h"
#import "Log.h"
#import "../sharedutils.h"

@implementation CRAProcViewController
-(instancetype)initWithProcess:(Process*)proc
{
    if ((self = [self init]))
    {
        _proc = proc;
        [_proc.logs sortUsingComparator:^NSComparisonResult(Log* a, Log* b) {
    	    return [b.date compare:a.date];
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
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    Log* log = _proc.logs[indexPath.row];
    NSString* logName = stringFromDate(log.date, CR4DateFormatPretty);
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
            Log* newLog = _proc.logs[1];
            _proc.latestDate = newLog.date;
        }
        else
        {
            _proc.latestDate = nil;
        }
    }
    NSString* path = _proc.logs[indexPath.row].path;
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	[_proc.logs removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

    [[NSNotificationCenter defaultCenter] postNotificationName:CR4ProcsNeedRefreshNotificationName object:nil];
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    CRALogController* logVC = [[CRALogController alloc] initWithLog:_proc.logs[indexPath.row]];
	[self.navigationController pushViewController:logVC animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
