rm -rf flowfinder.apks
flutter build appbundle
cd ..
cd Downloads
java -jar bundletool-all-1.16.0.jar build-apks --bundle=/home/ikhw/flowfinder/build/app/outputs/bundle/release/app-release.aab --output=/home/ikhw/flowfinder/flowfinder.apks
java -jar bundletool-all-1.16.0.jar install-apks --adb=/home/ikhw/Android/Sdk/platform-tools/adb --apks=/home/ikhw/flowfinder/flowfinder.apks 
