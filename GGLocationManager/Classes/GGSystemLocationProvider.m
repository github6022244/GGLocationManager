//
//  GGSystemLocationProvider.m
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGSystemLocationProvider.h"
#import "GGLocationErrors.h"
#import "GGPermission.h"
#import "GGPermissionLocationHelper.h"

@interface GGSystemLocationProvider ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, assign) BOOL needGeo;
@property (nonatomic, assign) BOOL isSingle;
@property (nonatomic, assign) BOOL didDeliverFinal;
@property (nonatomic, assign) BOOL permissionRequesting;
@end

@implementation GGSystemLocationProvider
@synthesize delegate = _delegate;

- (instancetype)init {
    if (self = [super init]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _geocoder = [CLGeocoder new];
    }
    return self;
}

#pragma mark - GGLocationProvider

- (void)applyConfig:(GGLocationConfig *)config {
    self.locationManager.desiredAccuracy = config.desiredAccuracy;
    self.locationManager.distanceFilter = config.distanceFilter;
}

- (BOOL)isAuthorized {
    return [GGPermissionLocationHelper isAuthorized];
}

- (void)requestSingleLocationWithNeedGeo:(BOOL)needGeo {
    self.needGeo = needGeo;
    self.isSingle = YES;
    self.didDeliverFinal = NO;
    [self _requestPermissionAndStart];
}

- (void)startUpdatingLocationWithNeedGeo:(BOOL)needGeo {
    self.needGeo = needGeo;
    self.isSingle = NO;
    self.didDeliverFinal = NO;
    [self _requestPermissionAndStart];
}

- (void)stopUpdatingLocation {
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Permission

- (void)_requestPermissionAndStart {
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
            [self.locationManager startUpdatingLocation];
        });
    }];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = locations.lastObject;
    if (!newLocation) { return; }

    if (self.isSingle) {
        if (self.didDeliverFinal) { return; }
        self.didDeliverFinal = YES;
        [manager stopUpdatingLocation];
    }

    if (self.needGeo) {
        __weak __typeof(self) weakSelf = self;
        [self.geocoder reverseGeocodeLocation:newLocation
                            completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks,
                                                NSError * _Nullable error) {
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self) { return; }

            GGLocationModel *geo = nil;
            if (placemarks.count > 0) {
                geo = [self _modelFromPlacemark:placemarks.firstObject location:newLocation];
            } else if (self.isSingle) {
                NSError *geoError = error ?: GGLocationMakeError(GGLocationErrorCode_GeocodeFailed,
                                                                 @"逆地理编码失败");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate provider:self didFailWithError:geoError];
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate provider:self
                       didUpdateLocation:newLocation
                                   geo:geo
                              isFinal:self.isSingle];
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate provider:self
                   didUpdateLocation:newLocation
                               geo:nil
                          isFinal:self.isSingle];
        });
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // 单次定位忽略 kCLErrorLocationUnknown（系统会继续尝试）
    if (self.isSingle
        && [error.domain isEqualToString:kCLErrorDomain]
        && error.code == kCLErrorLocationUnknown) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate provider:self
               didFailWithError:GGLocationMakeError(GGLocationErrorCode_LocationFailed,
                                                    error.localizedDescription)];
    });
}

#pragma mark - Mapping

- (GGLocationModel *)_modelFromPlacemark:(CLPlacemark *)placemark location:(CLLocation *)location {
    GGLocationModel *model = [GGLocationModel new];
    model.latitude = location.coordinate.latitude;
    model.longitude = location.coordinate.longitude;
    model.country = placemark.country;
    model.administrativeArea = placemark.administrativeArea;
    model.locality = placemark.locality;
    model.subLocality = placemark.subLocality;
    model.thoroughfare = placemark.thoroughfare;
    model.subThoroughfare = placemark.subThoroughfare;
    return model;
}

@end
