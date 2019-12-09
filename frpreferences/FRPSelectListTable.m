//
//  FRPSelectionListViewController.m
//  FRPreferences
//
//  Created by Fouad Raheb on 5/10/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPSelectListTable.h"

@implementation FRPSelectListTable

- (instancetype)initWithStyle:(UITableViewStyle)style title:(NSString *)title items:(NSArray *)items values:(NSArray *)values currentValue:(NSString *)value popViewOnSelect:(BOOL)back changeBlock:(FRPListItemChange)block {
    listItems = items;
    listValues = values;
    currentValue = value;
    popView = back;
    pageTitle = title;
    self.itemChanged = ^(id sender) {
        if (block) block(sender);
    };
    return [self initWithStyle:style];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = pageTitle;
    self.view.tintColor = self.tintUIColor;
    self.tableView.tintColor = self.tintUIColor;
    self.navigationController.navigationBar.tintColor = self.tintUIColor;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)theTableView numberOfRowsInSection:(NSInteger)section {
    return [listItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"LinkCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [listItems objectAtIndex:[indexPath row]];
    if ([[listValues objectAtIndex:[indexPath row]] isEqualToString:currentValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.itemChanged([listItems objectAtIndex:[indexPath row]]);

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    for (UITableViewCell *cell in tableView.visibleCells) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    if (popView)
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
