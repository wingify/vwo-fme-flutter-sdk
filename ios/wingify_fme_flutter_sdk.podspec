#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint wingify_fme_flutter_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'wingify_fme_flutter_sdk'
  s.version          = '0.0.1'
  s.summary          = 'Wingify is a server-side solution where you integrate Wingify SDK in your server codebase and can run feature tests, rollouts, personalization and experimentation campaigns.'
  s.description      = <<-DESC
Wingify is a server-side solution where you integrate Wingify's SDK in your server codebase and can run feature tests, rollouts, personalization and experimentation campaigns.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Wingify-FME','1.55.0'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => '$(inherited) WINGIFY_FME_FLUTTER_SDK'
  }
  s.swift_version = '5.0'
end
