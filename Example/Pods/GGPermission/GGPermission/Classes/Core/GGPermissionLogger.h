//
//  GGPermissionLogger.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 日志级别
typedef NS_ENUM(NSInteger, GGPermissionLogLevel) {
    GGPermissionLogLevelNone    = 0,   // 不输出
    GGPermissionLogLevelError   = 1,   // 错误
    GGPermissionLogLevelWarning = 2,   // 警告
    GGPermissionLogLevelInfo    = 3,   // 信息
    GGPermissionLogLevelDebug   = 4,   // 调试
};

/// 自定义日志处理 block
typedef void(^GGPermissionLogHandler)(GGPermissionLogLevel level,
                                      NSString *message,
                                      const char *file,
                                      int line);

/// 日志系统（线程安全）
@interface GGPermissionLogger : NSObject

/// 日志级别，默认 Debug（Debug 构建）/ Warning（Release 构建）
@property (nonatomic, assign) GGPermissionLogLevel logLevel;

/// 自定义日志处理，不设置则用 NSLog
@property (nonatomic, copy, nullable) GGPermissionLogHandler logHandler;

+ (instancetype)sharedLogger;

/// 内部使用
+ (void)log:(GGPermissionLogLevel)level
       file:(const char *)file
       line:(int)line
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(4, 5);

@end

NS_ASSUME_NONNULL_END
