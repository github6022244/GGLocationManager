//
//  GGPermissionLocationRequest.m
//  GGPermission_Example
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermissionLocationRequest.h"
#import "GGPermissionBaseRequest.h"
#import "GGPermissionLocationHandler.h"
#import <CoreLocation/CoreLocation.h>
#import "GGPermissionLocationHelper.h"

@interface GGPermissionLocationRequest () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *manager;
@end

@implementation GGPermissionLocationRequest

#pragma mark - 发起请求
- (void)startRequest:(GGPermissionType)type callback:(GGPermissionCallback)callback {
    [self prepareForNewRequest];
    self.callback = callback;

    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;

    if (type == GGPermissionTypeLocationWhen) {
        [self.manager requestWhenInUseAuthorization];
    } else {
        [self.manager requestAlwaysAuthorization];
    }

    [self startTimeoutIfNeeded];
}

#pragma mark - 基类 hook

- (void)onCancel {
    [self cleanManager];
}

- (NSNumber *)currentSystemStatus {
    CLAuthorizationStatus status = [GGPermissionLocationHelper currentAuthorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) return nil;
    return @(status);
}

#pragma mark - 内部

- (void)cleanManager {
    if (self.manager) {
        self.manager.delegate = nil;
        self.manager = nil;
    }
}

#pragma mark - CLLocationManagerDelegate

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    if (@available(iOS 14.0, *)) {
        CLAuthorizationStatus status = manager.authorizationStatus;
        if (status == kCLAuthorizationStatusNotDetermined) return;
        BOOL granted = (status == kCLAuthorizationStatusAuthorizedAlways ||
                        status == kCLAuthorizationStatusAuthorizedWhenInUse);
        [self executeCallback:granted statusCode:@(status)];
    }
}
#endif

- (void)locationManager:(CLLocationManager *)manager
    didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    // iOS 14+ 会优先走 locationManagerDidChangeAuthorization，这里仅向下兼容
    if (@available(iOS 14.0, *)) return;
    if (status == kCLAuthorizationStatusNotDetermined) return;
    BOOL granted = (status == kCLAuthorizationStatusAuthorizedAlways ||
                    status == kCLAuthorizationStatusAuthorizedWhenInUse);
    [self executeCallback:granted statusCode:@(status)];
}

@end
