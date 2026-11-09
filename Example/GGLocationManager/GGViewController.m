//
//  GGViewController.m
//  GGPermission_Example
//
//  Created by GG on 2026/11/05.
//  Copyright © 2026 GG. All rights reserved.
//

#import "GGViewController.h"
#import "GGLocationManager.h"
#import "GGLocationErrors.h"

#if __has_include(<AMapLocationKit/AMapLocationKit.h>)
#import "GGAmapLocationProvider.h"
#define GG_DEMO_HAS_AMAP 1
#else
#define GG_DEMO_HAS_AMAP 0
#endif

#pragma mark - ============================================================
#pragma mark - GGTestItem
#pragma mark - ============================================================

typedef NS_ENUM(NSInteger, GGTestItemAction) {
    GGTestItemAction_SingleCoordinate = 0,   // 单次定位，仅坐标
    GGTestItemAction_SingleWithGeo,          // 单次定位，坐标 + geo
    GGTestItemAction_SingleCustomConfig,     // 单次定位，自定义 config
    GGTestItemAction_SingleFailureOnly,      // 单次定位，只关心失败
    GGTestItemAction_SingleLegacyAPI,        // 旧接口兼容
    GGTestItemAction_KeepStart,              // 持续定位启动
    GGTestItemAction_KeepStop,               // 持续定位停止
    GGTestItemAction_ConsecutiveRequests,    // 连续请求两个（验证隔离）
    GGTestItemAction_CancelWhileLocating,    // 定位中主动取消
    GGTestItemAction_InjectSystemProvider,   // 注入系统 Provider
    GGTestItemAction_InjectAmapProvider,     // 注入高德 Provider（条件编译）
    GGTestItemAction_InjectRuntimeToggle,    // 运行时按开关切换
    GGTestItemAction_ClearLog,               // 清空日志
};

#pragma mark - 功能名（日志 source）

static NSString * const kFeatureDefaultProvider      = @"初始化-默认Provider";
static NSString * const kFeatureSingleCoordinate     = @"单次定位-仅坐标";
static NSString * const kFeatureSingleWithGeo        = @"单次定位-坐标+geo";
static NSString * const kFeatureSingleCustomConfig   = @"单次定位-自定义config";
static NSString * const kFeatureSingleFailureOnly    = @"单次定位-只关心失败";
static NSString * const kFeatureSingleLegacyAPI      = @"旧接口兼容";
static NSString * const kFeatureKeepStart            = @"持续定位-启动";
static NSString * const kFeatureKeepStop             = @"持续定位-停止";
static NSString * const kFeatureConsecutiveRequests  = @"连续请求-隔离";
static NSString * const kFeatureCancelWhileLocating  = @"定位中取消";
static NSString * const kFeatureInjectSystemProvider = @"Provider-注入系统";
static NSString * const kFeatureInjectAmapProvider   = @"Provider-注入高德";
static NSString * const kFeatureInjectRuntimeToggle  = @"Provider-运行时切换";
static NSString * const kFeatureClearLog             = @"日志-清空";

@interface GGTestItem : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) GGTestItemAction action;
+ (instancetype)itemWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                       action:(GGTestItemAction)action;
@end

@implementation GGTestItem

+ (instancetype)itemWithTitle:(NSString *)title
                     subtitle:(NSString *)subtitle
                       action:(GGTestItemAction)action {
    GGTestItem *item = [[GGTestItem alloc] init];
    item.title = title;
    item.subtitle = subtitle;
    item.action = action;
    return item;
}

@end

#pragma mark - ============================================================
#pragma mark - GGLogCell
#pragma mark - ============================================================

@interface GGLogCell : UITableViewCell
@property (nonatomic, strong) UILabel *logLabel;
- (void)configureWithText:(NSString *)text isError:(BOOL)isError;
@end

@implementation GGLogCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _logLabel = [[UILabel alloc] init];
        _logLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _logLabel.numberOfLines = 0;
        _logLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
        [self.contentView addSubview:_logLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_logLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor],
            [_logLabel.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor],
            [_logLabel.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor],
            [_logLabel.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor],
        ]];
    }
    return self;
}

