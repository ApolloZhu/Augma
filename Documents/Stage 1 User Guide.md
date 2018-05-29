# How to Compile?

1. Download [Xcode from Mac App Store](https://itunes.apple.com/us/app/xcode/id497799835). You must use a Mac.
2. Double click to open `Augma.xcodeporj`
3. Click the button with triangle on the top left corner to run, fix codesign issue as prompted by Xcode. This is required due to the codesign requirements of iOS.
4. In case if Xcode doesn't provide instructions for codesigning the app, select "Augma" with blue icon on the left navigation panel, the select the "Augma" under "TARGETS" with a purple icon, then under "Signing," change the Team from "None" to your personal team. You may be asked to sign into your Apple ID. You may be asked to change the Bundle Identifier, just choose a random one.
5. Allow the app to access camera, make sure you have dual cameras, and enjoy. The app will tell you how many fingers are present. A higher contrast between your hand and background works better.
