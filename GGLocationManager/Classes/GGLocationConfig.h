//
//  GGLocationConfig.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// 定位配置值对象。
/// 不暴露 CLLocationManager / AMapLocationManager，由各 Provider 自行映射。
@interface GGLocationConfig : NSObject <NSCopying>

/// 定位精度，默认 kCLLocationAccuracyBest
@property (nonatomic, assign) CLLocationAccuracy desiredAccuracy;

/// 距离过滤，默认 kCLDistanceFilterNone
@property (nonatomic, assign) CLLocationDistance distanceFilter;

/// 单次定位超时（Manager 层兜底），默认 20s
/// 注意：GGPermission 内部有 15s 超时，此值应大于 15s，避免双重超时。
@property (nonatomic, assign) NSTimeInterval singleLocationTimeout;

+ (instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END