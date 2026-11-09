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

#import "GGPermission.h"
#import "GGPermissionBaseHandler.h"
#import "GGPermissionBaseRequest.h"
#import "GGPermissionDefine.h"
#import "GGPermissionLogger.h"
#import "GGPermissionLoggerMacros.h"
#import "GGPermissionProtocol.h"
#import "GGPermissionTask.h"
#import "GGPermissionUIHelper.h"
#import "UIViewController+GGPermission.h"
#import "GGPermissionLocationHandler.h"
#import "GGPermissionLocationHelper.h"
#import "GGPermissionLocationRequest.h"

FOUNDATION_EXPORT double GGPermissionVersionNumber;
FOUNDATION_EXPORT const unsigned char GGPermissionVersionString[];

