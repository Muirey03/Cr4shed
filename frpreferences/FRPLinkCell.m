//
//  FRPLinkCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPLinkCell.h"

@interface FRPLinkCell ()
@end

@implementation FRPLinkCell

+ (instancetype)cellWithTitle:(NSString *)title selectedBlock:(FRPLinkCellSelected)block {
    return [[self alloc] cellWithTitle:title selectedBlock:block];
}

- (instancetype)cellWithTitle:(NSString *)title selectedBlock:(FRPLinkCellSelected)block {
    FRPLinkCell *cell = [super initWithTitle:title setting:nil];
    cell.valueChanged = block;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)didSelectFromTable:(FRPreferences *)viewController {
    NSIndexPath *indexPath = [viewController.tableView indexPathForCell:self];
    [viewController.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.valueChanged) {
        self.valueChanged(self);
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
