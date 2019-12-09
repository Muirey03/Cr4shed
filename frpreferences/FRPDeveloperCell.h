//
//  FRPDeveloperCell.h
//  FRPreferences
//
//  Created by Fouad Raheb on 7/3/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPCell.h"

@interface FRPDeveloperCell : FRPCell

+ (instancetype)cellWithTitle:(NSString *)title detail:(NSString *)detail image:(UIImage *)image url:(NSString *)url;

@end