//
//  FRListCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPListCell.h"
#import "FRPSelectListTable.h"

@interface FRPListCell ()
@end

@implementation FRPListCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting items:(NSArray *)items value:(NSArray *)values popViewOnSelect:(BOOL)pop postNotification:(NSString *)notification changedBlock:(FRPListItemChange)block {
    return [[self alloc] cellWithTitle:title setting:setting items:items value:values popViewOnSelect:pop postNotification:(NSString *)notification changedBlock:block];
}


- (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting items:(NSArray *)items value:(NSArray *)values popViewOnSelect:(BOOL)pop postNotification:(NSString *)notification changedBlock:(FRPListItemChange)block {
    FRPListCell *cell = [super initWithTitle:title setting:setting];
    [cell setValueChanged:block];
    cell.items = items;
    cell.values = values;
    self.popView = pop;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([self.values containsObject:setting.value])
        cell.detailTextLabel.text = [self.items objectAtIndex:[self.values indexOfObject:setting.value]];

    return cell;
}

- (void)didSelectFromTable:(FRPreferences *)viewController {
    NSIndexPath *indexPath = [viewController.tableView indexPathForCell:self];
    [viewController.tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [viewController.tableView cellForRowAtIndexPath:indexPath];
    
    FRPSelectListTable *selectionList = [[FRPSelectListTable alloc] initWithStyle:UITableViewStyleGrouped title:cell.textLabel.text items:self.items values:self.values currentValue:self.setting.value popViewOnSelect:self.popView changeBlock:^(NSString *item) {
        cell.detailTextLabel.text = item;
        NSString *valueOfItem = [self.values objectAtIndex:[self.items indexOfObject:item]];
        self.setting.value = valueOfItem;
        if (self.valueChanged) {
            self.valueChanged(valueOfItem);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:self.postNotification object:valueOfItem];
    }];
    selectionList.tintUIColor = self.tintUIColor;
    if (viewController.navigationController) {
        [viewController.navigationController pushViewController:selectionList animated:YES];
    } else {
        [viewController.navigationController presentViewController:selectionList animated:YES completion:nil];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
}
@end
