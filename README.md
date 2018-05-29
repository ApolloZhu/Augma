# Augma

This is an ambitious project that implements Augma, an imaginary device depicted in [*Sword Art Online The Movie: Ordinal Scale*](http://sao-movie.net/us/) which integrates augmented reality into everyday life activities. There already exists such devices like [Google Glass](https://www.x.company/glass/) and Microsoft [HoloLens](https://www.microsoft.com/en-us/hololens), however too expensive for normal customers. The goal of this project is to achieve similar functionalities as a software running on ARKit compatible iPhones (iOS 11, A9 or later processor) alone, without the help of any external sensors.

## Compilation Guide

1. Download [Xcode from Mac App Store](https://itunes.apple.com/us/app/xcode/id497799835). You must use a Mac.
2. Double click to open `Augma.xcodeporj`
3. Click the button with triangle on the top left corner to run, fix codesign issue as prompted by Xcode. This is required due to the codesign requirements of iOS.
4. In case if Xcode doesn't provide instructions for codesigning the app, select "Augma" with blue icon on the left navigation panel, the select the "Augma" under "TARGETS" with a purple icon, then under "Signing," change the Team from "None" to your personal team. You may be asked to sign into your Apple ID.
5. Allow the app to access camera, make sure you have dual cameras, and enjoy. The app will tell you how many fingers are present.

## License

```
Augma - Transforming your iPhone to a HoloLens like device.
Copyright (C) 2018 Zhiyu Zhu <public-apollonian@outlook.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
```

### App Icon Components

<div>Part of the icon, made by <a href="https://www.flaticon.com/authors/pixel-perfect" title="Pixel perfect">Pixel perfect</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>, is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>

Another part of the icon is licensed by **DEVELOPER ARTWORK LICENSE AGREEMENT FOR ARKIT** of **APPLE INC.**.

----

<details>
<summary></summary>

<script type="text/javascript">
  window.onload = function () {
    document.getElementById("augma").style.display="none";
  }
</script>
</details>