- (void)configureWithText:(NSString *)text isError:(BOOL)isError {
    self.logLabel.text = text;
    self.logLabel.textColor = isError ? [UIColor systemRedColor] : [UIColor labelColor];
}

@end

#pragma mark - ============================================================
#pragma mark - GGViewController
#pragma mark - ============================================================

@interface GGViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSArray<GGTestItem *> *> *sections;
@property (nonatomic, strong) NSArray<NSString *> *sectionTitles;

/// 测试日志（按时间倒序展示，最新在最上）
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *logs;
/// 日志时间格式化（复用，避免每次创建）
@property (nonatomic, strong) NSDateFormatter *logDateFormatter;

/// 持续定位是否已启动（用于 UI 状态提示）
@property (nonatomic, assign) BOOL keepLocating;
/// 运行时开关：是否走高德（模拟业务条件）
@property (nonatomic, assign) BOOL runtimeUseAmap;

@end

@implementation GGViewController

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"GGLocationManager 测试";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.logs = [NSMutableArray array];

    [self setupData];
    [self setupTableView];
    [self setupDefaultProvider];
}

#pragma mark - 默认 Provider

- (void)setupDefaultProvider {
    // 默认注入系统 Provider（也可以不注入，Manager 会回退系统 Provider）
    [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
        return nil; // nil = 回退系统 Provider
    }];
    [self appendLog:@"✅ 默认 Provider：系统定位（工厂返回 nil，回退系统 Provider）"
            isError:NO
             source:kFeatureDefaultProvider];
}

#pragma mark - 数据

- (void)setupData {
    self.sectionTitles = @[
        @"单次定位",
        @"持续定位",
        @"并发 / 取消",
        @"Provider 注入",
        @"日志",
    ];

    self.sections = @[
        @[
            [GGTestItem itemWithTitle:@"单次定位（仅坐标）"
                             subtitle:@"Single + coordinateBlock"
                               action:GGTestItemAction_SingleCoordinate],
            [GGTestItem itemWithTitle:@"单次定位（坐标 + geo）"
                             subtitle:@"Single + coordinateBlock + geoBlock"
                               action:GGTestItemAction_SingleWithGeo],
            [GGTestItem itemWithTitle:@"单次定位（自定义 config）"
                             subtitle:@"精度 100m / 超时 10s"
                               action:GGTestItemAction_SingleCustomConfig],
            [GGTestItem itemWithTitle:@"单次定位（只关心失败）"
                             subtitle:@"只传 failureBlock，坐标/geo 为 nil"
                               action:GGTestItemAction_SingleFailureOnly],
            [GGTestItem itemWithTitle:@"旧接口兼容"
                             subtitle:@"updateSingleLocationWithCoordinateBlock:geoBlock:"
                               action:GGTestItemAction_SingleLegacyAPI],
        ],
        @[
            [GGTestItem itemWithTitle:@"启动持续定位"
                             subtitle:@"Keep + coordinateBlock + geoBlock"
                               action:GGTestItemAction_KeepStart],
            [GGTestItem itemWithTitle:@"停止持续定位"
                             subtitle:@"stopUpdatingLocation（会回调 Cancelled）"
                               action:GGTestItemAction_KeepStop],
        ],
        @[
            [GGTestItem itemWithTitle:@"连续请求两个（验证隔离）"
                             subtitle:@"先单次定位，0.2s 后再次单次定位"
                               action:GGTestItemAction_ConsecutiveRequests],
            [GGTestItem itemWithTitle:@"定位中主动取消"
                             subtitle:@"发起单次定位后立即 stopUpdatingLocation"
                               action:GGTestItemAction_CancelWhileLocating],
        ],
        @[
            [GGTestItem itemWithTitle:@"注入系统 Provider"
                             subtitle:@"工厂返回 nil，回退系统定位"
                               action:GGTestItemAction_InjectSystemProvider],
            [GGTestItem itemWithTitle:@"注入高德 Provider"
                             subtitle:@"条件编译：未引入 AMap 时提示不可用"
                               action:GGTestItemAction_InjectAmapProvider],
            [GGTestItem itemWithTitle:@"运行时按开关切换"
                             subtitle:@"每次点击切换 系统/高德，再发起单次定位"
                               action:GGTestItemAction_InjectRuntimeToggle],
        ],
        @[
            [GGTestItem itemWithTitle:@"清空日志"
                             subtitle:@"清除下方所有日志"
                               action:GGTestItemAction_ClearLog],
        ],
    ];
}

