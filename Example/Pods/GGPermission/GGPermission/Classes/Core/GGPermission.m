//
//  GGPermission.m
//  GGPermission
//
//  Created by GG on 2026/9/18.
//  Copyright © 2026 github6022244. All rights reserved.
//

#import "GGPermission.h"
#import "GGPermissionProtocol.h"
#import "GGPermissionTask.h"
#import "GGPermissionLoggerMacros.h"

@interface GGPermission ()
/// type -> handler
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, id<GGPermissionHandlerProtocol>> *handlerMap;
/// 正在执行的 Task（同一时刻最多一个）
@property (nonatomic, strong, nullable) GGPermissionTask *executingTask;
/// 排队中的 Task（按 type 去重）
@property (nonatomic, strong) NSMutableArray<GGPermissionTask *> *pendingTasks;
/// 串行队列，保证 Task 状态变更线程安全（入口已保证主线程，队列主要用于语义清晰）
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@end

@implementation GGPermission

static GGPermission *_instance;

#pragma mark - Singleton

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
    });
    return _instance;
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    return [self shareInstance];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[self class] shareInstance];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[self class] shareInstance];
}

- (instancetype)init {
    if (self = [super init]) {
        _autoTipEnable = YES;
        _taskQueue = dispatch_queue_create("com.ggpermission.task.queue", DISPATCH_QUEUE_SERIAL);

        _cameraPushSettingTips = @"相机权限未开启，是否前往设置";
        _photoPushSettingTips = @"相册权限未开启，是否前往设置";
        _photoAddOnlyPushSettingTips = @"相册写入权限未开启，是否前往设置";
        _locationWhenPushSettingTips = @"位置权限未开启，是否前往设置";
        _locationAlwaysPushSettingTips = @"始终允许位置权限未开启，是否前往设置";
        _microphonePushSettingTips = @"麦克风权限未开启，是否前往设置";
        _contactsPushSettingTips = @"通讯录权限未开启，是否前往设置";
        _notificationPushSettingTips = @"通知权限未开启，是否前往设置";
        _calendarPushSettingTips = @"日历权限未开启，是否前往设置";
        _calendarWriteOnlyPushSettingTips = @"日历写入权限未开启，是否前往设置";
        _bluetoothPushSettingTips = @"蓝牙权限未开启，是否前往设置";
        _healthPushSettingTips = @"健康权限未开启，是否前往设置";
        _healthStepsPushSettingTips = @"步数权限未开启，是否前往设置";
        _healthHeartRatePushSettingTips = @"心率权限未开启，是否前往设置";
        _healthSleepPushSettingTips = @"睡眠权限未开启，是否前往设置";
        _healthWorkoutPushSettingTips = @"锻炼权限未开启，是否前往设置";

        _handlerMap = [NSMutableDictionary dictionary];
        _pendingTasks = [NSMutableArray array];
        [self registerHandlers];
    }
    return self;
}

#pragma mark - 注册 Handler

- (void)registerHandlers {
    NSDictionary<NSString *, NSArray<NSNumber *> *> *map = @{
        @"GGPermissionPhotoHandler":        @[@(GGPermissionTypePhoto),
                                              @(GGPermissionTypePhotoAddOnly)],
        @"GGPermissionCameraHandler":       @[@(GGPermissionTypeCamera)],
        @"GGPermissionLocationHandler":     @[@(GGPermissionTypeLocationWhen),
                                              @(GGPermissionTypeLocationAlways)],
        @"GGPermissionMicrophoneHandler":   @[@(GGPermissionTypeMicrophone)],
        @"GGPermissionContactsHandler":     @[@(GGPermissionTypeContacts)],
        @"GGPermissionNotificationHandler": @[@(GGPermissionTypeNotification)],
        @"GGPermissionCalendarHandler":     @[@(GGPermissionTypeCalendarFullAccess),
                                              @(GGPermissionTypeCalendarWriteOnly)],
        @"GGPermissionBluetoothHandler":    @[@(GGPermissionTypeBluetooth)],
        @"GGPermissionHealthHandler":       @[@(GGPermissionTypeHealth),
                                              @(GGPermissionTypeHealthSteps),
                                              @(GGPermissionTypeHealthHeartRate),
                                              @(GGPermissionTypeHealthSleep),
                                              @(GGPermissionTypeHealthWorkout)],
    };

    [map enumerateKeysAndObjectsUsingBlock:^(NSString *clsName,
                                             NSArray<NSNumber *> *types,
                                             BOOL *stop) {
        Class cls = NSClassFromString(clsName);
        if (!cls) {
            GGPermissionLogInfo(@"%@ 类不存在，跳过注册", clsName);
            return;
        }
        for (NSNumber *t in types) {
            id handler = [[cls alloc] init];
            if (![handler conformsToProtocol:@protocol(GGPermissionHandlerProtocol)]) {
                GGPermissionLogInfo(@"%@ 对象未遵循 Handler 协议，跳过注册", clsName);
                continue;
            }
            self.handlerMap[t] = handler;
        }
    }];
}

#pragma mark - Public

