#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint pdf_master.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'pdf_master'
  s.version          = '0.0.1'
  s.summary          = 'PDF Viewer Powered By Pdfium.'
  s.description      = <<-DESC
PDF Viewer Powered By Pdfium.
DESC
  s.homepage         = 'https://github.com/chengjie-jlu'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'chengjie.jlu@qq.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.vendored_frameworks = 'Frameworks/Pdfium.xcframework'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 x86_64',
  }

  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'pdf_master_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
