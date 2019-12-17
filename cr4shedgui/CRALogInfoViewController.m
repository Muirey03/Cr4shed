#import <objc/runtime.h>
#import "CRALogInfoViewController.h"
#import "Log.h"
#import "CRALogController.h"
#import "../sharedutils.h"
#import "dpkgutils.h"
#import "UIImage+UIKitImage.h"

@implementation CRALogInfoViewController
{
	NSMutableArray<NSDictionary*>* _infoFormat;
}

-(instancetype)initWithLog:(Log*)log
{
    if ((self = [self init]))
    {
        _log = log;
		_info = log.info;
        self.title = [NSString stringWithFormat:@"%@ (%@)", log.processName, stringFromDate(log.date, CR4DateFormatTimeOnly)];
    
		_infoFormat = [@[
			@{
				@"DisplayName" : @"Crash Date",
				@"Value" : stringFromDate(log.date, CR4DateFormatPretty) ?: @"N/A"
			},
			@{
				@"DisplayName" : @"Culprit",
				@"Value" : _info[@"Culprit"] ?: @"Unknown",
				@"HasAction" : @(_info[@"Culprit"] && ![_info[@"Culprit"] isEqualToString:@"Unknown"])
			}
		] mutableCopy];
		NSString* reason = _info[@"NSExceptionReason"];
		if (reason)
		{
			[_infoFormat addObject:@{
				@"DisplayName" : @"Reason",
				@"Value" : reason,
				@"Copyable" : @YES
			}];
		}
	}
    return self;
}