- (void)permissonType:(GGPermissionType)type withHandle:(GGPermissionCallback)callback {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self permissonType:type withHandle:callback];
        });
        return;
    }

    if (!callback) {
        GGPermissionLogWarning(@"permissonType:withHandle: callback 为 nil，直接返回");
        return;
    }

    // 1. 已有同 type Task 在排队中 → 追加订阅者
    GGPermissionTask *pendingSame = [self _pendingTaskForType:type];
    if (pendingSame) {
        GGPermissionLogInfo(@"同 type 排队中的 Task 已存在，追加订阅者（type=%ld）", (long)type);
        [pendingSame addSubscriber:callback];
        return;
    }

    // 2. 正在执行的 Task 是同 type → 追加订阅者
    if (self.executingTask && self.executingTask.type == type) {
        GGPermissionLogInfo(@"同 type 执行中的 Task 已存在，追加订阅者（type=%ld）", (long)type);
        [self.executingTask addSubscriber:callback];
        return;
    }

    // 3. 创建新 Task
    GGPermissionTask *task = [GGPermissionTask taskWithType:type];
    [task addSubscriber:callback];

    // 4. 没有正在执行的 Task → 立即执行；否则入队
    if (!self.executingTask) {
        [self _startTask:task];
    } else {
        GGPermissionLogInfo(@"不同 type 排队：type=%ld（当前执行 type=%ld）",
                            (long)type, (long)self.executingTask.type);
        [self.pendingTasks addObject:task];
    }
}

- (void)cancelTaskWithType:(GGPermissionType)type {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cancelTaskWithType:type];
        });
        return;
    }

    // 取消执行中的
    if (self.executingTask && self.executingTask.type == type) {
        GGPermissionLogInfo(@"取消执行中的 Task(type=%ld)", (long)type);

        // 先通知 Handler 取消当前 Request，避免 Request 继续回调
        id<GGPermissionHandlerProtocol> handler = self.handlerMap[@(type)];
        if ([handler respondsToSelector:@selector(cancelCurrentRequest)]) {
            [handler cancelCurrentRequest];
        }

        [self.executingTask cancel];
        self.executingTask = nil;
        [self _startNextPendingTask];
        return;
    }

    // 取消排队中的
    NSMutableArray<GGPermissionTask *> *toRemove = [NSMutableArray array];
    for (GGPermissionTask *task in self.pendingTasks) {
        if (task.type == type) {
            [toRemove addObject:task];
        }
    }
    for (GGPermissionTask *task in toRemove) {
        [task cancel];
        [self.pendingTasks removeObject:task];
    }
}

- (void)cancelAllTasks {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cancelAllTasks];
        });
        return;
    }

    if (self.executingTask) {
        // 先通知 Handler 取消当前 Request
        id<GGPermissionHandlerProtocol> handler = self.handlerMap[@(self.executingTask.type)];
        if ([handler respondsToSelector:@selector(cancelCurrentRequest)]) {
            [handler cancelCurrentRequest];
        }

        [self.executingTask cancel];
        self.executingTask = nil;
    }
    for (GGPermissionTask *task in self.pendingTasks.copy) {
        [task cancel];
    }
    [self.pendingTasks removeAllObjects];
}

#pragma mark - Task 调度

- (nullable GGPermissionTask *)_pendingTaskForType:(GGPermissionType)type {
    for (GGPermissionTask *task in self.pendingTasks) {
        if (task.type == type) {
            return task;
        }
    }
    return nil;
}

- (void)_startTask:(GGPermissionTask *)task {
    self.executingTask = task;

    id<GGPermissionHandlerProtocol> handler = self.handlerMap[@(task.type)];
    if (!handler) {
        GGPermissionLogError(@"未引入 %ld 对应的 subspec，请在 Podfile 中添加", (long)task.type);
        [self _finishTask:task granted:NO statusCode:@(GGPermissionErrorUnknown)];
        return;
    }

    __weak typeof(self) ws = self;
    __weak GGPermissionTask *weakTask = task;
    [handler requestPermission:task.type callback:^(BOOL granted, NSNumber *statusCode) {
        __strong typeof(ws) strongSelf = ws;
        __strong GGPermissionTask *strongTask = weakTask;
        if (!strongSelf || !strongTask) { return; }

        // 忽略非当前 Task 的迟到回调
        if (strongSelf.executingTask != strongTask) {
            GGPermissionLogDebug(@"迟到回调被忽略（task type=%ld）", (long)strongTask.type);
            return;
        }
        [strongSelf _finishTask:strongTask granted:granted statusCode:statusCode];
    }];
}

- (void)_finishTask:(GGPermissionTask *)task
            granted:(BOOL)granted
         statusCode:(NSNumber *)statusCode {
    if (self.executingTask != task) { return; }
    self.executingTask = nil;

    [task finishWithGranted:granted statusCode:statusCode];
    [self _startNextPendingTask];
}

- (void)_startNextPendingTask {
    if (self.executingTask) { return; }
    if (self.pendingTasks.count == 0) { return; }

    GGPermissionTask *next = self.pendingTasks.firstObject;
    [self.pendingTasks removeObjectAtIndex:0];
    GGPermissionLogInfo(@"从队列取出 Task(type=%ld) 开始执行", (long)next.type);
    [self _startTask:next];
}

#pragma mark - set/get

- (void)setLogLevel:(GGPermissionLogLevel)logLevel {
    [GGPermissionLogger sharedLogger].logLevel = logLevel;
}

- (GGPermissionLogLevel)logLevel {
    return [GGPermissionLogger sharedLogger].logLevel;
}

@end
