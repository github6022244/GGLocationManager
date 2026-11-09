//
//  GGPermissionDefine.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 权限类型
typedef NS_ENUM(NSInteger, GGPermissionType) {
    GGPermissionTypePhoto = 0,          // 相册 - 读写
    GGPermissionTypePhotoAddOnly,       // 相册 - 只写
    GGPermissionTypeCamera,
    GGPermissionTypeLocationWhen,
    GGPermissionTypeLocationAlways,
    GGPermissionTypeMicrophone,
    GGPermissionTypeContacts,
    GGPermissionTypeNotification,
    GGPermissionTypeCalendarFullAccess, // 日历 - 完整访问
    GGPermissionTypeCalendarWriteOnly,  // 日历 - 只写访问
    GGPermissionTypeBluetooth,
    GGPermissionTypeHealth,           // 健康综合（一次请求多种常用类型）
    GGPermissionTypeHealthSteps,      // 步数（读）
    GGPermissionTypeHealthHeartRate,  // 心率（读）
    GGPermissionTypeHealthSleep,      // 睡眠（读）
    GGPermissionTypeHealthWorkout,    // 锻炼（读）
};

/// 工具类内部错误码（负数为内部错误，非负数为系统框架原始状态）
///
/// 注意：健康权限（GGPermissionTypeHealth*）的 statusCode 不使用系统框架原始状态，
/// 而是采用以下约定：
///   - 0：弹窗流程已完成（granted = YES）。注意：这不代表所有请求的数据类型都被用户同意，
///         HealthKit 不提供同步查询授权状态的 API，需在读取数据时判断是否真正可读。
///   - 1：用户拒绝 / 请求失败（granted = NO）。
///   - 其他：未知状态。
typedef NS_ENUM(NSInteger, GGPermissionError) {
    GGPermissionErrorUnknown = -1,
    GGPermissionErrorServiceDisabled = -2,
    GGPermissionErrorTimeout = -3,
    GGPermissionErrorNoTopViewController = -4,
    /// 请求被取消（新请求覆盖旧请求 / 主动 cancelTask / cancelAll）
    GGPermissionErrorCancelled = -5,
};

/// 统一回调：granted 是否授权成功；statusCode 为系统原始状态或 GGPermissionError。
///
/// 健康权限特例：
/// - granted = YES 且 statusCode = 0：弹窗流程完成，不代表所有数据类型都可读；
/// - granted = NO  且 statusCode = 1：用户拒绝或请求失败；
/// - 具体数据类型是否可读，需在 HealthKit 读取数据时判断。
typedef void(^GGPermissionCallback)(BOOL granted, NSNumber *statusCode);

NS_ASSUME_NONNULL_END
