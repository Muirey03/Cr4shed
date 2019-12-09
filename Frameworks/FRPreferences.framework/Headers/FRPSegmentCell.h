//
//  FRPSegmentCell.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/19/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

typedef void (^FRPSegmentValueChanged)(NSString *value);

@interface FRPSegmentCell : FRPCell

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting items:(NSArray *)items postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block __attribute__((deprecated("use instead +cellWithTitle:setting:values:displayedValues:postNotification:changeBlock")));

+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values displayedValues:(NSArray *)displayedValues postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block;
+ (instancetype)cellWithTitle:(NSString *)title setting:(FRPSettings *)setting values:(NSArray *)values postNotification:(NSString *)notification changeBlock:(FRPSegmentValueChanged)block;

@end
