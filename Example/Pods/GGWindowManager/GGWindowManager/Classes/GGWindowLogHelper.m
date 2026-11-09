//
//  GGWindowLogHelper.m
//  GGCommenAppFundation
//

#import "GGWindowLogHelper.h"

@implementation GGWindowLogHelper

#pragma mark - Scene

+ (NSString *)sceneDescription:(UIWindowScene *)scene {
    if (!scene) return @"nil";
    
    return [NSString stringWithFormat:
            @"<UIWindowScene: %p, state=%@(%ld), windows=%lu, keyWindow=%@>",
            scene,
            [self activationStateDescription:scene.activationState],
            (long)scene.activationState,
            (unsigned long)scene.windows.count,
            [self windowBrief:[self _topKeyWindowInScene:scene]]];
}

+ (NSString *)sceneBriefDescription:(UIScene *)scene {
    if (!scene) return @"nil";
    
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return [NSString stringWithFormat:@"<非 UIWindowScene: %@, %p>",
                NSStringFromClass([scene class]), scene];
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    return [NSString stringWithFormat:@"<%p, state=%@>",
            windowScene,
            [self activationStateDescription:windowScene.activationState]];
}

#pragma mark - Window

+ (NSString *)windowBrief:(UIWindow *)window {
    if (!window) return @"nil";
    return [NSString stringWithFormat:@"<%p level=%.0f hidden=%@ key=%@>",
            window,
            window.windowLevel,
            window.hidden ? @"YES" : @"NO",
            window.isKeyWindow ? @"YES" : @"NO"];
}

#pragma mark - Enum

+ (NSString *)activationStateDescription:(UISceneActivationState)state {
    switch (state) {
        case UISceneActivationStateUnattached:
            return @"Unattached(未连接)";
        case UISceneActivationStateForegroundActive:
            return @"ForegroundActive(前台活跃)";
        case UISceneActivationStateForegroundInactive:
            return @"ForegroundInactive(前台非活跃)";
        case UISceneActivationStateBackground:
            return @"Background(后台)";
        default:
            return [NSString stringWithFormat:@"Unknown(%ld)", (long)state];
    }
}

#pragma mark - Private

+ (UIWindow *)_topKeyWindowInScene:(UIWindowScene *)scene {
    for (UIWindow *w in scene.windows) {
        if (w.isKeyWindow) {
            return w;
        }
    }
    return nil;
}

@end