#pragma mark - UI

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                  style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedSectionFooterHeight = 0;
    [self.tableView registerClass:[GGLogCell class] forCellReuseIdentifier:@"GGLogCell"];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

#pragma mark - Lazy

- (NSDateFormatter *)logDateFormatter {
    if (!_logDateFormatter) {
        _logDateFormatter = [[NSDateFormatter alloc] init];
        _logDateFormatter.dateFormat = @"HH:mm:ss.SSS";
    }
    return _logDateFormatter;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 日志区：第 0 行是“清空日志”按钮，第 1 行起是日志
    if (section == self.sections.count - 1) {
        return 1 + self.logs.count;
    }
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger logSection = self.sections.count - 1;

    // 日志区：第 0 行是“清空日志”按钮，第 1 行起是日志内容
    if (indexPath.section == logSection && indexPath.row >= 1) {
        GGLogCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GGLogCell" forIndexPath:indexPath];
        NSDictionary<NSString *, id> *log = self.logs[indexPath.row - 1];
        [cell configureWithText:log[@"text"] isError:[log[@"isError"] boolValue]];
        return cell;
    }

    // 普通项（含日志区第 0 行的“清空日志”按钮）
    static NSString *cellID = @"GGTestCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:cellID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.numberOfLines = 0;
        cell.detailTextLabel.numberOfLines = 0;
    }
    GGTestItem *item = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subtitle;
    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSInteger logSection = self.sections.count - 1;

    // 日志区：只有第 0 行（清空日志）可点，第 1 行起是日志内容
    if (indexPath.section == logSection) {
        if (indexPath.row == 0) {
            [self testClearLog];
        }
        return;
    }

    GGTestItem *item = self.sections[indexPath.section][indexPath.row];
    [self handleAction:item.action];
}

#pragma mark - Actions

- (void)handleAction:(GGTestItemAction)action {
    switch (action) {
        case GGTestItemAction_SingleCoordinate:
            [self testSingleCoordinate];
            break;
        case GGTestItemAction_SingleWithGeo:
            [self testSingleWithGeo];
            break;
        case GGTestItemAction_SingleCustomConfig:
            [self testSingleCustomConfig];
            break;
        case GGTestItemAction_SingleFailureOnly:
            [self testSingleFailureOnly];
            break;
        case GGTestItemAction_SingleLegacyAPI:
            [self testLegacyAPI];
            break;
        case GGTestItemAction_KeepStart:
            [self testKeepStart];
            break;
        case GGTestItemAction_KeepStop:
            [self testKeepStop];
            break;
        case GGTestItemAction_ConsecutiveRequests:
            [self testConsecutiveRequests];
            break;
        case GGTestItemAction_CancelWhileLocating:
            [self testCancelWhileLocating];
            break;
        case GGTestItemAction_InjectSystemProvider:
            [self testInjectSystemProvider];
            break;
        case GGTestItemAction_InjectAmapProvider:
            [self testInjectAmapProvider];
            break;
        case GGTestItemAction_InjectRuntimeToggle:
            [self testInjectRuntimeToggle];
            break;
        case GGTestItemAction_ClearLog:
            [self testClearLog];
            break;
    }
}

#pragma mark - 测试：单次定位（仅坐标）

- (void)testSingleCoordinate {
    [self appendLog:@"▶️ 开始：单次定位（仅坐标）" isError:NO source:kFeatureSingleCoordinate];
    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:nil
                    locationType:GGLocationManagerLocationType_Single
                 coordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"✅ 坐标：lat=%.6f lon=%.6f\n精度=%.1fm 时间=%@",
                         location.coordinate.latitude,
                         location.coordinate.longitude,
                         location.horizontalAccuracy,
                         location.timestamp]
                isError:NO
                 source:kFeatureSingleCoordinate];
    } geoBlock:nil
                failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[self logTextForError:error]
                isError:YES
                 source:kFeatureSingleCoordinate];
    }];
}

#pragma mark - 测试：单次定位（坐标 + geo）

