#import "CRARootViewController.h"
#import "CRAProcViewController.h"
#import "Process.h"
#import "Log.h"
#import "../sharedutils.h"

@implementation ProcessCell
-(void)didMoveToWindow
{
	[super didMoveToWindow];

	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	self.textLabel.text = _proc.name;

	self.detailTextLabel.text = stringFromDate(_proc.latestDate, CR4DateFormatPretty);

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

-(instancetype)init
{
	if ((self = [super init]))
	{
		//UIApplicationDidBecomeActiveNotification
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable:) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
	}
	return self;
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
	_refreshControl = [UIRefreshControl new];
    [_refreshControl addTarget:self action:@selector(refreshTable:) forControlEvents:UIControlEventValueChanged];
	if ([self.tableView respondsToSelector:@selector(setRefreshControl:)])
        self.tableView.refreshControl = _refreshControl;
	else
        [self.tableView addSubview:_refreshControl];
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	[self refreshTable:nil];
}

-(void)refreshTable:(id)obj
{
	[self loadLogs];
	if (_refreshControl.refreshing)
		[_refreshControl endRefreshing];
	[self.tableView reloadData];
}

-(void)viewDidAppear:(BOOL)arg1
{
    [super viewDidAppear:arg1];
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

-(void)sortProcs
{
	[_procs sortUsingComparator:^NSComparisonResult(Process* a, Process* b) {
	    NSDate* first = a.latestDate;
	    NSDate* second = b.latestDate; 
	    return [second compare:first];
	}];
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
	_procs = [NSMutableArray new];
	//loop through all logs
	NSString* const logsDirectory = @"/var/mobile/Library/Cr4shed";
	NSMutableArray* files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil] mutableCopy];
	for (int i = 0; i < files.count; i++)
	{
		NSString* fileName = files[i];
		NSString* filePath = [logsDirectory stringByAppendingPathComponent:fileName];
		if (![[fileName pathExtension] isEqualToString:@"log"])
		{
			[files removeObjectAtIndex:i];
			i--;
			continue;
		}
		//file is a log
		Process* proc = nil;
		NSArray<NSString*>* comp = [fileName componentsSeparatedByString:@"@"];
		NSString* procName = comp.count > 1 ? comp[0] : @"(null)";

		//check if process is already in array
		for (Process* p in _procs)
		{
			if ([p.name isEqualToString:procName])
			{
				proc = p;
				break;
			}
		}
		if (!proc)
		{
			//process isn't in array, add it
			proc = [[Process alloc] initWithName:procName];
			[_procs addObject:proc];
		}
		Log* log = [[Log alloc] initWithPath:filePath];
		[proc.logs addObject:log];

		NSDate* date = log.date;
		if (!proc.latestDate || [proc.latestDate compare:date] == NSOrderedAscending)
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
	for (Log* log in proc.logs)
	{
		[[NSFileManager defaultManager] removeItemAtPath:log.path error:NULL];
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
