#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GGPermissionUIHelper : NSObject

/// 弹窗引导去系统设置
/// @param tips 提示文案
/// @param cancel 用户点"取消"时的回调
/// @param goSetting 用户点"去设置"后，App 回到前台时的回调（可选）
+ (void)showSettingAlertWithTips:(NSString *)tips
                          cancel:(void(^_Nullable)(void))cancel
                       goSetting:(void(^_Nullable)(void))goSetting;

/// 打开系统设置页
+ (void)openSystemSetting;

@end

NS_ASSUME_NONNULL_END
