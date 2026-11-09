//
//  UIViewController+GGPermission.h
//  GGPermission_Example
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (GGPermission)

/// 获取当前最顶层的 ViewController（自动穿透 presented / tabBar / nav）
+ (nullable UIViewController *)gg_topViewController;

@end

NS_ASSUME_NONNULL_END
