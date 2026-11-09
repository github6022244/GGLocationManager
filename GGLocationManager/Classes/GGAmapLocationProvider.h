//
//  GGAmapLocationProvider.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGLocationProvider.h"

NS_ASSUME_NONNULL_BEGIN

#if __has_include(<AMapLocationKit/AMapLocationKit.h>)
/// 高德定位 Provider
@interface GGAmapLocationProvider : NSObject <GGLocationProvider>
@end
#endif

NS_ASSUME_NONNULL_END