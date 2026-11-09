//
//  GGLocationManager.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGLocationDefines.h"
#import "GGLocationConfig.h"
#import "GGLocationModel.h"
#import "GGLocationRequest.h"
#import "GGLocationProvider.h"

NS_ASSUME_NONNULL_BEGIN

/// Provider 工厂：返回 nil 时 Manager 回退到系统 Provider
typedef id<GGLocationProvider> _Nullable (^GGLocationProviderFactory)(void);

/// 定位管理器（单例）。
///
/// 职责：
/// - 编排请求、管理活跃请求列表；
/// - 统一错误回调（成功 / 权限拒绝 / 超时 / 定位失败 / 取消）；
/// - 主线程规约（所有 public 方法与回调均在主线程）。
///
/// 设计原则：
/// - 不直接依赖权限库 / 定位 SDK / 业务用户信息；
/// - 使用哪种 Provider（系统 / 高德 / 其他）由 App 层通过 `registerProviderFactory:` 注入决定；
/// - Manager 内部不做 "amap 优先" 之类的策略判断，未注入或工厂返回 nil 时回退系统 Provider。
@interface GGLocationManager : NSObject

+ (instancetype)sharedInstance;

/// 注入 Provider 工厂（App 启动时调用一次即可）。
///
/// - 不注入时默认使用 `GGSystemLocationProvider`；
/// - 是否使用高德/百度等第三方 SDK，由 App 层决定，Manager 内部不做判断；
/// - 工厂在每次发起定位请求时被调用，返回值作为该请求的 Provider；
/// - 返回 nil 时该请求回退系统 Provider；
/// - 必须在主线程调用。
///
/// @param factory 返回 Provider 实例的工厂 block，可为 nil（等价于回退系统 Provider）
- (void)registerProviderFactory:(nullable GGLocationProviderFactory)factory;

/// 单次定位（兼容旧接口）。
///
/// - 只回调坐标，不回调 geo；
/// - 失败时静默（不弹 UI、不回调 failure），仅用于不需要错误处理的旧调用方；
/// - 新代码请使用 `updateLocationWithConfig:locationType:coordinateBlock:geoBlock:failureBlock:`。
- (void)updateSingleLocationWithCoordinateBlock:(nullable GGLocationCoordinateBlock)coordinateBlock
                                       geoBlock:(nullable GGLocationGeoBlock)geoBlock;

/// 统一入口（推荐）。
///
/// 所有路径（成功 / 权限拒绝 / 超时 / 定位失败 / 取消）都会走 failureBlock。
///
/// @param configBlock     配置回调，可修改 desiredAccuracy / distanceFilter / singleLocationTimeout；可为 nil
/// @param locationType    Single 单次 / Keep 持续
/// @param coordinateBlock 坐标回调（成功时必回调）
/// @param geoBlock        逆地理编码回调（仅当非 nil 时才会请求 geo；成功且拿到 geo 时回调）
/// @param failureBlock    失败回调（所有失败路径统一走这里）；可为 nil
- (void)updateLocationWithConfig:(nullable GGLocationConfigBlock)configBlock
                    locationType:(GGLocationManagerLocationType)locationType
                 coordinateBlock:(nullable GGLocationCoordinateBlock)coordinateBlock
                        geoBlock:(nullable GGLocationGeoBlock)geoBlock
                    failureBlock:(nullable GGLocationFailureBlock)failureBlock;

/// 停止持续定位，并取消所有活跃请求（每个请求都会回调 `GGLocationErrorCode_Cancelled`）。
/// 必须在主线程调用。
- (void)stopUpdatingLocation;

@end

NS_ASSUME_NONNULL_END

