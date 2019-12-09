//
//  FRListCell.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

typedef void (^FRPListItemChange)(NSString *value);

@interface FRPListCell : FRPCell
+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting items:(NSArray *)items value:(NSArray *)values popViewOnSelect:(BOOL)pop postNotification:(NSString *)notification changedBlock:(FRPListItemChange)block;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, assign) BOOL popView;
@end
