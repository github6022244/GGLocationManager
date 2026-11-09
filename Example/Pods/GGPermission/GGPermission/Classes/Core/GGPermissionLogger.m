//
//  GGPermissionLogger.m
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermissionLogger.h"

@implementation GGPermissionLogger

+ (instancetype)sharedLogger {
    static GGPermissionLogger *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GGPermissionLogger alloc] init];
#ifdef DEBUG
        instance.logLevel = GGPermissionLogLevelDebug;
#else
        instance.logLevel = GGPermissionLogLevelWarning;
#endif
    });
    return instance;
}

+ (void)log:(GGPermissionLogLevel)level
       file:(const char *)file
       line:(int)line
     format:(NSString *)format, ... {
    GGPermissionLogger *logger = [self sharedLogger];
    if (level > logger.logLevel) return;

    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *levelStr;
    switch (level) {
        case GGPermissionLogLevelError:   levelStr = @"❌ [Error]";   break;
        case GGPermissionLogLevelWarning: levelStr = @"⚠️ [Warning]"; break;
        case GGPermissionLogLevelInfo:    levelStr = @"ℹ️ [Info]";    break;
        case GGPermissionLogLevelDebug:   levelStr = @"🐛 [Debug]";   break;
        default:                          levelStr = @"[Log]";        break;
    }

    NSString *fileName = [[NSString stringWithUTF8String:file] lastPathComponent];
    NSString *fullMessage = [NSString stringWithFormat:@"%@ [GGPermission] %@ (%@:%d)",
                             levelStr, message, fileName, line];

    if (logger.logHandler) {
        logger.logHandler(level, message, file, line);
    } else {
        NSLog(@"%@", fullMessage);
    }
}

@end
