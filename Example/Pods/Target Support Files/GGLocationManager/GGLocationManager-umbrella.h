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

#import "GGAmapLocationProvider.h"
#import "GGLocationConfig.h"
#import "GGLocationDefines.h"
#import "GGLocationErrors.h"
#import "GGLocationManager.h"
#import "GGLocationModel.h"
#import "GGLocationProvider.h"
#import "GGLocationRequest.h"
#import "GGSystemLocationProvider.h"

FOUNDATION_EXPORT double GGLocationManagerVersionNumber;
FOUNDATION_EXPORT const unsigned char GGLocationManagerVersionString[];

