//
//  GGLocationModel.m
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGLocationModel.h"

@implementation GGLocationModel

- (NSString *)description {
    return [NSString stringWithFormat:
            @"<GGLocationModel: %p> lat=%f lon=%f country=%@ province=%@ city=%@ district=%@ street=%@ number=%@",
            self, self.latitude, self.longitude,
            self.country, self.administrativeArea, self.locality,
            self.subLocality, self.thoroughfare, self.subThoroughfare];
}

@end