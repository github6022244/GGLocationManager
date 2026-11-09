#
# Be sure to run `pod lib lint GGLocationManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GGLocationManager'
  s.version          = '0.1.1'
  s.summary      = '可插拔 iOS 定位管理组件，支持单次/持续定位，可选逆地理编码'

  s.description  = <<-DESC
  轻量、基于提供者模式的 iOS 定位管理组件。

  特性：
  - 统一入口，支持单次定位与持续定位；所有公开接口与回调均在主线程执行。
  - 通过 GGLocationProvider 协议实现可插拔定位源：可通过工厂方法按需注入系统 CoreLocation 或高德定位，未注入时自动降级使用系统定位。
  - 可选逆地理编码，坐标回调后同步返回地址信息。
  - 统一错误类型，覆盖权限拒绝、权限受限、定位服务关闭、超时、定位失败、逆地理编码失败、主动取消等场景。
  - 可配置定位精度、距离过滤阈值、单次定位超时时间。
  - 不直接依赖任何第三方定位 SDK；权限校验逻辑交由 GGPermission/Location 处理。
                         DESC


  s.homepage         = 'https://github.com/github6022244/GGLocationManager.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'github6022244' => '1563084860@qq.com' }
  s.source           = { :git => 'https://github.com/github6022244/GGLocationManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'GGLocationManager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'GGLocationManager' => ['GGLocationManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'GGPermission/Location', '~> 1.0.2'
end
