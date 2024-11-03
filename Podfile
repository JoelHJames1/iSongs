# Define the platform for your project
platform :ios, '15.0' # Or whichever minimum target you prefer

# Ensure all pods respect this deployment target
# This line enforces the minimum deployment target on all pods
$IPHONEOS_DEPLOYMENT_TARGET = '15.0'

target 'iSongs' do
  use_frameworks!

  # Firebase dependencies
  pod 'Firebase/Auth'         # Firebase Authentication
  pod 'Firebase/Firestore'    # Firebase Firestore Database

  # YouTube handling
  pod 'XCDYouTubeKit', '~> 2.15' # YouTube video/audio handling

  target 'iSongsTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'iSongsUITests' do
    inherit! :search_paths
    # Pods for UI testing
  end
end
