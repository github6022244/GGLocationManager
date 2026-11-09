//
//  GGPermissionLocationHandler.m
//  GGPermission_Example
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermissionLocationHandler.h"
#import "GGPermissionLocationRequest.h"
#import "GGPermission.h"
#import "GGPermissionLoggerMacros.h"
#import "GGPermissionLocationHelper.h"

@implementation GGPermissionLocationHandler

#pragma mark - 子类重写

- (GGPermissionBaseRequest *)createRequest {
    return [[GGPermissionLocationRequest alloc] init];
}

- (NSNumber *)currentSystemStatus {
    // 定位总开关关闭 → 返回专用错误码
    if (![CLLocationManager locationServicesEnabled]) {
        return @(GGPermissionErrorServiceDisabled);
    }
    CLAuthorizationStatus status = [GGPermissionLocationHandler currentAuthorizationStatus];
    return @(status);
}

- (BOOL)isGrantedForStatus:(NSNumber *)statusCode {
    NSInteger s = statusCode.integerValue;
    if (s < 0) return NO;
    CLAuthorizationStatus status = (CLAuthorizationStatus)s;
    return status == kCLAuthorizationStatusAuthorizedAlways ||
           status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (BOOL)isDeniedOrRestrictedForStatus:(NSNumber *)statusCode {
    NSInteger s = statusCode.integerValue;
    if (s < 0) return NO;
    CLAuthorizationStatus status = (CLAuthorizationStatus)s;
    return status == kCLAuthorizationStatusDenied ||
           status == kCLAuthorizationStatusRestricted;
}

- (NSString *)guideTipsForType:(GGPermissionType)type {
    GGPermission *main = [GGPermission shareInstance];
    return (type == GGPermissionTypeLocationWhen)
        ? main.locationWhenPushSettingTips
        : main.locationAlwaysPushSettingTips;
}

#pragma mark - 静态查询

+ (CLAuthorizationStatus)currentAuthorizationStatus {
    return [GGPermissionLocationHelper currentAuthorizationStatus];
}

+ (BOOL)isAuthorized {
    return [GGPermissionLocationHelper isAuthorized];
}

+ (CLLocationManager *)sharedCLLocationManager {
    static CLLocationManager *sManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sManager = [[CLLocationManager alloc] init];
    });
    return sManager;
}

+ (BOOL)isGlobalLocationServiceEnabled {
    return [CLLocationManager locationServicesEnabled];
}

@end
