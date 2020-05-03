#import <objc/runtime.h>
#import "CRALogInfoViewController.h"
#import "Log.h"
#import "CRALogController.h"
#import <sharedutils.h>
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
				@"Copyable" : @YES,
				@"SubtitleStyle" : @YES
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
	UIBlurEffect* blurEffect;
	if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){13,0,0}])
		blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
	else
		blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	UIVisualEffectView* footer = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	[self.view addSubview:footer];

	footer.translatesAutoresizingMaskIntoConstraints = NO;
	[footer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
	[footer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
	[footer.heightAnchor constraintEqualToConstant:footerHeight].active = YES;
	if ([self.view respondsToSelector:@selector(safeAreaLayoutGuide)])
		[footer.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor].active = YES;
	else
		[footer.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor].active = YES;

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
	return 2;
}

-(NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
	return section == 0 ? 1 : _infoFormat.count;
}

-(UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
	UITableViewCell* cell;
	if (indexPath.section == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"LogInfoHeaderCell"];
		if (!cell)
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LogInfoHeaderCell"];

		NSString* bundleID = _info[@"ProcessBundleID"];
		cell.textLabel.text = _log.processName;
		cell.detailTextLabel.text = bundleID;
		cell.imageView.image = [[UIImage _applicationIconImageForBundleIdentifier:bundleID format:2 scale:3.] resizeToHeight:60.];
	}
	else
	{
		NSDictionary* infoRow = _infoFormat[indexPath.row];
		UITableViewCellStyle style = [infoRow[@"SubtitleStyle"] boolValue] ? UITableViewCellStyleSubtitle : UITableViewCellStyleValue1;
		NSString* identifier = [infoRow[@"SubtitleStyle"] boolValue] ? @"LogInfoSubtitleCell" : @"LogInfoCell";
		cell = [tableView dequeueReusableCellWithIdentifier:identifier];
		if (!cell)
			cell = [[UITableViewCell alloc] initWithStyle:style reuseIdentifier:identifier];
		
		cell.textLabel.text = infoRow[@"DisplayName"];
		cell.detailTextLabel.text = infoRow[@"Value"];
		if ([infoRow[@"HasAction"] boolValue])
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
		cell.detailTextLabel.numberOfLines = 0;
		cell.clipsToBounds = YES;
	}
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
	//hardcode header height
	if (indexPath.section == 0)
		return 75.;

	//normal cells and iOS 11 work with automagic
	if (![_infoFormat[indexPath.row][@"SubtitleStyle"] boolValue] || [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){11, 0, 0}])
		return UITableViewAutomaticDimension;

	//UIKit bug on iOS < 11:
	//UITableViewAutomaticDimension ignores detailTextLabel
	//so we need to calculate height ourself
	NSString* text = _infoFormat[indexPath.row][@"Value"];
	UITableViewCell* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(tableView.frame.size.width - 30., 0.) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : cell.detailTextLabel.font} context:nil];
	return boundingRect.size.height + 42.;
}

-(NSIndexPath*)tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.section == 1 && [_infoFormat[indexPath.row][@"HasAction"] boolValue])
		return indexPath;
	return nil;
}

-(BOOL)tableView:(UITableView*)tableView shouldHighlightRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.section == 1)
	{
		NSDictionary* info = _infoFormat[indexPath.row];
		return [info[@"Copyable"] boolValue] || [info[@"HasAction"] boolValue];
	}
	return NO;
}

-(BOOL)tableView:(UITableView*)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath*)indexPath
{
	if (indexPath.section == 1)
	{
		NSDictionary* info = _infoFormat[indexPath.row];
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
	if (indexPath.section == 1 && sel_isEqual(action, @selector(copy:)))
	{
		NSDictionary* info = _infoFormat[indexPath.row];
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
