//
//  GGLocationDefines.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 定位类型

typedef NS_ENUM(NSInteger, GGLocationManagerLocationType) {
    /// 单次定位：拿到一次结果后自动停止
    GGLocationManagerLocationType_Single = 0,
    /// 持续定位：直到调用 stopUpdatingLocation
    GGLocationManagerLocationType_Keep,
};

#pragma mark - 错误码

typedef NS_ENUM(NSInteger, GGLocationErrorCode) {
    /// 未知错误 / 未引入对应 subspec
    GGLocationErrorCode_Unknown = -1,
    /// 权限被拒绝
    GGLocationErrorCode_PermissionDenied = 1001,
    /// 超时（Provider 未在约定时间内回调）
    GGLocationErrorCode_Timeout = 1002,
    /// 定位失败（系统/高德返回错误）
    GGLocationErrorCode_LocationFailed = 1003,
    /// 逆地理编码失败
    GGLocationErrorCode_GeocodeFailed = 1004,
    /// 用户主动取消
    GGLocationErrorCode_Cancelled = 1005,
    /// 权限受限（家长控制、MDM 等）
    GGLocationErrorCode_PermissionRestricted = 1006,
    /// 系统级服务被禁用（定位总开关关闭）
    GGLocationErrorCode_PermissionServiceDisabled = 1007,
};

#pragma mark - 错误域

FOUNDATION_EXPORT NSErrorDomain const GGLocationErrorDomain;

NS_ASSUME_NONNULL_END