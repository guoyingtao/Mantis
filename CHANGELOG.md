# Change Log

-----

### [2.1.1](https://www.github.com/guoyingtao/Mantis/compare/v2.1.0...v2.1.1) (2022-08-28)


### Bug Fixes

* fix the weird rotation animation issue for alwaysUsingOnePresetFixedRatio ([#202](https://www.github.com/guoyingtao/Mantis/issues/202)) ([4440568](https://www.github.com/guoyingtao/Mantis/commit/4440568098ba4e9c8bec9de9507f1b41d2a231db))

## [2.1.0](https://www.github.com/guoyingtao/Mantis/compare/v2.0.1...v2.1.0) (2022-08-27)


### Features

* add mirror mode support ([#200](https://www.github.com/guoyingtao/Mantis/issues/200)) ([ea6b1f1](https://www.github.com/guoyingtao/Mantis/commit/ea6b1f173d8ce4b63dad440671bcbe3d86638d93))
* support adding border to cropped image ([#196](https://www.github.com/guoyingtao/Mantis/issues/196)) ([f55ae6e](https://www.github.com/guoyingtao/Mantis/commit/f55ae6eca8b16f7afdf34667093a6981c5412eed))


### Bug Fixes

* solve the issue of initial minimum zoom scale is not working ([#190](https://www.github.com/guoyingtao/Mantis/issues/190)) ([560e272](https://www.github.com/guoyingtao/Mantis/commit/560e272d40d3a983403193032b3943005d2947fd))
* use round() instead of floor() for output image size ([#197](https://www.github.com/guoyingtao/Mantis/issues/197)) ([42bb6cc](https://www.github.com/guoyingtao/Mantis/commit/42bb6cc8bcb24fef45c1b8e2db41a71c07de032d))

### [2.0.1](https://www.github.com/guoyingtao/Mantis/compare/v2.0.0...v2.0.1) (2022-07-21)


### Bug Fixes

* restore showRotationDial setting ([f3facb6](https://www.github.com/guoyingtao/Mantis/commit/f3facb6c5a1e613b309f899626fa2ca277203564))

## [2.0.0](https://www.github.com/guoyingtao/Mantis/compare/v1.9.0...v2.0.0) (2022-07-21)


### ⚠ BREAKING CHANGES

* refactor CropToolbarProtocol. Add heightForVerticalOrientation and widthForHorizonOrientation, remove heightForVerticalOrientationConstraint and widthForHorizonOrientationConstraint

### Features

* add CropToolbarIconProvider protocol ([#169](https://www.github.com/guoyingtao/Mantis/issues/169)) ([42b89cd](https://www.github.com/guoyingtao/Mantis/commit/42b89cd9e80702d90ac8fc054bf05939ba726cb7))
* add showAttachedCropToolbar option to CropToolbarConfig ([#177](https://www.github.com/guoyingtao/Mantis/issues/177)) ([417f607](https://www.github.com/guoyingtao/Mantis/commit/417f60711508717aa21c281e75963ea41674b368))
* Customize crop toolbar color ([#178](https://www.github.com/guoyingtao/Mantis/issues/178)) ([eaa8f06](https://www.github.com/guoyingtao/Mantis/commit/eaa8f06d1b55b597036584c2385a86d032d77297))
* make CropToolBar Sizable ([#171](https://www.github.com/guoyingtao/Mantis/issues/171)) ([d01662f](https://www.github.com/guoyingtao/Mantis/commit/d01662f551edc1dea3e7a0401deec7142374f251))
* refactor configs and add zoom scale limitation settings ([#184](https://www.github.com/guoyingtao/Mantis/issues/184)) ([a46341d](https://www.github.com/guoyingtao/Mantis/commit/a46341deef106805602d278d2c8c2484bd5f4f6a))

## [1.9.0](https://www.github.com/guoyingtao/Mantis/compare/v1.8.0...v1.9.0) (2022-01-14)


### Features

* expose CropInfo in cropViewControllerDidCrop ([#157](https://www.github.com/guoyingtao/Mantis/issues/157)) ([a0e3f39](https://www.github.com/guoyingtao/Mantis/commit/a0e3f39c546a1852c32bb3677be562fc194748b8))


### Bug Fixes

* exclude Info.plist in Package file ([4c5de48](https://www.github.com/guoyingtao/Mantis/commit/4c5de486e0f6d1b9cc37c4ae52b87d64f79aed8f))

## [1.8.0](https://www.github.com/guoyingtao/Mantis/compare/v1.7.5...v1.8.0) (2021-11-16)


### Features

* added support to set the rotation limits ([#148](https://www.github.com/guoyingtao/Mantis/issues/148)) ([8feece0](https://www.github.com/guoyingtao/Mantis/commit/8feece05a23c66240bde446ffaea13f2e0dfe4ae))

### [1.7.5](https://www.github.com/guoyingtao/Mantis/compare/v1.7.4...v1.7.5) (2021-11-06)


### Bug Fixes

* solve SPM localization issue ([#145](https://www.github.com/guoyingtao/Mantis/issues/145)) ([8dedb8b](https://www.github.com/guoyingtao/Mantis/commit/8dedb8be2e58874fdf0da0dacd227dc4cec97e22))

### [1.7.4](https://www.github.com/guoyingtao/Mantis/compare/v1.7.3...v1.7.4) (2021-11-05)


### Bug Fixes

* support static lib localization ([#141](https://www.github.com/guoyingtao/Mantis/issues/141)) ([#142](https://www.github.com/guoyingtao/Mantis/issues/142)) ([fd2de0f](https://www.github.com/guoyingtao/Mantis/commit/fd2de0f69ce5c0695b40b32b4ee9e76250a7a58d))

### [1.7.3](https://www.github.com/guoyingtao/Mantis/compare/v1.7.2...v1.7.3) (2021-10-27)


### Bug Fixes

* delete a blank row ([d1506e1](https://www.github.com/guoyingtao/Mantis/commit/d1506e1d5f899114607d5fef0e73dfb0d43363d0))
* fix a code missing problem by bumping version ([1a65bec](https://www.github.com/guoyingtao/Mantis/commit/1a65becf4037fc12bd3af7fe374590d3b57896ee))

### [1.7.2](https://www.github.com/guoyingtao/Mantis/compare/v1.7.1...v1.7.2) (2021-08-11)


### Bug Fixes

* fix the wrong mask rounded rectangle value ([#124](https://www.github.com/guoyingtao/Mantis/issues/124)) ([33a8865](https://www.github.com/guoyingtao/Mantis/commit/33a8865f61f2f0dc0811ebd508ef23791ad91693))
* solve the SwiftLint errors ([#126](https://www.github.com/guoyingtao/Mantis/issues/126)) ([5e147aa](https://www.github.com/guoyingtao/Mantis/commit/5e147aa19785b57a6e5af89d098c30e39438ea51))

### [1.7.1](https://www.github.com/guoyingtao/Mantis/compare/v1.7.0...v1.7.1) (2021-05-02)


### Bug Fixes

* Add logic for macCatalyst mac idiom ([f4c8353](https://www.github.com/guoyingtao/Mantis/commit/f4c83537aac427e27b453dbe584cc0f33173007d))

## [1.7.0](https://www.github.com/guoyingtao/Mantis/compare/v1.6.2...v1.7.0) (2021-05-02)


### Features

* add more custom crop shapes ([#111](https://www.github.com/guoyingtao/Mantis/issues/111)) ([380dd01](https://www.github.com/guoyingtao/Mantis/commit/380dd01dbf1a691799bd5a0bacc56151b91022b4))

### [1.6.2](https://www.github.com/guoyingtao/Mantis/compare/v1.6.1...v1.6.2) (2021-04-26)


### Bug Fixes

* allow set different fixed ratio after preset transforamtion ([#106](https://www.github.com/guoyingtao/Mantis/issues/106)) ([06e98b8](https://www.github.com/guoyingtao/Mantis/commit/06e98b8f37924c29bdc6072d7d5c3eeeba74eecb))

### [1.6.1](https://www.github.com/guoyingtao/Mantis/compare/v1.6.0...v1.6.1) (2021-04-23)


### Bug Fixes

* fix “keep zooming” issue ([#101](https://www.github.com/guoyingtao/Mantis/issues/101)) ([eacc8ed](https://www.github.com/guoyingtao/Mantis/commit/eacc8edda535a8bbf7736f729a3e4cd32bd785e1))
* fix the issue of manul crop not working sometime ([#102](https://www.github.com/guoyingtao/Mantis/issues/102)) ([6f58bb7](https://www.github.com/guoyingtao/Mantis/commit/6f58bb74b8be02b2b921ba665fa9e9e5e45e2e64))
* fix the manual crop offset issue after rotation ([#105](https://www.github.com/guoyingtao/Mantis/issues/105)) ([5e8eb20](https://www.github.com/guoyingtao/Mantis/commit/5e8eb20b00e7158987aab60c8e21a50cd83d22ef))
* fixe a crop issue after rotation for alwaysUsingOnePresetFixedRatio ([f8f7763](https://www.github.com/guoyingtao/Mantis/commit/f8f7763dd7bc2771d2517182c679777dda9f0d3a))
* solve the issues when using normalizedTransform with presetFixedRatioType ([#98](https://www.github.com/guoyingtao/Mantis/issues/98)) ([de03623](https://www.github.com/guoyingtao/Mantis/commit/de03623abf7f12bc7f3f65a2f69f8c9e328b4484))

## [1.6.0 - Add Add Dutch localization](https://github.com/guoyingtao/Mantis/releases/tag/1.6.0) (2021-04-09)

#### Enhencement
* https://github.com/guoyingtao/Mantis/pull/96

---

## [1.5.2 - Fix wrong ratio for fixed ratio selection](https://github.com/guoyingtao/Mantis/releases/tag/1.5.2) (2021-03-30)

#### Fix
* https://github.com/guoyingtao/Mantis/pull/94

---

## [1.5.1 - Fix wrong auto zoom and a memory leak issue](https://github.com/guoyingtao/Mantis/releases/tag/1.5.1) (2021-03-22)

#### Fix
* https://github.com/guoyingtao/Mantis/pull/92

---

## [1.5.0 - Add getBitmapInfo for creating CGContext when cropping](https://github.com/guoyingtao/Mantis/releases/tag/1.5.0) (2021-03-20)

#### Enhencement
* https://github.com/guoyingtao/Mantis/pull/90

---

## [1.4.13 - Remove CFBundleExecutable key from resources bundle](https://github.com/guoyingtao/Mantis/releases/tag/1.4.13) (2021-03-04)

#### Fix
* https://github.com/guoyingtao/Mantis/pull/88

---


## [1.4.12 - Set showRatiosType for RatioSelector](https://github.com/guoyingtao/Mantis/releases/tag/1.4.12) (2021-02-23)

#### Enhencement
* https://github.com/guoyingtao/Mantis/issues/85

---

## [1.4.11 - Fix #85 #87](https://github.com/guoyingtao/Mantis/releases/tag/1.4.11) (2021-02-22)

#### Enhencement
* https://github.com/guoyingtao/Mantis/issues/87#issuecomment-784150304

---


## [1.4.10 - Fix getting resources from prebuilt framework](https://github.com/guoyingtao/Mantis/releases/tag/1.4.10) (2021-02-09)

#### Fix
Merge the PR #84: 
* https://github.com/guoyingtao/Mantis/pull/84

---

## [1.4.9 - Fix build with BUILD_LIBRARY_FOR_DISTRIBUTION](https://github.com/guoyingtao/Mantis/releases/tag/1.4.9) (2021-02-04)

#### Fix
Solve the issues: 
* https://github.com/guoyingtao/Mantis/pull/82
* https://github.com/guoyingtao/Mantis/issues/81

---


## [1.4.8 - Fix clockwise roration bug](https://github.com/guoyingtao/Mantis/releases/tag/1.4.8) (2021-01-17)

#### Enhancement
Solve the issue: https://github.com/guoyingtao/Mantis/issues/79

---

## [1.4.7 - Fix clockwise roration bug](https://github.com/guoyingtao/Mantis/releases/tag/1.4.7) (2020-11-19)

#### Fix
Fix a bug for clockwise rotation https://github.com/guoyingtao/Mantis/issues/75

---

-----

## [1.4.6 - Remove animation](https://github.com/guoyingtao/Mantis/releases/tag/1.4.6) (2020-11-18)

#### Fix
Remove animation when Mantis.Config.presetFixedRatioType is alwaysUsingOnePresetFixedRatio

---