#pragma mark - ============================================================
#pragma mark - 使用示例（Usage Examples）
#pragma mark - ============================================================
//
// 【1. 线程约定】
//   - 所有 public 方法必须在主线程调用（内部有 NSAssert 校验）；
//   - coordinateBlock / geoBlock / failureBlock 均在主线程回调；
//   - 业务方在 block 内可直接更新 UI，无需再 dispatch 到主线程。
//
// ---------------------------------------------------------------------
//
// 【2. App 启动时注入 Provider（决定用系统还是高德）】
//
//   在 AppDelegate 或依赖注入入口，隐私协议已同意后调用一次即可：
//
//   #import "GGLocationManager.h"
//
//   // 方案 A：固定使用系统定位（不注入即可，或显式注入系统 Provider）
//   // 无需任何代码，默认就是系统定位。
//
//   // 方案 B：固定使用高德定位
//   #if __has_include(<AMapLocationKit/AMapLocationKit.h>)
//   #import "GGAmapLocationProvider.h"
//
//   [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
//       return [GGAmapLocationProvider new];
//   }];
//   #endif
//
//   // 方案 C：运行时按业务条件切换（推荐，Manager 完全无感知）
//   #if __has_include(<AMapLocationKit/AMapLocationKit.h>)
//   #import "GGAmapLocationProvider.h"
//   #import "CXGUserInfoManager.h"
//
//   [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
//       if ([CXGUserInfoManager userAgreePrivacyPolicy]) {
//           return [GGAmapLocationProvider new];
//       }
//       return nil; // 回退系统定位
//   }];
//   #endif
//
//   注意：
//   - 是否使用高德由 App 层决定，GGLocationManager 内部不做 "amap 优先" 判断；
//   - 工厂在每次发起定位时被调用，可返回不同 Provider（如按场景切换）；
//   - 工厂返回 nil 时该请求回退系统 Provider。
//
// ---------------------------------------------------------------------
//
// 【3. 单次定位（只要坐标，不要 geo）】
//
//   [[GGLocationManager sharedInstance]
//       updateLocationWithConfig:nil
//                   locationType:GGLocationManagerLocationType_Single
//                coordinateBlock:^(CLLocation *location) {
//       NSLog(@"坐标：%f, %f", location.coordinate.latitude, location.coordinate.longitude);
//   } geoBlock:nil
//               failureBlock:^(NSError *error) {
//       if (error.code == GGLocationErrorCode_Cancelled) { return; } // 忽略主动取消
//       NSLog(@"定位失败：%@", error.localizedDescription);
//       // 权限拒绝：GGLocationErrorCode_PermissionDenied
//       // 超时：GGLocationErrorCode_Timeout
//       // 定位失败：GGLocationErrorCode_LocationFailed
//   }];
//
// ---------------------------------------------------------------------
//
// 【4. 单次定位（要坐标 + 逆地理编码）】
//
//   [[GGLocationManager sharedInstance]
//       updateLocationWithConfig:^(GGLocationConfig *config) {
//           config.desiredAccuracy = kCLLocationAccuracyHundredMeters; // 可选：降低精度省电
//           config.singleLocationTimeout = 15.0;                       // 可选：超时兜底
//       }
//                   locationType:GGLocationManagerLocationType_Single
//                coordinateBlock:^(CLLocation *location) {
//       // 先回调坐标
//   } geoBlock:^(GGLocationModel *geoLocation) {
//       // 再回调 geo（同一请求内，坐标回调之后）
//       NSLog(@"%@ %@ %@ %@", geoLocation.country, geoLocation.administrativeArea,
//             geoLocation.locality, geoLocation.subLocality);
//   } failureBlock:^(NSError *error) {
//       // 统一失败处理
//   }];
//
//   注意：
//   - 只有 geoBlock 非 nil 时才会请求逆地理编码；
//   - 若系统链路 geocode 失败且是单次定位，会走 failureBlock（GGLocationErrorCode_GeocodeFailed）；
//   - 高德链路单次定位的 geo 与坐标在同一次回调里给出。
//
// ---------------------------------------------------------------------
//
// 【5. 持续定位】
//
//   [[GGLocationManager sharedInstance]
//       updateLocationWithConfig:^(GGLocationConfig *config) {
//           config.distanceFilter = 10.0; // 每移动 10m 回调一次
//       }
//                   locationType:GGLocationManagerLocationType_Keep
//                coordinateBlock:^(CLLocation *location) {
//       // 持续回调
//   } geoBlock:nil
//               failureBlock:^(NSError *error) {
//       // 持续定位中的失败（如权限被中途收回）
//   }];
//
//   // 不需要时停止（会取消所有活跃请求，并回调 Cancelled）
//   [[GGLocationManager sharedInstance] stopUpdatingLocation];
//
//   注意：
//   - 持续定位不会自动超时（timeoutTimer 只对 Single 生效）；
//   - 同一 Provider 实例上的持续定位，重复调用 startUpdatingLocation 不会重复启动；
//   - stopUpdatingLocation 会取消所有活跃请求（包括单次和持续）。
//
// ---------------------------------------------------------------------
//
// 【6. 错误码说明（GGLocationErrorCode）】
//
//   GGLocationErrorCode_Unknown                  -1    未知 / 未引入对应 subspec
//   GGLocationErrorCode_PermissionDenied        1001  权限被拒绝
//   GGLocationErrorCode_Timeout                 1002  超时（Manager 兜底 或 GGPermission 超时）
//   GGLocationErrorCode_LocationFailed          1003  系统/高德定位失败
//   GGLocationErrorCode_GeocodeFailed           1004  逆地理编码失败（单次定位且需要 geo 时）
//   GGLocationErrorCode_Cancelled               1005  主动取消（stopUpdatingLocation）
//   GGLocationErrorCode_PermissionRestricted    1006  权限受限（家长控制、MDM 等）
//   GGLocationErrorCode_PermissionServiceDisabled 1007 系统级服务被禁用（定位总开关关闭）
//
//   典型处理：
//   - Cancelled：直接 return，不提示用户；
//   - PermissionDenied / PermissionRestricted：引导去设置页；
//   - PermissionServiceDisabled：提示打开系统定位总开关；
//   - Timeout / LocationFailed：提示重试；
//   - GeocodeFailed：坐标已拿到，geo 失败可降级为只显示坐标。
//
// ---------------------------------------------------------------------
//
// 【7. 旧接口兼容】
//
//   旧代码可继续使用：
//
//   [[GGLocationManager sharedInstance]
//       updateSingleLocationWithCoordinateBlock:^(CLLocation *location) {
//       // ...
//   } geoBlock:nil];
//
//   行为等价于 Single + 无 failureBlock（失败静默）。
//   新代码请统一使用带 failureBlock 的统一入口。
//
// ---------------------------------------------------------------------
//
// 【8. 与 GGPermission 的关系】
//
//   - 权限请求由各 Provider 内部调用 GGPermission 完成，Manager 不感知权限库；
//   - GGPermission 内部 15s 超时，Manager 单次定位兜底超时默认 20s（大于 15s，避免双重超时）；
//   - 收到 GGPermissionErrorTimeout 时会映射为 GGLocationErrorCode_Timeout 透传给 failureBlock。
//
// ---------------------------------------------------------------------
//
// 【9. 与高德 SDK 的关系】
//
//   - GGLocationManager 不 import 高德 SDK；
//   - 高德 Provider（GGAmapLocationProvider）由 App 层注入，内部使用 AMapLocationManager；
//   - 高德 Provider 会先用 GGPermission 校验定位权限，已授权直接启动，未确定才触发系统弹窗；
//   - 高德 `doRequireLocationAuth:` 回调不再调用 `requestAlwaysAuthorization`，避免与 GGPermission 弹窗竞争。
//
#pragma mark - ============================================================
