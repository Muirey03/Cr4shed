//
//  FRPSettings.h
//  FRPreferences
//
//  Created by Fouad Raheb on 5/5/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FRPSettings : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSString *fileSave;

+ (instancetype)settingsWithKey:(NSString *)key defaultValue:(id)defaultValue;
@end
