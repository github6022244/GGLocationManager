//
//  GGAmapLocationProvider.m
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGAmapLocationProvider.h"
#import "GGLocationErrors.h"

#if __has_include(<AMapLocationKit/AMapLocationKit.h>)
#import <AMapLocationKit/AMapLocationKit.h>
#import <GGPermission.h>

@interface GGAmapLocationProvider () <AMapLocationManagerDelegate>
@property (nonatomic, strong) AMapLocationManager *amapLocationManager;
@property (nonatomic, assign) BOOL needGeo;
@property (nonatomic, assign) BOOL isSingle;
@property (nonatomic, assign) BOOL didDeliverFinal;
@property (nonatomic, assign) BOOL permissionRequesting;
@end

@implementation GGAmapLocationProvider
@synthesize delegate = _delegate;

- (instancetype)init {
    if (self = [super init]) {
        _amapLocationManager = [AMapLocationManager new];
        _amapLocationManager.delegate = self;
    }
    return self;
}

#pragma mark - GGLocationProvider

- (void)applyConfig:(GGLocationConfig *)config {
    self.amapLocationManager.desiredAccuracy = config.desiredAccuracy;
    self.amapLocationManager.distanceFilter = config.distanceFilter;
}

- (BOOL)isAuthorized {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedAlways
        || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (void)requestSingleLocationWithNeedGeo:(BOOL)needGeo {
    self.needGeo = needGeo;
    self.isSingle = YES;
    self.didDeliverFinal = NO;
    [self _ensurePermissionThenStart:^{
        [self _doRequestSingleLocation];
    }];
}

- (void)startUpdatingLocationWithNeedGeo:(BOOL)needGeo {
    self.needGeo = needGeo;
    self.isSingle = NO;
    self.didDeliverFinal = NO;
    [self _ensurePermissionThenStart:^{
        [self.amapLocationManager startUpdatingLocation];
    }];
}

- (void)stopUpdatingLocation {
    [self.amapLocationManager stopUpdatingLocation];
}

#pragma mark - Permission

- (void)_ensurePermissionThenStart:(void (^)(void))startBlock {
    if ([self isAuthorized]) {
        startBlock();
        return;
    }
    if (self.permissionRequesting) { return; }
    self.permissionRequesting = YES;

    __weak __typeof(self) weakSelf = self;
    [[GGPermission shareInstance] permissonType:GGPermissionTypeLocationAlways
                                     withHandle:^(BOOL granted, NSNumber *statusCode) {
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self) { return; }
        self.permissionRequesting = NO;

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted) {
                [self.delegate provider:self
                       didFailWithError:GGLocationMakePermissionError(granted, statusCode)];
                return;
            }
            startBlock();
        });
    }];
}

#pragma mark - Single

- (void)_doRequestSingleLocation {
    __weak __typeof(self) weakSelf = self;
    [self.amapLocationManager requestLocationWithReGeocode:self.needGeo
                                          completionBlock:^(CLLocation *location,
                                                            AMapLocationReGeocode *regeocode,
                                                            NSError *error) {
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self) { return; }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.didDeliverFinal) { return; }
            self.didDeliverFinal = YES;
            [self.amapLocationManager stopUpdatingLocation];

            if (error) {
                [self.delegate provider:self
                       didFailWithError:GGLocationMakeError(GGLocationErrorCode_LocationFailed,
                                                            error.localizedDescription)];
                return;
            }
            if (!location) {
                [self.delegate provider:self
                       didFailWithError:GGLocationMakeError(GGLocationErrorCode_LocationFailed,
                                                            @"高德单次定位返回空位置")];
                return;
            }
            GGLocationModel *geo = [self _geoModelWithLocation:location regeocode:regeocode];
            [self.delegate provider:self didUpdateLocation:location geo:geo isFinal:YES];
        });
    }];
}

#pragma mark - AMapLocationManagerDelegate

- (void)amapLocationManager:(AMapLocationManager *)manager
      doRequireLocationAuth:(CLLocationManager *)locationManager {
    // 权限统一由 GGPermission 管理，此处不再重复 requestAlwaysAuthorization，
    // 避免与 GGPermission 的弹窗流程竞争。
}

- (void)amapLocationManager:(AMapLocationManager *)manager
          didUpdateLocation:(CLLocation *)location
                  reGeocode:(AMapLocationReGeocode *)reGeocode {
    if (self.isSingle) { return; }
    if (!location) { return; }

    GGLocationModel *geo = self.needGeo ? [self _geoModelWithLocation:location regeocode:reGeocode] : nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate provider:self didUpdateLocation:location geo:geo isFinal:NO];
    });
}

- (void)amapLocationManager:(AMapLocationManager *)manager
           didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate provider:self
               didFailWithError:GGLocationMakeError(GGLocationErrorCode_LocationFailed,
                                                    error.localizedDescription)];
    });
}

#pragma mark - Mapping

- (GGLocationModel *)_geoModelWithLocation:(CLLocation *)location
                                regeocode:(AMapLocationReGeocode *)regeocode {
    if (!location || !regeocode) { return nil; }
    GGLocationModel *model = [GGLocationModel new];
    model.latitude = location.coordinate.latitude;
    model.longitude = location.coordinate.longitude;
    model.country = regeocode.country;
    model.administrativeArea = regeocode.province;
    model.locality = regeocode.city;
    model.subLocality = regeocode.district;
    model.thoroughfare = regeocode.street;
    model.subThoroughfare = regeocode.number;
    return model;
}

@end
#endif
