//
//  GGLocationErrors.h
//  GeneralPurposeAppKit
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGLocationDefines.h"

NS_ASSUME_NONNULL_BEGIN

/// 构造 GGLocationErrorDomain 下的 NSError
/// @param code 错误码
/// @param description 错误描述（可为 nil）
FOUNDATION_EXPORT NSError * GGLocationMakeError(GGLocationErrorCode code,
                                                NSString * _Nullable description);

/// 把 GGPermission 的 (granted, statusCode) 映射为 GGLocationErrorDomain 下的 NSError
/// @param granted GGPermission 回调的授权结果
/// @param statusCode GGPermission 回调的原始状态码（可能是 GGPermissionError* 负数，也可能是系统原始状态）
/// @return granted == YES 时返回 nil；否则返回对应 NSError
FOUNDATION_EXPORT NSError * _Nullable GGLocationMakePermissionError(BOOL granted,
                                                                    NSNumber * _Nullable statusCode);

NS_ASSUME_NONNULL_END