- (void)testSingleWithGeo {
    [self appendLog:@"▶️ 开始：单次定位（坐标 + geo）" isError:NO source:kFeatureSingleWithGeo];
    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:nil
                    locationType:GGLocationManagerLocationType_Single
                 coordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"✅ 坐标：lat=%.6f lon=%.6f",
                         location.coordinate.latitude,
                         location.coordinate.longitude]
                isError:NO
                 source:kFeatureSingleWithGeo];
    } geoBlock:^(GGLocationModel *geoLocation) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"✅ Geo：%@ %@ %@ %@\n街道：%@ %@",
                         geoLocation.country ?: @"(nil)",
                         geoLocation.administrativeArea ?: @"(nil)",
                         geoLocation.locality ?: @"(nil)",
                         geoLocation.subLocality ?: @"(nil)",
                         geoLocation.thoroughfare ?: @"(nil)",
                         geoLocation.subThoroughfare ?: @"(nil)"]
                isError:NO
                 source:kFeatureSingleWithGeo];
    } failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[self logTextForError:error]
                isError:YES
                 source:kFeatureSingleWithGeo];
    }];
}

#pragma mark - 测试：单次定位（自定义 config）

- (void)testSingleCustomConfig {
    [self appendLog:@"▶️ 开始：单次定位（自定义 config：精度 100m / 超时 10s）"
            isError:NO
             source:kFeatureSingleCustomConfig];
    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:^(GGLocationConfig *config) {
        config.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        config.distanceFilter = kCLDistanceFilterNone;
        config.singleLocationTimeout = 10.0;
    } locationType:GGLocationManagerLocationType_Single
                 coordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"✅ 坐标：lat=%.6f lon=%.6f 精度=%.1fm",
                         location.coordinate.latitude,
                         location.coordinate.longitude,
                         location.horizontalAccuracy]
                isError:NO
                 source:kFeatureSingleCustomConfig];
    } geoBlock:nil
                failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[self logTextForError:error]
                isError:YES
                 source:kFeatureSingleCustomConfig];
    }];
}

#pragma mark - 测试：单次定位（只关心失败）

- (void)testSingleFailureOnly {
    [self appendLog:@"▶️ 开始：单次定位（只关心失败）"
            isError:NO
             source:kFeatureSingleFailureOnly];
    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:nil
                    locationType:GGLocationManagerLocationType_Single
                 coordinateBlock:nil
                        geoBlock:nil
                    failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[self logTextForError:error]
                isError:YES
                 source:kFeatureSingleFailureOnly];
    }];
    [self appendLog:@"ℹ️ 若定位成功，本用例不会产生任何日志（预期行为）"
            isError:NO
             source:kFeatureSingleFailureOnly];
}

#pragma mark - 测试：旧接口兼容

- (void)testLegacyAPI {
    [self appendLog:@"▶️ 开始：旧接口 updateSingleLocationWithCoordinateBlock:geoBlock:"
            isError:NO
             source:kFeatureSingleLegacyAPI];
    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateSingleLocationWithCoordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"✅ 旧接口坐标：lat=%.6f lon=%.6f",
                         location.coordinate.latitude,
                         location.coordinate.longitude]
                isError:NO
                 source:kFeatureSingleLegacyAPI];
    } geoBlock:nil];
    [self appendLog:@"ℹ️ 旧接口失败时静默（不回调、不弹 UI）"
            isError:NO
             source:kFeatureSingleLegacyAPI];
}

#pragma mark - 测试：持续定位启动

- (void)testKeepStart {
    if (self.keepLocating) {
        [self appendLog:@"⚠️ 持续定位已在运行，先停止再启动"
                isError:YES
                 source:kFeatureKeepStart];
        return;
    }
    self.keepLocating = YES;
    [self appendLog:@"▶️ 开始：持续定位（distanceFilter=10m）"
            isError:NO
             source:kFeatureKeepStart];

    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:^(GGLocationConfig *config) {
        config.distanceFilter = 10.0;
    } locationType:GGLocationManagerLocationType_Keep
                 coordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"📍 持续坐标：lat=%.6f lon=%.6f 精度=%.1fm",
                         location.coordinate.latitude,
                         location.coordinate.longitude,
                         location.horizontalAccuracy]
                isError:NO
                 source:kFeatureKeepStart];
    } geoBlock:^(GGLocationModel *geoLocation) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:
                         @"📍 持续 Geo：%@ %@ %@",
                         geoLocation.country ?: @"(nil)",
                         geoLocation.administrativeArea ?: @"(nil)",
                         geoLocation.locality ?: @"(nil)"]
                isError:NO
                 source:kFeatureKeepStart];
    } failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[self logTextForError:error]
                isError:YES
                 source:kFeatureKeepStart];
    }];
}

