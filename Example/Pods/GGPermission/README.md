# GGPermission

按需引入的 iOS 权限请求工具：按 subspec 拆分，用哪个引哪个，不为没用的权限把系统框架打进包里。

[![Version](https://img.shields.io/cocoapods/v/GGPermission.svg?style=flat)](https://cocoapods.org/pods/GGPermission)
[![License](https://img.shields.io/cocoapods/l/GGPermission.svg?style=flat)](https://cocoapods.org/pods/GGPermission)
[![Platform](https://img.shields.io/cocoapods/p/GGPermission.svg?style=flat)](https://cocoapods.org/pods/GGPermission)

## 特性

- **按需引入**：Core 负责统一入口与引导弹窗，相册、相机、定位等各自独立成 subspec，互不牵连。
- **iOS 13.0+**，兼容 ObjC 工程与 Swift 工程（通过桥接头使用）。
- **统一封装**：状态查询、发起系统请求、被拒绝后引导去设置，都由一个入口完成。
- **不引入无关框架**：只装了相机，就不会把 HealthKit、EventKit 拖进链接列表。

## 环境要求

| 项目 | 要求 |
| --- | --- |
| 系统版本 | iOS 13.0 及以上（`s.ios.deployment_target = '13.0'`） |
| Xcode | 能编译 iOS 13 及以上目标即可（建议 Xcode 14+） |
| CocoaPods | 1.10 及以上 |
| 语言 | 库本身是 **Objective-C**（`source_files` 为 `{h,m}`），ObjC 工程直接用，Swift 工程通过桥接文件使用 |

## 安装

CocoaPods 引入，仓库地址：`https://github.com/github6022244/GGPermission.git`。

### 只装 Core（最小安装）

```ruby
platform :ios, '13.0'
target 'YourApp' do
  use_frameworks!
  pod 'GGPermission'
end
```

`pod 'GGPermission'` 不写 subspec 时，只会安装 `default_subspecs` 里的 `Core`（podspec 中 `s.default_subspecs = 'Core'`）。Core 提供入口类、权限类型枚举、日志与「去设置」引导，但**不含任何具体权限的实现**。

### 全量安装

```ruby
pod 'GGPermission/Core'
pod 'GGPermission/Photo'
pod 'GGPermission/Camera'
pod 'GGPermission/Location'
pod 'GGPermission/Microphone'
pod 'GGPermission/Contacts'
pod 'GGPermission/Notification'
pod 'GGPermission/Calendar'
pod 'GGPermission/Bluetooth'
pod 'GGPermission/Health'
```

### 按需组合安装（推荐）

```ruby
# 只用到相机、相册、定位
pod 'GGPermission/Core'
pod 'GGPermission/Camera'
pod 'GGPermission/Photo'
pod 'GGPermission/Location'
```

每个权限 subspec 都依赖 `GGPermission/Core`，所以 `Core` 写不写都会被自动带上；显式写一行只是让 Podfile 读起来更清楚。改完 Podfile 后执行：

```bash
pod install
```

如果本地索引较旧导致找不到 1.0.1，先跑一次 `pod repo update`。

## subspec 一览

| 模块 | Podfile 写法 | 对应系统框架 | 需要的 Info.plist Key | 典型场景 |
| --- | --- | --- | --- | --- |
| Core（必选） | `pod 'GGPermission/Core'`（默认自带） | UIKit、Foundation | 无 | 统一入口、状态查询、引导弹窗、日志 |
| Photo | `pod 'GGPermission/Photo'` | Photos | `NSPhotoLibraryUsageDescription`；需要写入相册再加 `NSPhotoLibraryAddUsageDescription`（iOS 14+） | 选择本地图片、保存图片到相册 |
| Camera | `pod 'GGPermission/Camera'` | AVFoundation | `NSCameraUsageDescription` | 拍照、扫码、录像 |
| Location | `pod 'GGPermission/Location'` | CoreLocation | `NSLocationWhenInUseUsageDescription`；需要后台定位再加 `NSLocationAlwaysAndWhenInUseUsageDescription` | 附近门店、导航、打卡 |
| Microphone | `pod 'GGPermission/Microphone'` | AVFoundation | `NSMicrophoneUsageDescription` | 录音、语音消息、语音识别 |
| Contacts | `pod 'GGPermission/Contacts'` | Contacts | `NSContactsUsageDescription` | 邀请好友、导入通讯录 |
| Notification | `pod 'GGPermission/Notification'` | UserNotifications | 无需 Info.plist Key，运行时请求即可 | 推送授权、通知开关引导 |
| Calendar | `pod 'GGPermission/Calendar'` | EventKit | `NSCalendarsUsageDescription`（iOS 17+ 新增 `NSCalendarsFullAccessUsageDescription` / `NSCalendarsWriteOnlyAccessUsageDescription`） | 写入日程、读取用户日历 |
| Bluetooth | `pod 'GGPermission/Bluetooth'` | CoreBluetooth | `NSBluetoothAlwaysUsageDescription`（iOS 13+）；如需兼容旧行为可加 `NSBluetoothPeripheralUsageDescription` | 连接手环、外设、近场设备 |
| Health | `pod 'GGPermission/Health'` | HealthKit | `NSHealthShareUsageDescription`、`NSHealthUpdateUsageDescription`；另需在 Target 的 Signing & Capabilities 中开启 HealthKit | 步数、心率、睡眠、锻炼数据 |

## Info.plist 配置

把用到的权限 key 粘到 Target 的 `Info.plist`（或 Xcode 的 Info 标签页）里，描述文案会直接展示给用户，请写清楚用途：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>用于选择图片作为头像</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>用于把生成的图片保存到相册</string>
<key>NSCameraUsageDescription</key>
<string>用于拍摄照片和扫描二维码</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>用于展示附近的门店信息</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>用于在后台持续记录运动轨迹</string>
<key>NSMicrophoneUsageDescription</key>
<string>用于录制语音消息</string>
<key>NSContactsUsageDescription</key>
<string>用于邀请通讯录好友</string>
<key>NSCalendarsUsageDescription</key>
<string>用于写入和读取日程</string>
<key>NSCalendarsFullAccessUsageDescription</key>
<string>用于读取完整日历信息</string>
<key>NSCalendarsWriteOnlyAccessUsageDescription</key>
<string>用于仅向日历写入日程</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>用于连接智能穿戴设备</string>
<key>NSHealthShareUsageDescription</key>
<string>用于读取步数与心率数据</string>
<key>NSHealthUpdateUsageDescription</key>
<string>用于写入锻炼记录</string>
```

## 使用示例

核心入口是单例 `GGPermission`，请求方法统一为 `permissonType:withHandle:`（方法名按源码原样拼写），回调在主线程执行。

```objc
#import <GGPermission/GGPermission.h>

GGPermission *permission = [GGPermission shareInstance];

// 是否在权限未开启且已拒绝时自动弹窗引导去设置，默认 YES
permission.autoTipEnable = YES;
// 未开启时的提示文案可自定义，不设置则用内置默认文案
permission.photoPushSettingTips = @"相册权限未开启，是否前往设置";

[permission permissonType:GGPermissionTypeCamera
                 withHandle:^(BOOL granted, NSNumber *statusCode) {
    if (granted) {
        // 已授权，可以打开相机
    } else {
        // statusCode 为非负数时是系统框架返回的原始状态
        // 为负数时是库内部错误码：-1 未知、-2 服务不可用、-3 超时、-4 找不到顶层控制器
        NSLog(@"未授权，statusCode = %@", statusCode);
    }
}];
```

相册读写与只写分别是 `GGPermissionTypePhoto` 和 `GGPermissionTypePhotoAddOnly`；定位有 `GGPermissionTypeLocationWhen` 与 `GGPermissionTypeLocationAlways`；日历有 `GGPermissionTypeCalendarFullAccess` 与 `GGPermissionTypeCalendarWriteOnly`。健康相关除综合的 `GGPermissionTypeHealth` 外，还有 `GGPermissionTypeHealthSteps`、`GGPermissionTypeHealthHeartRate`、`GGPermissionTypeHealthSleep`、`GGPermissionTypeHealthWorkout`。

Swift 工程通过桥接头使用：

```swift
// 桥接头文件中：#import <GGPermission/GGPermission.h>

let permission = GGPermission.shareInstance()
permission.autoTipEnable = true
permission.permissonType(.camera) { granted, statusCode in
    print("granted: \(granted), status: \(String(describing: statusCode))")
}
```

Swift 侧的枚举与工厂方法名由桥接头按系统规则导入，若与上例略有出入，以实际头文件为准。

细节约束：`permissonType:withHandle:` 必须在主线程调用（内部也会切回主线程）；同一时刻只保留一个进行中的请求，新请求会丢弃旧请求的回调；每次请求默认 15 秒超时。调试时可设置 `permission.logLevel = GGPermissionLogLevelDebug`，或通过 `GGPermissionLogger` 自定义 `logHandler`。

## 权限注意事项

- **Info.plist 缺 key 会直接崩溃**：访问相机、相册、定位等能力前若没有对应的 UsageDescription，App 会被系统终止，且不是可捕获的异常。
- **系统授权弹窗只弹一次**：用户选择「不允许」后，再次请求不会再弹窗，只能引导用户到「设置」里手动打开。`autoTipEnable = YES` 时库会自动弹窗引导，文案可用上面的 `xxxPushSettingTips` 属性覆盖。
- **拒绝不等于不可用**：部分权限（如定位、相册）存在「受限」「仅本次允许」等中间状态，判断时不要只看一个布尔值，需要结合 `statusCode` 做分支。
- **审核要求**：App Store 审核会检查权限描述文案是否说明了真实用途，写「提升用户体验」这类空话容易被拒；也不要在没有对应功能时申请权限。

## 常见问题

**只装了某个权限模块，编译报找不到头文件**
确认 Podfile 里有 `GGPermission/Core`（或至少有一行 `pod 'GGPermission'`），改完后重新 `pod install`，再 `Product > Clean Build Folder`。subspec 的头文件搜索路径是 `pod install` 时写入的，只改 Podfile 不重装不会生效。

**`pod 'GGPermission'` 装了却请求不到权限**
这是预期行为：不写 subspec 只会带 `Core`。请求未引入的类型时，回调会返回 `granted = NO`，`statusCode = -1`（`GGPermissionErrorUnknown`），控制台会打印「未引入 subspec」的日志。按需补上 `pod 'GGPermission/Camera'` 之类即可。

**请求一直不回调**
先看是否在主线程调用；再确认是否有前一个请求未结束（新请求会丢弃旧请求）。超过 15 秒会以 `-3`（超时）回调，可据此排查系统服务状态。

**相册读写和只写都申请了，还是保存失败**
读写（`NSPhotoLibraryUsageDescription`）与只写（`NSPhotoLibraryAddUsageDescription`）是两个独立 key，iOS 14+ 保存图片到相册需要后者。

**通知权限没有 Info.plist Key，为什么还是没弹窗**
通知授权完全由 `UNUserNotificationCenter` 在运行时请求，不需要 plist 声明；如果没弹窗，通常是本次安装已经做过决定，去系统设置里检查。

**健康数据拿不到**
除了两个 UsageDescription，还必须在 Target 的 Signing & Capabilities 中勾选 HealthKit（对应 entitlements 里的 `com.apple.developer.healthkit`），并确认设备可用健康数据。

## License

MIT，见仓库中的 [LICENSE](https://github.com/github6022244/GGPermission/blob/main/LICENSE)。

仓库地址：https://github.com/github6022244/GGPermission.git

作者：github6022244 &lt;1563084860@qq.com&gt;
