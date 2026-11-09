//
//  GGWindowDefine.h
//  GGWindowManager
//
//  Created by GG on 2026/9/15.
//

#import <Foundation/Foundation.h>

/// 日志前缀（由使用方定义并赋值）
extern NSString *const GGWindowLogPrefixString;

#ifdef DEBUG
    #define GGWindowLog(fmt, ...) NSLog((@"%@ " fmt), GGWindowLogPrefixString, ##__VA_ARGS__)
#else
    #define GGWindowLog(fmt, ...) do {} while (0)
#endif
