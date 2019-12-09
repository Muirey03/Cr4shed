//
//  FRPSegmentCell.m
//  FRPreferences
//
//  Created by Fouad Raheb on 7/19/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPSegmentCell.h"

@interface FRPSegmentCell ()
@property (nonatomic, strong) UISegmentedControl *segment;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, strong) NSArray *displayedValues;
@end

@implementation FRPSegmentCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting items:(NSArray *)items postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block {
    return [[self alloc] cellWithTitle:title setting:setting values:items displayedValues:items postNotification:notification changeBlock:block];
}

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values displayedValues:(NSArray *)displayedValues postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block {
    return [[self alloc] cellWithTitle:title setting:setting values:values displayedValues:displayedValues postNotification:notification changeBlock:block];
}

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block {
    return [[self alloc] cellWithTitle:title setting:setting values:values displayedValues:nil postNotification:notification changeBlock:block];
}

- (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values displayedValues:(NSArray *)displayedValues postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block {
    FRPSegmentCell *cell = [super initWithTitle:title setting:setting];
    cell.setting = setting;
    cell.postNotification = notification;
    [cell setValueChanged:block];
    self.values = values;
    self.displayedValues = displayedValues;
    if (!self.displayedValues) {
        self.displayedValues = values;
    }
    
    self.segment = [[UISegmentedControl alloc] initWithItems:self.displayedValues];
    [self.segment addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
    self.segment.selectedSegmentIndex = [self.values indexOfObject:cell.setting.value];
    
    cell.accessoryView = self.segment;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (void)segmentAction:(UISegmentedControl *)segment {
    NSString *selectedItem = [self.values objectAtIndex:segment.selectedSegmentIndex];
    self.setting.value = selectedItem;
    if (self.valueChanged) {
        self.valueChanged(selectedItem);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:self.postNotification object:selectedItem];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.segment.tintColor = self.tintUIColor;
}
@end
