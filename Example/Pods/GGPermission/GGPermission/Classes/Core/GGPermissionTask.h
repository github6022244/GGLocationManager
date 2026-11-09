//
//  GGPermissionTask.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGPermissionDefine.h"
#import "GGPermissionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 请求级对象：一个 Task 对应一次权限请求意图。
/// 同 type 的多个调用会合并到同一个 Task，共享一次系统弹窗，结果分发给所有订阅者。
@interface GGPermissionTask : NSObject <GGPermissionTaskProtocol>

@property (nonatomic, assign, readonly) GGPermissionType type;
@property (nonatomic, assign, readonly) BOOL finished;

/// 创建 Task
+ (instancetype)taskWithType:(GGPermissionType)type;

/// 订阅者数量（用于去重判断）
@property (nonatomic, assign, readonly) NSUInteger subscriberCount;

@end

NS_ASSUME_NONNULL_END
