#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "GGWindowDefine.h"
#import "GGWindowLogHelper.h"
#import "GGWindowManager.h"
#import "UIWindow+GG.h"

FOUNDATION_EXPORT double GGWindowManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char GGWindowManagerVersionString[];

