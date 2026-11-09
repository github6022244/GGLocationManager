//
//  UIWindow+GG.h
//  GGCommenAppFundation
//
//  Created by GG on 2022/6/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIWindow (GG)

/// 获取当前 Key Window（仅返回 windowLevel ≤ UIWindowLevelNormal 的业务窗口，推荐）
+ (nullable UIWindow *)getKeyWindow;

/// 获取当前 Key Window
/// @param onlyMain YES 仅返回 windowLevel ≤ UIWindowLevelNormal 的业务窗口（推荐）；
///                  NO  返回任意层级的 keyWindow（含弹窗、键盘等高层窗口）
+ (nullable UIWindow *)getKeyWindow:(BOOL)onlyMain;

/**
 查找keyWindow，可指定最大允许windowLevel
 @param maxLevel 最大允许windowLevel，只选取 window.windowLevel <= maxLevel 的窗口
 @return 符合条件，且层级最高的keyWindow
 */
+ (UIWindow *)getKeyWindowWithMaxLevel:(CGFloat)maxLevel;

@end

NS_ASSUME_NONNULL_END
