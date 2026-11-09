//
//  UIViewController+GGPermission.m
//  GGPermission_Example
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "UIViewController+GGPermission.h"
#import "UIWindow+GG.h"

@implementation UIViewController (GGPermission)

+ (nullable UIViewController *)gg_topViewController {
    UIWindow *keyWin = [UIWindow getKeyWindow];
    if (!keyWin || !keyWin.rootViewController) return nil;
    return [self gg_topFrom:keyWin.rootViewController];
}

+ (nullable UIViewController *)gg_topFrom:(nullable UIViewController *)vc {
    if (!vc) return nil;

    // 先处理 presented（覆盖在最上层的优先）
    if (vc.presentedViewController) {
        return [self gg_topFrom:vc.presentedViewController];
    }

    // 再处理容器
    if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)vc;
        return [self gg_topFrom:tab.selectedViewController];
    }

    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return [self gg_topFrom:nav.visibleViewController];
    }

    return vc;
}

@end
