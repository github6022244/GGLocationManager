//
//  GGPermissionBaseRequest.m
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermissionBaseRequest.h"
#import "GGPermissionDefine.h"
#import "GGPermissionLoggerMacros.h"

@interface GGPermissionBaseRequest ()
@property (nonatomic, assign, readwrite) BOOL cancelled;
@property (nonatomic, assign, readwrite) BOOL isCallbackExecuted;
@property (nonatomic, assign) BOOL timeoutTriggered;
@property (nonatomic, strong, nullable) dispatch_block_t timeoutBlock;
@end

@implementation GGPermissionBaseRequest

- (instancetype)init {
    if (self = [super init]) {
        [self prepareForNewRequest];
    }
    return self;
}

- (void)dealloc {
    GGPermissionLogDebug(@"🔴 %@ dealloc", NSStringFromClass([self class]));
    [self onCancel];
    [self cancelTimeoutBlock];
}

#pragma mark - 子类调用：重置状态

- (void)prepareForNewRequest {
    _cancelled = NO;
    _isCallbackExecuted = NO;
    _timeoutTriggered = NO;
    _callback = nil;
}

#pragma mark - 子类必须重写

- (void)startRequest:(GGPermissionType)type callback:(GGPermissionCallback)callback {
    NSAssert(NO, @"子类必须重写 startRequest:callback:");
}

#pragma mark - Public

- (void)cancel {
    if (self.cancelled || self.isCallbackExecuted) { return; }
    self.cancelled = YES;

    [self cancelTimeoutBlock];
    [self onCancel];

    // 取消也要回调，保证调用方状态机不悬挂
    GGPermissionCallback cb = self.callback;
    self.callback = nil;
    self.isCallbackExecuted = YES;
    if (cb) cb(NO, @(GGPermissionErrorCancelled));
}

#pragma mark - 超时

- (NSTimeInterval)timeoutInterval {
    return 15.0;
}

- (void)startTimeoutIfNeeded {
    [self cancelTimeoutBlock];

    __weak typeof(self) ws = self;
    dispatch_block_t block = dispatch_block_create(0, ^{
        __strong typeof(ws) strongSelf = ws;
        if (!strongSelf) return;
        if (strongSelf.cancelled) return;
        if (strongSelf.isCallbackExecuted) return;
        if (strongSelf.timeoutTriggered) return;

        strongSelf.timeoutTriggered = YES;
        GGPermissionLogWarning(@"⚠️ %@ 超时", NSStringFromClass([strongSelf class]));

        NSNumber *statusCode = [strongSelf currentSystemStatus];
        if (!statusCode) {
            statusCode = @(GGPermissionErrorTimeout);
        }
        [strongSelf executeCallback:NO statusCode:statusCode];
    });

    self.timeoutBlock = block;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)([self timeoutInterval] * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   block);
}

- (void)cancelTimeoutBlock {
    if (self.timeoutBlock) {
        dispatch_block_cancel(self.timeoutBlock);
        self.timeoutBlock = nil;
    }
}

#pragma mark - 回调统一出口

- (void)executeCallback:(BOOL)granted statusCode:(NSNumber *)statusCode {
    if (self.cancelled) return;
    if (self.isCallbackExecuted) return;
    self.isCallbackExecuted = YES;
    self.timeoutTriggered = YES;

    [self cancelTimeoutBlock];
    [self onCancel];

    GGPermissionCallback cb = self.callback;
    self.callback = nil;
    if (cb) cb(granted, statusCode);
}

#pragma mark - 子类可重写

- (void)onCancel {}
- (NSNumber *)currentSystemStatus { return nil; }

@end
