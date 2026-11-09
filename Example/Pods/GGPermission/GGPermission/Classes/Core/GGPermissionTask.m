//
//  GGPermissionTask.m
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermissionTask.h"
#import "GGPermissionLoggerMacros.h"

@interface GGPermissionTask ()
@property (nonatomic, assign, readwrite) GGPermissionType type;
@property (nonatomic, assign, readwrite) BOOL finished;
@property (nonatomic, strong) NSMutableArray<GGPermissionCallback> *subscribers;
@end

@implementation GGPermissionTask

+ (instancetype)taskWithType:(GGPermissionType)type {
    GGPermissionTask *task = [[GGPermissionTask alloc] init];
    task.type = type;
    task.finished = NO;
    task.subscribers = [NSMutableArray array];
    return task;
}

- (void)addSubscriber:(GGPermissionCallback)callback {
    if (!callback) { return; }
    if (self.finished) {
        GGPermissionLogWarning(@"Task(type=%ld) 已完成，忽略新订阅者", (long)self.type);
        return;
    }
    [self.subscribers addObject:[callback copy]];
}

- (NSUInteger)subscriberCount {
    return self.subscribers.count;
}

- (void)finishWithGranted:(BOOL)granted statusCode:(NSNumber *)statusCode {
    if (self.finished) { return; }
    self.finished = YES;

    NSArray<GGPermissionCallback> *callbacks = self.subscribers.copy;
    [self.subscribers removeAllObjects];

    for (GGPermissionCallback cb in callbacks) {
        cb(granted, statusCode);
    }
}

- (void)cancel {
    if (self.finished) { return; }
    GGPermissionLogInfo(@"Task(type=%ld) 被取消，回调 %lu 个订阅者",
                        (long)self.type, (unsigned long)self.subscribers.count);
    [self finishWithGranted:NO statusCode:@(GGPermissionErrorCancelled)];
}

@end
