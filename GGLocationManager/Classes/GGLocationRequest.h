//
//  GGLocationRequest.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGLocationDefines.h"
#import "GGLocationProvider.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^GGLocationCoordinateBlock)(CLLocation *location);
typedef void (^GGLocationGeoBlock)(GGLocationModel *geoLocation);
typedef void (^GGLocationConfigBlock)(GGLocationConfig *config);
typedef void (^GGLocationFailureBlock)(NSError *error);

/// 请求对象（内部使用，不对外暴露）。
/// 每次调用 updateLocation... 生成一个，单例 Manager 只管理活跃请求列表。
@interface GGLocationRequest : NSObject

@property (nonatomic, assign) GGLocationManagerLocationType locationType;
@property (nonatomic, assign) BOOL needGeo;

@property (nonatomic, copy, nullable) GGLocationCoordinateBlock coordinateBlock;
@property (nonatomic, copy, nullable) GGLocationGeoBlock geoBlock;
@property (nonatomic, copy, nullable) GGLocationFailureBlock failureBlock;

@property (nonatomic, strong) id<GGLocationProvider> provider;
@property (nonatomic, assign) BOOL finished;
@property (nonatomic, strong, nullable) NSTimer *timeoutTimer;

@end

NS_ASSUME_NONNULL_END