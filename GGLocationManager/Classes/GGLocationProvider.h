//
//  GGLocationProvider.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGLocationDefines.h"
#import "GGLocationConfig.h"
#import "GGLocationModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GGLocationProvider;

@protocol GGLocationProviderDelegate <NSObject>

/// 定位成功。
/// @param location 坐标（必非 nil）
/// @param geo 逆地理编码结果（仅 needGeo 且成功时非 nil）
/// @param isFinal 单次定位成功即 YES，Provider 应停止
- (void)provider:(id<GGLocationProvider>)provider
 didUpdateLocation:(CLLocation *)location
             geo:(nullable GGLocationModel *)geo
        isFinal:(BOOL)isFinal;

/// 失败（权限拒绝、超时、定位失败、逆地理编码失败等所有失败路径）
- (void)provider:(id<GGLocationProvider>)provider
 didFailWithError:(NSError *)error;

@end

@protocol GGLocationProvider <NSObject>

@property (nonatomic, weak, nullable) id<GGLocationProviderDelegate> delegate;

/// 应用配置
- (void)applyConfig:(GGLocationConfig *)config;

/// 当前是否已授权（Provider 自行判断，Manager 不感知权限库）
- (BOOL)isAuthorized;

/// 单次定位
- (void)requestSingleLocationWithNeedGeo:(BOOL)needGeo;

/// 持续定位
- (void)startUpdatingLocationWithNeedGeo:(BOOL)needGeo;

/// 停止
- (void)stopUpdatingLocation;

@end

NS_ASSUME_NONNULL_END
