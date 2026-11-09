//
//  GGPermissionLoggerMacros.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#ifndef GGPermissionLoggerMacros_h
#define GGPermissionLoggerMacros_h

#import "GGPermissionLogger.h"

#define GGPermissionLogError(fmt, ...)   [GGPermissionLogger log:GGPermissionLogLevelError   file:__FILE__ line:__LINE__ format:fmt, ##__VA_ARGS__]
#define GGPermissionLogWarning(fmt, ...) [GGPermissionLogger log:GGPermissionLogLevelWarning file:__FILE__ line:__LINE__ format:fmt, ##__VA_ARGS__]
#define GGPermissionLogInfo(fmt, ...)    [GGPermissionLogger log:GGPermissionLogLevelInfo    file:__FILE__ line:__LINE__ format:fmt, ##__VA_ARGS__]
#define GGPermissionLogDebug(fmt, ...)   [GGPermissionLogger log:GGPermissionLogLevelDebug   file:__FILE__ line:__LINE__ format:fmt, ##__VA_ARGS__]

#endif /* GGPermissionLoggerMacros_h */