#pragma mark - 测试：持续定位停止

- (void)testKeepStop {
    if (!self.keepLocating) {
        [self appendLog:@"⚠️ 当前没有持续定位在运行"
                isError:YES
                 source:kFeatureKeepStop];
        return;
    }
    self.keepLocating = NO;
    [self appendLog:@"⏹ 停止持续定位（会回调 Cancelled）"
            isError:NO
             source:kFeatureKeepStop];
    [[GGLocationManager sharedInstance] stopUpdatingLocation];
}

#pragma mark - 测试：连续请求两个

- (void)testConsecutiveRequests {
    [self appendLog:@"▶️ 开始：连续请求（先 A，0.2s 后 B）"
            isError:NO
             source:kFeatureConsecutiveRequests];
    [self appendLog:@"ℹ️ 预期：A、B 各自独立回调，互不覆盖（请求级隔离）"
            isError:NO
             source:kFeatureConsecutiveRequests];

    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:nil
                    locationType:GGLocationManagerLocationType_Single
                 coordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:@"✅ A 坐标：lat=%.6f lon=%.6f",
                         location.coordinate.latitude, location.coordinate.longitude]
                isError:NO
                 source:kFeatureConsecutiveRequests];
    } geoBlock:nil
                failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:@"❌ A 失败：%@", [self logTextForError:error]]
                isError:YES
                 source:kFeatureConsecutiveRequests];
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(ws) self = ws;
        if (!self) { return; }

        [[GGLocationManager sharedInstance]
            updateLocationWithConfig:nil
                        locationType:GGLocationManagerLocationType_Single
                     coordinateBlock:^(CLLocation *location) {
            __strong typeof(ws) self = ws;
            if (!self) { return; }
            [self appendLog:[NSString stringWithFormat:@"✅ B 坐标：lat=%.6f lon=%.6f",
                             location.coordinate.latitude, location.coordinate.longitude]
                    isError:NO
                     source:kFeatureConsecutiveRequests];
        } geoBlock:nil
                    failureBlock:^(NSError *error) {
            __strong typeof(ws) self = ws;
            if (!self) { return; }
            [self appendLog:[NSString stringWithFormat:@"❌ B 失败：%@", [self logTextForError:error]]
                    isError:YES
                     source:kFeatureConsecutiveRequests];
        }];
    });
}

#pragma mark - 测试：定位中主动取消

- (void)testCancelWhileLocating {
    [self appendLog:@"▶️ 开始：发起单次定位后立即取消（预期回调 Cancelled）"
            isError:NO
             source:kFeatureCancelWhileLocating];

    __weak typeof(self) ws = self;
    [[GGLocationManager sharedInstance]
        updateLocationWithConfig:nil
                    locationType:GGLocationManagerLocationType_Single
                 coordinateBlock:^(CLLocation *location) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[NSString stringWithFormat:@"✅ 取消前仍拿到坐标：lat=%.6f lon=%.6f",
                         location.coordinate.latitude, location.coordinate.longitude]
                isError:NO
                 source:kFeatureCancelWhileLocating];
    } geoBlock:nil
                failureBlock:^(NSError *error) {
        __strong typeof(ws) self = ws;
        if (!self) { return; }
        [self appendLog:[self logTextForError:error]
                isError:YES
                 source:kFeatureCancelWhileLocating];
    }];

    [[GGLocationManager sharedInstance] stopUpdatingLocation];
}

#pragma mark - 测试：注入系统 Provider

- (void)testInjectSystemProvider {
    [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
        return nil;
    }];
    [self appendLog:@"✅ 已注入：系统 Provider（工厂返回 nil）"
            isError:NO
             source:kFeatureInjectSystemProvider];
    [self testSingleCoordinate];
}

