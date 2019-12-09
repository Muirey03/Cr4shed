//
//  FRPLinkCell.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/2/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

typedef void (^FRPLinkCellSelected)(UITableViewCell *sender);

@interface FRPLinkCell : FRPCell

+ (instancetype)cellWithTitle:(NSString *)title selectedBlock:(FRPLinkCellSelected)block;

@end

