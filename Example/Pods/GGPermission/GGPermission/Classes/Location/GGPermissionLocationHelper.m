//
//  GGPermissionLocationHelper.m
//  GGPermission
//
//  Created by GG on 2026/9/20.
//

#import "GGPermissionLocationHelper.h"

@implementation GGPermissionLocationHelper

+ (CLAuthorizationStatus)currentAuthorizationStatus {
    if (@available(iOS 14.0, *)) {
        return [self sharedManager].authorizationStatus;
    } else {
        return [CLLocationManager authorizationStatus];
    }
}

+ (BOOL)isAuthorized {
    CLAuthorizationStatus status = [self currentAuthorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedAlways ||
           status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

+ (BOOL)isGlobalLocationServiceEnabled {
    return [CLLocationManager locationServicesEnabled];
}

+ (CLLocationManager *)sharedManager {
    static CLLocationManager *sManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sManager = [[CLLocationManager alloc] init];
    });
    return sManager;
}

@end
