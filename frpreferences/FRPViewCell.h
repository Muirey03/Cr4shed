//
//  FRPViewCell.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/3/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

typedef void (^FRPViewCellBlock)(UITableViewCell *cell);

@interface FRPViewCell : FRPCell

+ (instancetype)cellWithHeight:(int)height initBlock:(FRPViewCellBlock)initBlock layoutBlock:(FRPViewCellBlock)layoutBlock;

@property (nonatomic, strong) FRPViewCellBlock layoutBlock;
@property (nonatomic, assign) BOOL hideSeperators;

@end
