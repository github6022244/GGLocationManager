//
//  GGSystemLocationProvider.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "GGLocationProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// 系统定位 Provider（CLLocationManager + CLGeocoder）
@interface GGSystemLocationProvider : NSObject <GGLocationProvider, CLLocationManagerDelegate>
@end

NS_ASSUME_NONNULL_END