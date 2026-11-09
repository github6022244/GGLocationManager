//
//  GGPermissionBaseRequest.h
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GGPermissionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface GGPermissionBaseRequest : NSObject <GGPermissionRequestProtocol>

@property (nonatomic, copy, nullable) GGPermissionCallback callback;
@property (nonatomic, assign, readonly) BOOL cancelled;
@property (nonatomic, assign, readonly) BOOL isCallbackExecuted;

- (void)prepareForNewRequest;
- (void)cancel;
- (void)startRequest:(GGPermissionType)type callback:(GGPermissionCallback)callback;
- (void)executeCallback:(BOOL)granted statusCode:(NSNumber *)statusCode;
- (void)onCancel;
- (nullable NSNumber *)currentSystemStatus;
- (NSTimeInterval)timeoutInterval;
- (void)startTimeoutIfNeeded;

@end

NS_ASSUME_NONNULL_END
