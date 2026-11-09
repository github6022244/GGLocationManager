//
//  GGPermission.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGPermissionDefine.h"
#import "GGPermissionLogger.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 系统权限请求统一入口。
 *
 * 线程约定：
 * - 所有公开方法必须在主线程调用；
 * - 所有回调均在主线程执行。
 *
 * 回调约定：
 * - 每个请求保证有且仅有一次回调；
 * - 回调结果可能是授权成功、用户拒绝、系统错误、超时或被取消；
 * - 被取消的请求通过 `statusCode == GGPermissionErrorCancelled` 标识。
 *
 * 并发约定：
 * - 同一 `GGPermissionType` 的多个并发请求会合并，共享一次系统弹窗；
 * - 不同 `GGPermissionType` 的请求串行执行，按调用顺序依次处理；
 * - 调用方无需关心其他模块是否正在请求，自己的回调一定会被触发。
 *
 * 错误约定：
 * - `statusCode >= 0`：系统框架原始状态值，语义由各权限框架定义；
 * - `statusCode < 0`：`GGPermissionError` 内部错误码。
 */
@interface GGPermission : NSObject

/**
 * 全局单例。
 *
 * @return 共享实例，线程安全。
 */
+ (instancetype)shareInstance;

/**
 * 是否在权限被拒绝后自动弹窗引导用户前往系统设置。
 *
 * 默认 `YES`。关闭后，已拒绝/受限的请求会直接回调
 * `(NO, <系统原始状态>)`，不再弹引导窗。
 */
@property (nonatomic, assign) BOOL autoTipEnable;

/**
 * 日志级别，转发到 `GGPermissionLogger.sharedLogger.logLevel`。
 *
 * Debug 构建默认 `GGPermissionLogLevelDebug`，
 * Release 构建默认 `GGPermissionLogLevelWarning`。
 */
@property (nonatomic, assign) GGPermissionLogLevel logLevel;

#pragma mark - 引导文案（权限被拒绝后展示）

/// 相机权限引导文案。
@property (nonatomic, copy) NSString *cameraPushSettingTips;

/// 相册（读写）权限引导文案。
@property (nonatomic, copy) NSString *photoPushSettingTips;

/// 相册（只写）权限引导文案。
@property (nonatomic, copy) NSString *photoAddOnlyPushSettingTips;

/// 定位（使用期间）权限引导文案。
@property (nonatomic, copy) NSString *locationWhenPushSettingTips;

/// 定位（始终）权限引导文案。
@property (nonatomic, copy) NSString *locationAlwaysPushSettingTips;

/// 麦克风权限引导文案。
@property (nonatomic, copy) NSString *microphonePushSettingTips;

/// 通讯录权限引导文案。
@property (nonatomic, copy) NSString *contactsPushSettingTips;

/// 通知权限引导文案。
@property (nonatomic, copy) NSString *notificationPushSettingTips;

/// 日历（完整访问）权限引导文案。
@property (nonatomic, copy) NSString *calendarPushSettingTips;

/// 日历（只写）权限引导文案。
@property (nonatomic, copy) NSString *calendarWriteOnlyPushSettingTips;

/// 蓝牙权限引导文案。
@property (nonatomic, copy) NSString *bluetoothPushSettingTips;

/// 健康（综合）权限引导文案。
@property (nonatomic, copy) NSString *healthPushSettingTips;

/// 健康（步数）权限引导文案。
@property (nonatomic, copy) NSString *healthStepsPushSettingTips;

/// 健康（心率）权限引导文案。
@property (nonatomic, copy) NSString *healthHeartRatePushSettingTips;

/// 健康（睡眠）权限引导文案。
@property (nonatomic, copy) NSString *healthSleepPushSettingTips;

/// 健康（锻炼）权限引导文案。
@property (nonatomic, copy) NSString *healthWorkoutPushSettingTips;

#pragma mark - 请求

/**
 * 请求指定类型的系统权限。
 *
 * 并发与合并行为：
 * - 同一 `type` 已有请求在进行或排队时，本次调用只追加订阅者，
 *   不会取消已有请求，也不会重复触发系统弹窗；
 * - 不同 `type` 的请求按调用顺序串行处理，前一个请求结束后
 *   才开始下一个。
 *
 * 取消行为：
 * - 通过 `-cancelTaskWithType:` 或 `-cancelAllTasks` 取消的请求，
 *   会收到 `(NO, @(GGPermissionErrorCancelled))` 回调；
 * - 已完成的请求不会重复回调。
 *
 * @param type     权限类型，见 `GGPermissionType`。
 * @param callback 结果回调，主线程执行，保证有且仅有一次。
 *                 不得为 `nil`；传入 `nil` 时本方法直接返回，不发起请求。
 *
 * @note 必须在主线程调用；非主线程调用会自动派发到主线程后执行。
 * @warning 回调中不要做耗时操作，避免阻塞主线程。
 */
- (void)permissonType:(GGPermissionType)type withHandle:(GGPermissionCallback)callback;

/**
 * 取消指定类型的权限请求。
 *
 * 包括正在执行的和排队中的请求。被取消的请求会立即收到
 * `(NO, @(GGPermissionErrorCancelled))` 回调；若该类型没有活跃请求，
 * 本方法不做任何事。
 *
 * @param type 要取消的权限类型。
 *
 * @note 必须在主线程调用；非主线程调用会自动派发到主线程后执行。
 */
- (void)cancelTaskWithType:(GGPermissionType)type;

/**
 * 取消所有活跃的权限请求。
 *
 * 包括正在执行的和排队中的请求。所有被取消的请求会立即收到
 * `(NO, @(GGPermissionErrorCancelled))` 回调。
 *
 * @note 必须在主线程调用；非主线程调用会自动派发到主线程后执行。
 * @warning 取消后，排队中的请求不会继续执行；如需重新请求，请再次调用
 *          `-permissonType:withHandle:`。
 */
- (void)cancelAllTasks;

@end

NS_ASSUME_NONNULL_END
