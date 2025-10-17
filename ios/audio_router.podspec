# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint audio_router.podspec` to validate before publishing.
Pod::Spec.new do |s|
  s.name             = 'audio_router'
  s.version          = '1.0.0'
  s.summary          = 'Flutter plugin for managing audio output routing.'
  s.description      = <<-DESC
Audio Router exposes native audio route selection UI and device state updates for VoIP and communication apps.
  DESC
  s.homepage         = 'https://github.com/vagabondms/audio_router'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'audio_router contributors'
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.swift_version = '5.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }

  s.resource_bundles = {
    'audio_router_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end
