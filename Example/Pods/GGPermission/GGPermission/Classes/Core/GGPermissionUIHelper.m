//
//  GGPermissionUIHelper.m
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermissionUIHelper.h"
#import "UIViewController+GGPermission.h"
#import "GGPermissionLoggerMacros.h"

static const NSTimeInterval kPermissionSettingBackDelay = 0.3;

@interface GGPermissionUIHelper ()
@property (nonatomic, strong, nullable) id globalObserver;
@property (nonatomic, copy, nullable) dispatch_block_t pendingGoSettingBlock;
+ (instancetype)sharedHelper;
@end

@implementation GGPermissionUIHelper

+ (instancetype)sharedHelper {
    static GGPermissionUIHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GGPermissionUIHelper alloc] init];
    });
    return instance;
}

#pragma mark - 去设置弹框

+ (void)showSettingAlertWithTips:(NSString *)tips
                          cancel:(void(^)(void))cancel
                       goSetting:(void(^)(void))goSetting {
    GGPermissionUIHelper *helper = [self sharedHelper];

    if (!tips.length) {
        GGPermissionLogWarning(@"showSettingAlertWithTips: tips 为空");
        if (cancel) cancel();
        return;
    }

    [helper removeGlobalObserverIfNeeded];
    [helper cancelPendingGoSettingBlock];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示"
                                                                   message:tips
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __block BOOL didGoSetting = NO;

    [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                             style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction * _Nonnull action) {
        GGPermissionLogInfo(@"用户点击：取消");
        [helper removeGlobalObserverIfNeeded];
        [helper cancelPendingGoSettingBlock];
        if (cancel) cancel();
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"去设置"
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * _Nonnull action) {
        GGPermissionLogInfo(@"用户点击：去设置");
        didGoSetting = YES;
        [self openSystemSetting];
    }]];

    if (goSetting) {
        __block BOOL hasTriggered = NO;
        __weak typeof(helper) weakHelper = helper;
        id observer = [[NSNotificationCenter defaultCenter]
                       addObserverForName:UIApplicationDidBecomeActiveNotification
                                   object:nil
                                    queue:[NSOperationQueue mainQueue]
                               usingBlock:^(NSNotification * _Nonnull note) {
            if (hasTriggered) return;
            hasTriggered = YES;

            __strong typeof(weakHelper) strongHelper = weakHelper;
            if (!strongHelper) { return; }

            [strongHelper removeGlobalObserverIfNeeded];
            if (!didGoSetting) {
                GGPermissionLogDebug(@"用户未点'去设置'，忽略前台激活");
                return;
            }

            GGPermissionLogInfo(@"App 回到前台，准备重新读取权限状态");
            dispatch_block_t pending = ^{
                GGPermissionLogDebug(@"延迟 %.1fs 后触发 goSetting 回调", kPermissionSettingBackDelay);
                goSetting();
                strongHelper.pendingGoSettingBlock = nil;
            };
            strongHelper.pendingGoSettingBlock = pending;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                         (int64_t)(kPermissionSettingBackDelay * NSEC_PER_SEC)),
                           dispatch_get_main_queue(),
                           pending);
        }];
        helper.globalObserver = observer;
    }

    UIViewController *top = [UIViewController gg_topViewController];
    if (top) {
        [top presentViewController:alert animated:YES completion:nil];
    } else {
        GGPermissionLogWarning(@"showSettingAlertWithTips: 找不到顶层 VC，直接回调 cancel");
        [helper removeGlobalObserverIfNeeded];
        [helper cancelPendingGoSettingBlock];
        if (cancel) cancel();
    }
}

#pragma mark - 打开系统设置

+ (void)openSystemSetting {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            GGPermissionLogInfo(@"跳转系统设置 %@", success ? @"成功" : @"失败");
        }];
    } else {
        GGPermissionLogWarning(@"无法打开系统设置页");
    }
}

#pragma mark - Private

- (void)removeGlobalObserverIfNeeded {
    if (self.globalObserver) {
        GGPermissionLogDebug(@"移除全局通知监听");
        [[NSNotificationCenter defaultCenter] removeObserver:self.globalObserver];
        self.globalObserver = nil;
    }
}

- (void)cancelPendingGoSettingBlock {
    if (self.pendingGoSettingBlock) {
        GGPermissionLogDebug(@"取消待执行的 goSetting 延时回调");
        self.pendingGoSettingBlock = nil;
    }
}

@end
