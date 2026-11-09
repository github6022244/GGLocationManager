//
//  GGWindowManager.m
//  GGCommenAppFundation
//
//  Created by GG on 2022/6/1.
//

#import "GGWindowManager.h"
#import "GGWindowDefine.h"
#import "GGWindowLogHelper.h"

@interface GGWindowManager ()

/// 当前活跃的 Scene
@property (nonatomic, weak, readwrite, nullable) UIWindowScene *currentActiveScene;

@end

@implementation GGWindowManager

+ (instancetype)sharedInstance {
    static GGWindowManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GGWindowManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _registerSceneNotifications];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)start {
    GGWindowLog(@"[GGWindowManager] start 被调用，提前初始化并注册 Scene 通知");
    [GGWindowManager sharedInstance];
}

#pragma mark - 通知注册

- (void)_registerSceneNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    // Scene 激活：UISceneDidActivateNotification
    // 官方文档：Scene 变为活跃时发出（对应 sceneDidBecomeActive:）
    [center addObserver:self
               selector:@selector(_handleSceneDidActivate:)
                   name:UISceneDidActivateNotification
                 object:nil];
    
    // Scene 断开：UISceneDidDisconnectNotification
    // 官方文档：Scene 被销毁时发出（对应 sceneDidDisconnect:）
    [center addObserver:self
               selector:@selector(_handleSceneDidDisconnect:)
                   name:UISceneDidDisconnectNotification
                 object:nil];
    
    // Scene 进入后台：UISceneDidEnterBackgroundNotification
    // 用于"活跃 Scene 进入后台"时清空，避免拿到非活跃 Scene
    [center addObserver:self
               selector:@selector(_handleSceneDidEnterBackground:)
                   name:UISceneDidEnterBackgroundNotification
                 object:nil];
    
    GGWindowLog(@"[GGWindowManager] 已注册 Scene 通知监听");
}

#pragma mark - 通知处理

- (void)_handleSceneDidActivate:(NSNotification *)notification {
    UIScene *scene = notification.object;
    GGWindowLog(@"[GGWindowManager] 收到 UISceneDidActivateNotification: %@",
                [GGWindowLogHelper sceneBriefDescription:scene]);
    
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        GGWindowLog(@"⚠️ 忽略非 UIWindowScene: %@", scene);
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    if (_currentActiveScene == windowScene) {
        GGWindowLog(@"activeScene 无变化，跳过更新");
        return;
    }
    
    UIWindowScene *oldScene = _currentActiveScene;
    _currentActiveScene = windowScene;
    
    GGWindowLog(@"✅ activeScene 更新: %@ -> %@",
                [GGWindowLogHelper sceneDescription:oldScene],
                [GGWindowLogHelper sceneDescription:windowScene]);
}

- (void)_handleSceneDidDisconnect:(NSNotification *)notification {
    UIScene *scene = notification.object;
    GGWindowLog(@"[GGWindowManager] 收到 UISceneDidDisconnectNotification: %@",
                [GGWindowLogHelper sceneBriefDescription:scene]);
    
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        GGWindowLog(@"⚠️ 忽略非 UIWindowScene: %@", scene);
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    // 断开的不是记录的活跃 Scene，无需清空
    if (_currentActiveScene != windowScene) {
        GGWindowLog(@"断开的 Scene 不是记录的活跃 Scene，无需清空");
        return;
    }
    
    GGWindowLog(@"✅ activeScene 清空（原: %@）", [GGWindowLogHelper sceneDescription:_currentActiveScene]);
    _currentActiveScene = nil;
}

- (void)_handleSceneDidEnterBackground:(NSNotification *)notification {
    UIScene *scene = notification.object;
    GGWindowLog(@"[GGWindowManager] 收到 UISceneDidEnterBackgroundNotification: %@",
                [GGWindowLogHelper sceneBriefDescription:scene]);
    
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    // 只有"记录的活跃 Scene 进入后台"才清空
    if (_currentActiveScene != windowScene) {
        return;
    }
    
    GGWindowLog(@"✅ activeScene 清空（进入后台，原: %@）",
                [GGWindowLogHelper sceneDescription:_currentActiveScene]);
    _currentActiveScene = nil;
}

@end
