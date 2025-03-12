#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint vwo_fme_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'vwo_fme_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'FME is a server-side solution where you integrate VWO SDK in your server codebase and can run feature tests, rollouts, personalization and experimentation campaigns.'
  s.description      = <<-DESC
FME is a server-side solution where you integrate VWO's SDK in your server codebase and can run feature tests, rollouts, personalization and experimentation campaigns.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'VWO-FME','1.4.1'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
