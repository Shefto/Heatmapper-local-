# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Heatmapper' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'Google-Mobile-Ads-SDK'
  pod 'DTMHeatmap'
  # Pods for Heatmapper

end

target 'Heatmapper WatchKit App' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Heatmapper WatchKit App

end

target 'Heatmapper WatchKit Extension' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Heatmapper WatchKit Extension

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
