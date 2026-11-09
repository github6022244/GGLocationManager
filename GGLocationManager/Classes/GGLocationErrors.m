//
//  GGLocationErrors.m
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGLocationErrors.h"

#import <CoreLocation/CoreLocation.h>

#if __has_include(<GGPermission.h>)
#import <GGPermission.h>
#define GG_LOCATION_HAS_PERMISSION 1
#else
#define GG_LOCATION_HAS_PERMISSION 0
#endif

#pragma mark - Error Domain

NSErrorDomain const GGLocationErrorDomain = @"GGLocationErrorDomain";

#pragma mark - Public

NSError * GGLocationMakeError(GGLocationErrorCode code, NSString * _Nullable description) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (description.length > 0) {
        userInfo[NSLocalizedDescriptionKey] = description;
    }
    return [NSError errorWithDomain:GGLocationErrorDomain
                               code:code
                           userInfo:userInfo.copy];
}

NSError * _Nullable GGLocationMakePermissionError(BOOL granted, NSNumber * _Nullable statusCode) {
    if (granted) { return nil; }

    NSInteger code = statusCode.integerValue;

#if GG_LOCATION_HAS_PERMISSION
    // ========== GGPermission 内部错误（负数）==========
    if (code < 0) {
        switch (code) {
            case GGPermissionErrorUnknown:
                return GGLocationMakeError(GGLocationErrorCode_Unknown,
                                           @"权限状态未知 / 未引入对应 subspec");
            case GGPermissionErrorServiceDisabled:
                return GGLocationMakeError(GGLocationErrorCode_PermissionServiceDisabled,
                                           @"系统级服务被禁用");
            case GGPermissionErrorTimeout:
                return GGLocationMakeError(GGLocationErrorCode_Timeout,
                                           @"权限请求超时");
            case GGPermissionErrorNoTopViewController:
                return GGLocationMakeError(GGLocationErrorCode_PermissionDenied,
                                           @"找不到顶层 VC，无法弹窗引导");
            default:
                return GGLocationMakeError(GGLocationErrorCode_PermissionDenied,
                                           [NSString stringWithFormat:@"权限请求失败（code=%ld）", (long)code]);
        }
    }
#endif

    // ========== 系统原始状态（非负）==========
    CLAuthorizationStatus status = (CLAuthorizationStatus)code;
    switch (status) {
        case kCLAuthorizationStatusRestricted:
            return GGLocationMakeError(GGLocationErrorCode_PermissionRestricted,
                                       @"定位权限受限（家长控制等）");
        case kCLAuthorizationStatusDenied:
            return GGLocationMakeError(GGLocationErrorCode_PermissionDenied,
                                       @"定位权限被拒绝");
        case kCLAuthorizationStatusNotDetermined:
            return GGLocationMakeError(GGLocationErrorCode_PermissionDenied,
                                       @"定位权限未确定");
        default:
            return GGLocationMakeError(GGLocationErrorCode_PermissionDenied,
                                       @"定位权限未授权");
    }
}
