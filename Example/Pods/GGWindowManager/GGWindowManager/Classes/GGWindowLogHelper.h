//
//  GGWindowLogHelper.h
//  GGCommenAppFundation
//
//  窗口/Scene 日志格式化辅助工具（仅用于日志输出，不参与业务逻辑）
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGWindowLogHelper : NSObject

#pragma mark - Scene

/// Scene 详细描述：<UIWindowScene: 0x..., state=ForegroundActive(前台活跃)(0), windows=2, keyWindow=...>
+ (NSString *)sceneDescription:(nullable UIWindowScene *)scene;

/// Scene 简要描述：<0x..., state=ForegroundActive(前台活跃)>
/// 可接受任意 UIScene，非 UIWindowScene 会标注类型
+ (NSString *)sceneBriefDescription:(nullable UIScene *)scene;

#pragma mark - Window

/// Window 简要描述：<0x..., level=0, hidden=NO, key=YES>
+ (NSString *)windowBrief:(nullable UIWindow *)window;

#pragma mark - Enum

/// UISceneActivationState 的中英文描述
+ (NSString *)activationStateDescription:(UISceneActivationState)state;

@end

NS_ASSUME_NONNULL_END
