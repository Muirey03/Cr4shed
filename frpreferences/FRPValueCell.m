//
//  FRPValueCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/22/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPValueCell.h"

@implementation FRPValueCell

+ (instancetype)cellWithTitle:(NSString *)title detail:(NSString *)detail {
    return [[self alloc] cellWithTitle:title detail:detail];
}

- (instancetype)cellWithTitle:(NSString *)title detail:(NSString *)detail {
    FRPValueCell *cell = [super initWithTitle:title setting:nil];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.detailTextLabel.text = detail;
    return cell;
}

@end
