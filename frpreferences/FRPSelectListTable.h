//
//  FRPSelectionListViewController.h
//  FRPreferences
//
//  Created by Fouad Raheb on 5/10/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FRPListCell.h"

@interface FRPSelectListTable : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
    NSArray *listItems;
    NSArray *listValues;
    NSString *currentValue;
    NSString *pageTitle;
    BOOL popView;
}
@property (nonatomic, copy) FRPListItemChange itemChanged;
@property (nonatomic, copy) UIColor *tintUIColor;

- (instancetype)initWithStyle:(UITableViewStyle)style title:(NSString *)title items:(NSArray *)items values:(NSArray *)values currentValue:(NSString *)value popViewOnSelect:(BOOL)back changeBlock:(FRPListItemChange)block;

@end