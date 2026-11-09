//
//  GGPermissionProtocol.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGPermissionDefine.h"

NS_ASSUME_NONNULL_BEGIN

/// 权限处理器协议（负责状态判断、分发、弹窗引导）
@protocol GGPermissionHandlerProtocol <NSObject>
@required
- (void)requestPermission:(GGPermissionType)type callback:(GGPermissionCallback)callback;

@optional
+ (BOOL)isAuthorized;

/// 取消当前正在进行的请求（由 GGPermission 在 Task 被取消时调用）。
/// Handler 应在此方法中取消 currentRequest、清理平台资源，
/// 并保证后续不会再对已取消的 Task 回调。
- (void)cancelCurrentRequest;
@end

/// 权限请求器协议（只负责调用系统 API 发起一次请求）
@protocol GGPermissionRequestProtocol <NSObject>
@required
- (void)startRequest:(GGPermissionType)type callback:(GGPermissionCallback)callback;
@end

/// Task 协议：一个 Task 代表“一次权限请求意图”，可包含多个订阅者
@protocol GGPermissionTaskProtocol <NSObject>
@required
/// 添加订阅者（同 type 合并）
- (void)addSubscriber:(GGPermissionCallback)callback;
/// 完成（所有订阅者统一回调）
- (void)finishWithGranted:(BOOL)granted statusCode:(NSNumber *)statusCode;
/// 取消（所有订阅者统一回调 Cancelled）
- (void)cancel;
@end

NS_ASSUME_NONNULL_END
