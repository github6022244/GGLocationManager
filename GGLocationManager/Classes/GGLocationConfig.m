//
//  GGLocationConfig.m
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGLocationConfig.h"

@implementation GGLocationConfig

+ (instancetype)defaultConfig {
    GGLocationConfig *config = [GGLocationConfig new];
    config.desiredAccuracy = kCLLocationAccuracyBest;
    config.distanceFilter = kCLDistanceFilterNone;
    config.singleLocationTimeout = 20.0;
    return config;
}

- (id)copyWithZone:(NSZone *)zone {
    GGLocationConfig *copy = [[[self class] allocWithZone:zone] init];
    copy.desiredAccuracy = self.desiredAccuracy;
    copy.distanceFilter = self.distanceFilter;
    copy.singleLocationTimeout = self.singleLocationTimeout;
    return copy;
}

@end