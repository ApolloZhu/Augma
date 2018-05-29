# Augma

This is an ambitious project that implements Augma, an imaginary device depicted in [*Sword Art Online The Movie: Ordinal Scale*](http://sao-movie.net/us/) which integrates augmented reality into everyday life activities. There already exists such devices like [Google Glass](https://www.x.company/glass/) and Microsoft [HoloLens](https://www.microsoft.com/en-us/hololens), however too expensive for normal customers. The goal of this project is to achieve similar functionalities as a software running on ARKit compatible iPhones (iOS 11, A9 or later processor) alone, without the help of any external sensors.

## Stage 1 Description

The project itself is too complicated, therefore divided into several stages, with hand gesture recognition being the most essential part. I consider this stage alone complex enough as the final project, which I'll use the [OpenCV library](https://opencv.org/) with a compatible programming language (python for prototype and Objective-C++ for the actual app running on iPhone).

Improving accuracy and architectural design is not considered part of stage 1.

## Designed Approach

Identification of the hand will be based on color range, which (optionally) the user will calibrate with their own hands. Recognizer will use binarized static images, continuous videos, and combinations of the two to match against built-in templates to classify the gesture.

## Expected Features

Based on the standards of [ManoMotion](https://www.manomotion.com/), a mature SDK provider that **supposedly** provides a similar SDK, the ultimate final product should be able to identify:

- [x] Hand Presence
- [x] One Hand (either L or R)
- [x] Hand Contour
- [x] Skeleton
- [x] Fingertips
- [ ] *Palm Center*
- [ ] *Detailed Hand Pose Information*
- [ ] Built-in gesture Recognition
- [ ] Custom gestures
<del>- [ ] Inner Points</del>
<del>- [ ] Two hands</del>

## External Resources

A quick google search with "hand gesture recognition" yields many YouTube videos. That list is omitted since the number of videos is too large. For OpenCV, official [documentation](https://docs.opencv.org/master/) and [tutorials](https://docs.opencv.org/master/d9/df8/tutorial_root.html) are available, as well as blog posts on [edge detection](https://medium.com/ios-os-x-development/the-fd4fcb249358) of a [custom shape](https://www.toptal.com/machine-learning/real-time-object-detection-using-mser-in-ios). Several online tutorials also cover this topic to a certain extent. Again, the list is rather long and thus not included.

## Personal Goal

Once finished, the source code, presentation, and documentation will be made available on GitHub at [https://github.com/ApolloZhu/Augma](https://github.com/ApolloZhu/Augma) under [GNU General Public License](https://github.com/ApolloZhu/Augma/blob/master/LICENSE). But more importantly, this project will introduce me to the OpenCV framework, the Objective-C++ programming language, and computer vision (object recognition specifically). Additionally, getting familiar with C++ will prepare me for further studying into lower level computer systems.

## Timeline

Completing the entire ecosystem might take infinitely long. However, I should be able to complete stage 1 within the given time frame (with full dedication). The following milestones are the expected time frame organized by weeks in stage one, and the actual progress and tasks will be organized through this Kanban at [https://github.com/ApolloZhu/Augma/projects/1](https://github.com/ApolloZhu/Augma/projects/1).

|Week|In Class|At Home|
|--|--|--|
|5/1 - 5/7|Extract hand image|Identify hand position|
|5/8 - 5/13|Extract hand skeleton|Recognize gesture|
|5/14 - 5/21|Porting to Objective-C++|Implement native iOS UI|
|5/22 - 5/31|Presentation|Final adjustment|
|Future|N/A|Improve accuracy|

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

2018/03/09 Ver. (Update May 28)

<script type="text/javascript">
  window.onload = function () {
    document.getElementById("augma").style.display="none";
  }
</script>
