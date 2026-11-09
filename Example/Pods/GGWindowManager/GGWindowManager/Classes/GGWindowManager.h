//
//  GGWindowManager.h
//  GGCommenAppFundation
//
//  Created by GG on 2022/6/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGWindowManager : NSObject

+ (instancetype)sharedInstance;

/// 获取当前用户正在交互的活跃 Scene
@property (nonatomic, weak, readonly, nullable) UIWindowScene *currentActiveScene;

/// 启动窗口管理
/// @note 可选调用。不调用也能工作，只是第一次 getKeyWindow 可能走兜底遍历。
///       建议在 AppDelegate 的 didFinishLaunchingWithOptions 中调用，确保通知尽早注册。
+ (void)start;

@end

NS_ASSUME_NONNULL_END
