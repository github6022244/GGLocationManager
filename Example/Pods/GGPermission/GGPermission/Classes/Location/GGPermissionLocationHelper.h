//
//  GGPermissionLocationHelper.h
//  GGPermission
//
//  Created by GG on 2026/9/20.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGPermissionLocationHelper : NSObject

/// 当前定位授权状态
+ (CLAuthorizationStatus)currentAuthorizationStatus;

/// 是否已授权
+ (BOOL)isAuthorized;

/// 系统定位总开关是否开启
+ (BOOL)isGlobalLocationServiceEnabled;

@end

NS_ASSUME_NONNULL_END
