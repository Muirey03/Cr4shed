#import "CRARootViewController.h"
#import "CRAProcViewController.h"
#import "Process.h"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation Process
-(id)init
{
	self = [super init];
	if (self)
	{
		_logs = [NSMutableArray new];
	}
	return self;
}
@end

@implementation ProcessCell
-(void)didMoveToWindow
{
	[super didMoveToWindow];

	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	self.textLabel.text = _proc.name;

	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy/MM/dd HH:mm"];
	self.detailTextLabel.text = [formatter stringFromDate:_proc.latestDate];

	if (!_countLbl)
	{
		_countLbl = [[UILabel alloc] init];
		[self addSubview:_countLbl];
	}
	_countLbl.text = [NSString stringWithFormat:@"(%lu)", (unsigned long)_proc.logs.count];
	_countLbl.textColor = self.detailTextLabel.textColor;
	_countLbl.textAlignment = NSTextAlignmentCenter;

	_countLbl.translatesAutoresizingMaskIntoConstraints = NO;
	[_countLbl.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
	[_countLbl.widthAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
	[_countLbl.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor].active = YES;
}
@end

@implementation CRARootViewController
{
	NSMutableArray<Process*>* _procs;
}

-(void)loadView
{
	[super loadView];

	self.title = @"Cr4shed";
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	//remove extra separators
	self.tableView.tableFooterView = [UIView new];
	self.tableView.rowHeight = 50;

	//pull to refresh:
	UIRefreshControl* refreshControl = [[UIRefreshControl alloc]init];
    [refreshControl addTarget:self action:@selector(refreshTable:) forControlEvents:UIControlEventValueChanged];
	if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"10.0")) {
        self.tableView.refreshControl = refreshControl;
    } else {
        [self.tableView addSubview:refreshControl];
    }
}

-(void)refreshTable:(UIRefreshControl*)control
{
	[self loadLogs];
	[self.tableView reloadData];
	[control endRefreshing];
}

-(void)viewDidAppear:(BOOL)arg1
{
    [super viewDidAppear:arg1];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

-(void)viewWillAppear:(BOOL)arg1
{
	[super viewWillAppear:arg1];

	//UIApplicationDidBecomeActiveNotification
	static void (^handler)(void) = nil;
	if (handler) [[NSNotificationCenter defaultCenter] removeObserver:handler];
	handler = ^{
		[self loadLogs];
		[self.tableView reloadData];
	};
	[[NSNotificationCenter defaultCenter] addObserver:handler selector:@selector(invoke) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];

	[self sortProcs];
	[self.tableView reloadData];
}

-(void)sortProcs
{
	_procs = [[_procs sortedArrayUsingComparator:^NSComparisonResult(Process* a, Process* b) {
	    NSDate* first = a.latestDate;
	    NSDate* second = a.latestDate;
	    return [first compare:second];
	}] mutableCopy];
	for (int i = 0; i < _procs.count; i++)
	{
		if (_procs[i].logs.count == 0)
		{
			[_procs removeObjectAtIndex:i];
			i--;
		}
	}
}

-(void)loadLogs
{
	_procs = [[NSMutableArray alloc] init];
	//loop through all logs
	NSMutableArray* files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/tmp/crash_logs" error:nil] mutableCopy];
	for (int i = 0; i < files.count; i++)
	{
		NSString* file = files[i];
		if (![[file pathExtension] isEqualToString:@"log"])
		{
			[files removeObjectAtIndex:i];
			i--;
			continue;
		}
		//file is a log
		Process* proc;
		NSArray* comp = [file componentsSeparatedByString:@"@"];
		NSString* name = comp.count > 1 ? comp[0] : @"(null)";

		//check if process is already in array
		BOOL inArray = NO;
		for (Process* p in _procs)
		{
			if ([p.name isEqualToString:name])
			{
				proc = p;
				inArray = YES;
				break;
			}
		}
		if (!inArray)
		{
			//process isn't in array, add it
			proc = [Process new];
			proc.name = name;
			[_procs addObject:proc];
		}
		[proc.logs addObject:file];

		//get date:
		NSString* path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", file];
		NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
		NSDate* date = [fileAttribs objectForKey:NSFileCreationDate];
		if (!inArray || [proc.latestDate compare:date] == NSOrderedAscending)
		{
			proc.latestDate = date;
		}
	}

	[self sortProcs];
}

#pragma mark - Table View Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _procs.count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	ProcessCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	if (!cell)
	{
		cell = [[ProcessCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
	}
	cell.proc = _procs[indexPath.row];
	return cell;
}

-(void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
	Process* proc = _procs[indexPath.row];
	for (NSString* file in proc.logs)
	{
		NSString* path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", file];
	    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	}
	[_procs removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	CRAProcViewController* procVC = [[CRAProcViewController alloc] initWithProcess:_procs[indexPath.row]];
	[self.navigationController pushViewController:procVC animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
