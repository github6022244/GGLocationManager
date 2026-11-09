//
//  UIWindow+GG.m
//  GGCommenAppFundation
//
//  Created by GG on 2022/6/1.
//  Modified on 2024/5/20 (最低版本 iOS13，多窗口适配)
//

#import "UIWindow+GG.h"
#import "GGWindowManager.h"
#import "GGWindowDefine.h"
#import "GGWindowLogHelper.h"

@implementation UIWindow (GG)

#pragma mark - Public Methods

+ (UIWindow *)getKeyWindow {
    return [self getKeyWindow:YES];
}

+ (UIWindow *)getKeyWindow:(BOOL)onlyMain {
    if (onlyMain) {
        return [self getKeyWindowWithMaxLevel:UIWindowLevelNormal];
    } else {
        return [self getKeyWindowWithMaxLevel:CGFLOAT_MAX];
    }
}


+ (UIWindow *)getKeyWindowWithMaxLevel:(CGFloat)maxLevel {
    UIApplication *app = [UIApplication sharedApplication];
    GGWindowLog(@"getKeyWindowWithMaxLevel 开始查找 maxLevel=%f", maxLevel);
    
    // 1. 优先 GGWindowManager 记录活跃Scene
    UIWindowScene *activeScene = [GGWindowManager sharedInstance].currentActiveScene;
    if (activeScene) {
        GGWindowLog(@"① 记录的活跃 Scene: %@", [GGWindowLogHelper sceneDescription:activeScene]);
        if (activeScene.activationState != UISceneActivationStateBackground) {
            UIWindow *window = [self _findTopKeyWindowInScene:activeScene maxLevel:maxLevel];
            if (window) {
                GGWindowLog(@"✅ 命中①，返回: %@", [GGWindowLogHelper windowBrief:window]);
                return window;
            }
            GGWindowLog(@"⚠️ ① 未命中，Scene内无满足maxLevel的keyWindow");
        } else {
            GGWindowLog(@"⚠️ ① 记录Scene处于Background，跳过");
        }
    } else {
        GGWindowLog(@"⚠️ ① 无记录活跃Scene");
    }
    
    // 2. 兜底遍历所有Scene
    NSSet<UIScene *> *connectedScenes = app.connectedScenes;
    GGWindowLog(@"② 开始Scene遍历 connectedScenes.count = %lu", (unsigned long)connectedScenes.count);
    if (connectedScenes.count) {
        UIWindow *foundWindow = [self _findKeyWindowInScenes:connectedScenes onlyForegroundActive:YES maxLevel:maxLevel];
        if (foundWindow) {
            GGWindowLog(@"✅ 命中②.1 ForegroundActive 返回: %@", [GGWindowLogHelper windowBrief:foundWindow]);
            return foundWindow;
        }
        GGWindowLog(@"⚠️ ②.1 未命中");
        
        foundWindow = [self _findKeyWindowInScenes:connectedScenes onlyForegroundActive:NO maxLevel:maxLevel];
        if (foundWindow) {
            GGWindowLog(@"✅ 命中②.2 全部Scene 返回: %@", [GGWindowLogHelper windowBrief:foundWindow]);
            return foundWindow;
        }
        GGWindowLog(@"⚠️ ②.2 未命中");
    } else {
        GGWindowLog(@"⚠️ ② connectedScenes为空");
    }
    
    // 3. AppDelegate 兜底
    UIWindow *appDelWindow = [self _keyWindowFromAppDelegateWithMaxLevel:maxLevel];
    if (appDelWindow) {
        GGWindowLog(@"✅ 命中③ AppDelegate.window 返回: %@", [GGWindowLogHelper windowBrief:appDelWindow]);
        return appDelWindow;
    }
    GGWindowLog(@"⚠️ ③ AppDelegate兜底未命中");
    
    GGWindowLog(@"❌ 未找到满足maxLevel的keyWindow");
    return nil;
}

#pragma mark - Private new helper（配套新增私有方法）
+ (UIWindow *)_findTopKeyWindowInScene:(UIWindowScene *)windowScene maxLevel:(CGFloat)maxLevel {
    if (!windowScene) return nil;
    UIWindow *topWindow = nil;
    for (UIWindow *window in windowScene.windows) {
        if (!window.isKeyWindow) continue;
        // ✅ 核心判断：窗口层级不能超过传入maxLevel
        if (window.windowLevel > maxLevel) {
            GGWindowLog(@"   窗口层级超出maxLevel，跳过: %@ level=%f", [GGWindowLogHelper windowBrief:window], window.windowLevel);
            continue;
        }
        // 在符合条件窗口中，选windowLevel最大的
        if (!topWindow || window.windowLevel > topWindow.windowLevel) {
            topWindow = window;
        }
    }
    return topWindow;
}

+ (UIWindow *)_findKeyWindowInScenes:(NSSet<UIScene *> *)scenes onlyForegroundActive:(BOOL)onlyForegroundActive maxLevel:(CGFloat)maxLevel {
    for (UIScene *scene in scenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (onlyForegroundActive && windowScene.activationState != UISceneActivationStateForegroundActive) {
            continue;
        }
        UIWindow *topWindow = [self _findTopKeyWindowInScene:windowScene maxLevel:maxLevel];
        if (topWindow) return topWindow;
    }
    return nil;
}

+ (UIWindow *)_keyWindowFromAppDelegateWithMaxLevel:(CGFloat)maxLevel {
    id<UIApplicationDelegate> delegate = [UIApplication sharedApplication].delegate;
    if (![delegate respondsToSelector:@selector(window)]) {
        GGWindowLog(@"   AppDelegate未响应window");
        return nil;
    }
    id rawWindow = [delegate performSelector:@selector(window)];
    if (![rawWindow isKindOfClass:[UIWindow class]]) {
        GGWindowLog(@"   AppDelegate.window非UIWindow");
        return nil;
    }
    UIWindow *appDelWindow = (UIWindow *)rawWindow;
    if (!appDelWindow.isKeyWindow) {
        GGWindowLog(@"   AppDelegate.window不是keyWindow");
        return nil;
    }
    if (appDelWindow.windowLevel > maxLevel) {
        GGWindowLog(@"   AppDelegate.window层级超出maxLevel");
        return nil;
    }
    return appDelWindow;
}


@end
