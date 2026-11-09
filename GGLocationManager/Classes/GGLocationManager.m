//
//  GGLocationManager.m
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGLocationManager.h"
#import "GGLocationErrors.h"
#import "GGSystemLocationProvider.h"

#pragma mark - GGLocationManager

@interface GGLocationManager () <GGLocationProviderDelegate>
@property (nonatomic, strong) NSMutableArray<GGLocationRequest *> *activeRequests;
@property (nonatomic, copy, nullable) GGLocationProviderFactory providerFactory;
@end

@implementation GGLocationManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static GGLocationManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] init];
    });
    return instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _activeRequests = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Public

- (void)registerProviderFactory:(GGLocationProviderFactory)factory {
    [self _assertMainThread];
    self.providerFactory = factory;
}

- (void)updateSingleLocationWithCoordinateBlock:(GGLocationCoordinateBlock)coordinateBlock
                                       geoBlock:(GGLocationGeoBlock)geoBlock {
    [self updateLocationWithConfig:nil
                      locationType:GGLocationManagerLocationType_Single
                   coordinateBlock:coordinateBlock
                          geoBlock:geoBlock
                      failureBlock:nil];
}

- (void)updateLocationWithConfig:(GGLocationConfigBlock)configBlock
                    locationType:(GGLocationManagerLocationType)locationType
                 coordinateBlock:(GGLocationCoordinateBlock)coordinateBlock
                        geoBlock:(GGLocationGeoBlock)geoBlock
                    failureBlock:(GGLocationFailureBlock)failureBlock {
    [self _assertMainThread];

    GGLocationConfig *config = [GGLocationConfig defaultConfig];
    if (configBlock) { configBlock(config); }

    GGLocationRequest *request = [GGLocationRequest new];
    request.locationType = locationType;
    request.needGeo = (geoBlock != nil);
    request.coordinateBlock = coordinateBlock;
    request.geoBlock = geoBlock;
    request.failureBlock = failureBlock;

    id<GGLocationProvider> provider = [self _makeProvider];
    request.provider = provider;
    provider.delegate = self;
    [provider applyConfig:config];

    [self.activeRequests addObject:request];

    if (locationType == GGLocationManagerLocationType_Single) {
        __weak __typeof(self) weakSelf = self;
        __weak GGLocationRequest *weakRequest = request;
        request.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:config.singleLocationTimeout
                                                                repeats:NO
                                                                  block:^(NSTimer * _Nonnull timer) {
            __strong __typeof(weakSelf) self = weakSelf;
            if (!self || !weakRequest || weakRequest.finished) { return; }
            [self _finishRequest:weakRequest
                       withError:GGLocationMakeError(GGLocationErrorCode_Timeout, @"定位超时")];
        }];
        [provider requestSingleLocationWithNeedGeo:request.needGeo];
    } else {
        [provider startUpdatingLocationWithNeedGeo:request.needGeo];
    }
}

- (void)stopUpdatingLocation {
    [self _assertMainThread];
    for (GGLocationRequest *request in self.activeRequests.copy) {
        [request.provider stopUpdatingLocation];
        [self _finishRequest:request
                   withError:GGLocationMakeError(GGLocationErrorCode_Cancelled, @"用户取消定位")];
    }
}

#pragma mark - GGLocationProviderDelegate

- (void)provider:(id<GGLocationProvider>)provider
 didUpdateLocation:(CLLocation *)location
             geo:(GGLocationModel *)geo
        isFinal:(BOOL)isFinal {
    [self _assertMainThread];

    GGLocationRequest *request = [self _requestForProvider:provider];
    if (!request || request.finished) { return; }

    if (request.coordinateBlock) {
        request.coordinateBlock(location);
    }
    if (geo && request.geoBlock) {
        request.geoBlock(geo);
    }

    if (isFinal || request.locationType == GGLocationManagerLocationType_Single) {
        [self _finishRequest:request withError:nil];
    }
}

- (void)provider:(id<GGLocationProvider>)provider
 didFailWithError:(NSError *)error {
    [self _assertMainThread];

    GGLocationRequest *request = [self _requestForProvider:provider];
    if (!request || request.finished) { return; }
    [self _finishRequest:request withError:error];
}

#pragma mark - Private

/// 只负责“取 Provider”，不做任何 amap/系统 判断。
/// 策略完全由外部注入的 factory 决定；未注入或返回 nil 时回退系统 Provider。
- (id<GGLocationProvider>)_makeProvider {
    if (self.providerFactory) {
        id<GGLocationProvider> provider = self.providerFactory();
        if (provider) { return provider; }
    }
    return [GGSystemLocationProvider new];
}

- (nullable GGLocationRequest *)_requestForProvider:(id<GGLocationProvider>)provider {
    for (GGLocationRequest *request in self.activeRequests) {
        if (request.provider == provider) {
            return request;
        }
    }
    return nil;
}

- (void)_finishRequest:(GGLocationRequest *)request
             withError:(nullable NSError *)error {
    if (request.finished) { return; }
    request.finished = YES;

    [request.timeoutTimer invalidate];
    request.timeoutTimer = nil;
    [request.provider stopUpdatingLocation];

    [self.activeRequests removeObject:request];

    if (error && request.failureBlock) {
        request.failureBlock(error);
    }
}

- (void)_assertMainThread {
    NSAssert(NSThread.isMainThread, @"GGLocationManager 必须在主线程调用");
}

@end