-(void)loadView
{
	[super loadView];

	_tableView = [UITableView new];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:_tableView];

	[_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
	[_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
	[_tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
	[_tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;

	const CGFloat footerHeight = 65.;
	const CGFloat btnPadding = 10.;
	const CGFloat btnCornerRadius = 10.;

	_tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 0., footerHeight)];
	UIBlurEffect* blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	UIVisualEffectView* footer = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	[self.view addSubview:footer];

	footer.translatesAutoresizingMaskIntoConstraints = NO;
	[footer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
	[footer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
	[footer.heightAnchor constraintEqualToConstant:footerHeight].active = YES;
	if ([self.view respondsToSelector:@selector(safeAreaLayoutGuide)])
		[footer.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
	else
		[footer.bottomAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.bottomAnchor].active = YES;

	UIButton* viewLogBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	viewLogBtn.translatesAutoresizingMaskIntoConstraints = NO;
	viewLogBtn.layer.cornerRadius = btnCornerRadius;
	viewLogBtn.clipsToBounds = YES;
	[viewLogBtn addTarget:self action:@selector(viewLog) forControlEvents:UIControlEventTouchUpInside];
	[viewLogBtn setTitle:@"View Log" forState:UIControlStateNormal];
	[viewLogBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	viewLogBtn.backgroundColor = [UIColor systemBlueColor];
	[footer.contentView addSubview:viewLogBtn];
	[viewLogBtn.leadingAnchor constraintEqualToAnchor:footer.leadingAnchor constant:btnPadding].active = YES;
	[viewLogBtn.trailingAnchor constraintEqualToAnchor:footer.trailingAnchor constant:btnPadding * -1].active = YES;
	[viewLogBtn.topAnchor constraintEqualToAnchor:footer.topAnchor constant:btnPadding].active = YES;
	[viewLogBtn.bottomAnchor constraintEqualToAnchor:footer.bottomAnchor constant:btnPadding * -1].active = YES;
}

-(void)viewDidAppear:(BOOL)arg1
{
    [super viewDidAppear:arg1];
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

-(void)viewLog
{
	CRALogController* logVC = [[CRALogController alloc] initWithLog:_log];
	[self.navigationController pushViewController:logVC animated:YES];
}

-(void)displayErrorAlert:(NSString*)body
{
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error" message:body preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction* dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
	[alert addAction:dismiss];
	[self presentViewController:alert animated:YES completion:nil];
}

-(void)composeEmail
{
	if ([MFMailComposeViewController canSendMail])
	{
		NSString* culpritFile = [@"/Library/MobileSubstrate/DynamicLibraries" stringByAppendingPathComponent:_log.info[@"Culprit"]];
		NSString* package = packageForFile(culpritFile);
		if (package)
		{
			NSString* packageName = controlFieldForPackage(package, @"Name");
			NSString* maintainer = controlFieldForPackage(package, @"Maintainer");
			NSString* version = controlFieldForPackage(package, @"Version");

			MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
			composeVC.mailComposeDelegate = self;
			
			NSString* subject = [NSString stringWithFormat:@"Cr4shed Report: %@ (%@)", packageName, version];
			NSString* body = [NSString stringWithFormat:@"Your package (%@) has been determined to be the culprit of the attached crash.\n\nAdditional Details:\n\n", package];
			NSData* logData = [_log.contents dataUsingEncoding:NSUTF8StringEncoding];

			composeVC.toRecipients = @[maintainer];
			composeVC.subject = subject;
			[composeVC setMessageBody:body isHTML:NO];
			[composeVC addAttachmentData:logData mimeType:@"text/plain" fileName:[_log.path lastPathComponent]];
			[self presentViewController:composeVC animated:YES completion:nil];
		}
		else
			[self displayErrorAlert:@"Unable to find package for culprit"];
	}
	else
		[self displayErrorAlert:@"Unable to compose email"];
}

#pragma mark - Table View Data Source

-(NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
	return 1;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return _infoFormat.count + 1;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCellStyle style = UITableViewCellStyleDefault;
	UIImage* img = nil;
	NSString* text = nil;
	NSString* detail = nil;
	BOOL needsIndicator = NO;
	BOOL canWrapDetail = NO;
	switch (indexPath.row)
	{
		case 0:
		{
			NSString* bundleID = _info[@"ProcessBundleID"];
			style = UITableViewCellStyleSubtitle;
			text = _log.processName;
			detail = bundleID;
			img = [[UIImage _applicationIconImageForBundleIdentifier:bundleID format:2 scale:3.] resizeToHeight:60.];
			break;
		}
		default:
		{
			NSDictionary* infoRow = _infoFormat[indexPath.row - 1];
			style = UITableViewCellStyleValue1;
			text = infoRow[@"DisplayName"];
			detail = infoRow[@"Value"];
			needsIndicator = [infoRow[@"HasAction"] boolValue];
			canWrapDetail = YES;
			break;
		}
	}

	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"LogInfoCell"];
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:@"LogInfoCell"];
	cell.textLabel.text = text;
	cell.detailTextLabel.text = detail;
	if (canWrapDetail)
	{
		cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
		cell.detailTextLabel.numberOfLines = 0;
	}
	cell.clipsToBounds = YES;
	cell.imageView.image = img;
	if (needsIndicator)
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}

#pragma mark - Table View Delegate

-(void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	[self composeEmail];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
	switch (indexPath.row)
	{
		case 0:
			return 75.;
		default:
		{
			NSString* name = _infoFormat[indexPath.row - 1][@"DisplayName"];
			NSString* text = _infoFormat[indexPath.row - 1][@"Value"];
			UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
			CGRect nameRect = [name boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : cell.textLabel.font} context:nil];
			CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(tableView.frame.size.width - nameRect.size.width - 36., 0.) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : cell.detailTextLabel.font} context:nil];
			return boundingRect.size.height + 25.;
		}
	}
}

-(NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.row > 0 && [_infoFormat[indexPath.row - 1][@"HasAction"] boolValue])
		return indexPath;
	return nil;
}

-(BOOL)tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.row)
	{
		NSDictionary* info = _infoFormat[indexPath.row - 1];
		return [info[@"Copyable"] boolValue] || [info[@"HasAction"] boolValue];
	}
    return NO;
}

-(BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.row)
	{
		NSDictionary* info = _infoFormat[indexPath.row - 1];
		return [info[@"Copyable"] boolValue];
	}
    return NO;
}

-(BOOL)tableView:(UITableView*)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender
{
    return sel_isEqual(action, @selector(copy:));
}

-(void)tableView:(UITableView*)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath*)indexPath withSender:(id)sender
{
    if (sel_isEqual(action, @selector(copy:)))
	{
        NSDictionary* info = _infoFormat[indexPath.row - 1];
        UIPasteboard* pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:info[@"Value"]];
    }
}

#pragma mark Mail Compose Controller Delegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	[controller dismissViewControllerAnimated:YES completion:nil];
}

@end
