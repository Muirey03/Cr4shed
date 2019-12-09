//
//  FRPSwitchCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPSwitchCell.h"

@implementation FRPSwitchCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting postNotification:(NSString *)notification changeBlock:(FRPSwitchCellChanged)block {
    return [[self alloc] cellWithTitle:title setting:setting postNotification:notification changeBlock:block];
}

- (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting postNotification:(NSString *)notification changeBlock:(FRPSwitchCellChanged)block {
    FRPSwitchCell *cell = [super initWithTitle:title setting:setting];
    cell.postNotification = notification;
    cell.valueChanged = block;
    self.switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
    [self.switchView setOn:[self.setting.value boolValue] animated:NO];
    [self.switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = self.switchView;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)switchChanged:(UISwitch *)switchItem {
    self.setting.value = [NSNumber numberWithBool:[switchItem isOn]];
    if (self.valueChanged) {
        self.valueChanged(switchItem);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:self.postNotification object:switchItem];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.switchView.onTintColor = self.tintUIColor;
//    self.switchView.tintColor = self.tintUIColor;
}

@end
