//
//  FRPSettings.m
//  FRPreferences
//
//  Created by Fouad Raheb on 5/5/15.
//  Copyright (c) 2015 F0u4d. All rights reserved.
//

#import "FRPSettings.h"

@interface FRPSettings ()
typedef void(^FRPSettingValueDidChangeBlock)(void);
@property (nonatomic, copy) FRPSettingValueDidChangeBlock valueDidChangeBlock;
@end

@implementation FRPSettings

+ (instancetype)settingsWithKey:(NSString *)key defaultValue:(id)defaultValue {
    return [[self alloc] initWithKey:key defaultValue:defaultValue];
}

- (instancetype)initWithKey:(NSString *)key defaultValue:(id)defaultValue {
    if (self = [super init]) {
        self.key = key;
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{self.key: defaultValue}];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (self.valueDidChangeBlock) {
        self.valueDidChangeBlock();
    }
}

- (id)value {
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.key];
}

- (void)setValue:(id)value {
    if (self.value != value) {
        [[NSUserDefaults standardUserDefaults] setObject:value forKey:self.key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if ([self.fileSave length] > 0) {
            [self saveValue:value];
        }
    }
}

- (void)saveValue:(id)value {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:self.fileSave];
    if (dict == nil) dict = [NSMutableDictionary new];
    [dict setObject:value forKey:self.key];
    [dict writeToFile:self.fileSave atomically:YES];
}

@end