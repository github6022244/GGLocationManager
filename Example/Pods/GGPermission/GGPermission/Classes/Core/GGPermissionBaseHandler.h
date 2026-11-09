//
//  GGPermissionBaseHandler.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGPermissionProtocol.h"
#import "GGPermissionBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

/// 所有权限 Handler 的基类，封装 currentRequest 管理与引导设置
@interface GGPermissionBaseHandler : NSObject <GGPermissionHandlerProtocol>

/// 当前正在进行的 Request（子类通过 startRequestWithType:callback: 使用）
@property (nonatomic, strong, nullable) GGPermissionBaseRequest *currentRequest;

/// 当前请求是否已被取消（由 GGPermission 在 Task 取消时置 YES）
@property (nonatomic, assign) BOOL isCancelled;

#pragma mark - 子类必须重写

- (GGPermissionBaseRequest *)createRequest;
- (nullable NSNumber *)currentSystemStatus;
- (BOOL)isGrantedForStatus:(NSNumber *)statusCode;
- (BOOL)isDeniedOrRestrictedForStatus:(NSNumber *)statusCode;
- (NSString *)guideTipsForType:(GGPermissionType)type;

#pragma mark - 子类可调用

- (void)startRequestWithType:(GGPermissionType)type callback:(GGPermissionCallback)callback;

- (void)guideToSettingWithType:(GGPermissionType)type
                        status:(NSNumber *)status
                      callback:(GGPermissionCallback)callback;

@end

NS_ASSUME_NONNULL_END
