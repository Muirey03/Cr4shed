#import "CRALogController.h"

@implementation CRALogController
-(id)initWithLog:(NSString*)logFile
{
    self = [self init];
    if (self)
    {
        _log = logFile;
    }
    return self;
}

-(void)loadView
{
	[super loadView];

    self.view.backgroundColor = [UIColor whiteColor];
    NSArray<NSString*>* comp = [_log componentsSeparatedByString:@"@"];
    NSString* title = comp.count > 1 ? comp[1] : comp[0];
	self.title = title;

    UIBarButtonItem* backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;

    UIBarButtonItem* shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(share:)];
    self.navigationItem.rightBarButtonItem = shareButton;

    textView = [UITextView new];
    textView.editable = NO;
    NSString* path = [NSString stringWithFormat:@"/var/tmp/crash_logs/%@", _log];
    logMessage = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    textView.text = logMessage;
    textView.alwaysBounceVertical = YES;
    [self.view addSubview:textView];

    textView.translatesAutoresizingMaskIntoConstraints = NO;
    [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
    [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
    [textView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
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

-(void)share:(id)sender
{
    NSArray* activityItems = @[logMessage];
    UIActivityViewController* activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityViewControntroller.popoverPresentationController.sourceView = self.view;
        activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/4, 0, 0);
    }
    [self presentViewController:activityViewControntroller animated:YES completion:nil];
}
@end