#pragma mark - 测试：注入高德 Provider

- (void)testInjectAmapProvider {
#if GG_DEMO_HAS_AMAP
    [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
        return [GGAmapLocationProvider new];
    }];
    [self appendLog:@"✅ 已注入：高德 Provider"
            isError:NO
             source:kFeatureInjectAmapProvider];
    [self testSingleCoordinate];
#else
    [self appendLog:@"⚠️ 未引入 AMapLocationKit，无法注入高德 Provider"
            isError:YES
             source:kFeatureInjectAmapProvider];
#endif
}

#pragma mark - 测试：运行时按开关切换

- (void)testInjectRuntimeToggle {
    self.runtimeUseAmap = !self.runtimeUseAmap;

#if GG_DEMO_HAS_AMAP
    BOOL useAmap = self.runtimeUseAmap;
    [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
        if (useAmap) {
            return [GGAmapLocationProvider new];
        }
        return nil;
    }];
    [self appendLog:[NSString stringWithFormat:@"✅ 运行时切换：%@",
                     useAmap ? @"高德 Provider" : @"系统 Provider（工厂返回 nil）"]
            isError:NO
             source:kFeatureInjectRuntimeToggle];
#else
    self.runtimeUseAmap = NO;
    [[GGLocationManager sharedInstance] registerProviderFactory:^id<GGLocationProvider> _Nullable{
        return nil;
    }];
    [self appendLog:@"⚠️ 未引入 AMapLocationKit，运行时切换仅能使用系统 Provider"
            isError:YES
             source:kFeatureInjectRuntimeToggle];
#endif

    [self testSingleCoordinate];
}

#pragma mark - 测试：清空日志

- (void)testClearLog {
    [self.logs removeAllObjects];
    NSLog(@"[GGLocation][INFO ][%@][%@] 日志已清空",
          [self.logDateFormatter stringFromDate:[NSDate date]],
          kFeatureClearLog);
    NSInteger section = self.sections.count - 1;
    [UIView performWithoutAnimation:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                      withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - 日志

- (void)appendLog:(NSString *)text isError:(BOOL)isError source:(NSString *)source {
    NSString *time = [self.logDateFormatter stringFromDate:[NSDate date]];
    NSString *feature = source.length > 0 ? source : @"-";
    NSString *line = [NSString stringWithFormat:@"[%@][%@] %@", time, feature, text];

    // 新日志插到最前（展示时最新在最上）
    [self.logs insertObject:@{@"text": line, @"isError": @(isError)} atIndex:0];

    // 控制台日志：级别 + 时间 + 功能 + 内容，方便按功能过滤
    if (isError) {
        NSLog(@"[GGLocation][ERROR][%@][%@] %@", time, feature, text);
    } else {
        NSLog(@"[GGLocation][INFO ][%@][%@] %@", time, feature, text);
    }

    // 无动画刷新日志区，避免 insertRows 动画与行数不一致导致的崩溃/闪烁
    NSInteger section = self.sections.count - 1;
    [UIView performWithoutAnimation:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
                      withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (NSString *)logTextForError:(NSError *)error {
    NSString *codeDesc = [self descForErrorCode:error.code];
    return [NSString stringWithFormat:@"❌ %@（code=%ld）\n%@\n%@",
            codeDesc, (long)error.code,
            error.localizedDescription,
            error.domain];
}

- (NSString *)descForErrorCode:(GGLocationErrorCode)code {
    switch (code) {
        case GGLocationErrorCode_Unknown:                   return @"未知错误";
        case GGLocationErrorCode_PermissionDenied:          return @"权限被拒绝";
        case GGLocationErrorCode_Timeout:                   return @"定位超时";
        case GGLocationErrorCode_LocationFailed:            return @"定位失败";
        case GGLocationErrorCode_GeocodeFailed:             return @"逆地理编码失败";
        case GGLocationErrorCode_Cancelled:                 return @"已取消";
        case GGLocationErrorCode_PermissionRestricted:      return @"权限受限";
        case GGLocationErrorCode_PermissionServiceDisabled: return @"系统定位服务被禁用";
        default:                                            return @"其他错误";
    }
}

@end
