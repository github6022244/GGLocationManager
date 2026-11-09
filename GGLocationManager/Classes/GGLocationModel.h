//
//  GGLocationModel.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

/// 统一位置模型。
/// 系统链路（CLGeocoder）与高德链路（AMapLocationReGeocode）均映射到此模型，
/// 保证业务方拿到的字段语义一致。
@interface GGLocationModel : NSObject

/// 纬度
@property (nonatomic, assign) double latitude;
/// 经度
@property (nonatomic, assign) double longitude;

/// 国家
@property (nonatomic, copy, nullable) NSString *country;
/// 省 / 直辖市
@property (nonatomic, copy, nullable) NSString *administrativeArea;
/// 市
@property (nonatomic, copy, nullable) NSString *locality;
/// 区 / 县
@property (nonatomic, copy, nullable) NSString *subLocality;
/// 街道
@property (nonatomic, copy, nullable) NSString *thoroughfare;
/// 门牌号
@property (nonatomic, copy, nullable) NSString *subThoroughfare;

@end

NS_ASSUME_NONNULL_END