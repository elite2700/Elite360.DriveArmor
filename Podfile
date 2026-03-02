platform :ios, '17.0'
inhibit_all_warnings!
use_frameworks!

target 'DriveArmor' do
  # Firebase
  pod 'Firebase/Auth',       '~> 11.0'
  pod 'Firebase/Firestore',  '~> 11.0'
  pod 'Firebase/Messaging',  '~> 11.0'

  target 'DriveArmorTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
    end
  end
end
