# Change Log

-----

## [2.28.0](https://www.github.com/guoyingtao/Mantis/compare/v2.27.0...v2.28.0) (2025-10-18)


### Features

* support more actions for CropAction ([#480](https://www.github.com/guoyingtao/Mantis/issues/480)) ([3b3f45b](https://www.github.com/guoyingtao/Mantis/commit/3b3f45bbbeb0469c6b3acd90840dd8cd6428584d))

## [2.27.0](https://www.github.com/guoyingtao/Mantis/compare/v2.26.0...v2.27.0) (2025-08-22)


### Features

* support callback when crop is done ([#471](https://www.github.com/guoyingtao/Mantis/issues/471)) ([dcf5728](https://www.github.com/guoyingtao/Mantis/commit/dcf5728c58e9d8e058d2e69fc61b21e3141b2288))


### Bug Fixes

* avoid SwiftUI warning by scheduling binding updates async in cropViewControllerDidCrop ([#475](https://www.github.com/guoyingtao/Mantis/issues/475)) ([d1069ce](https://www.github.com/guoyingtao/Mantis/commit/d1069ce75468e7a301b4e74e57c03d103f4626e9))
* fix crop view displaying issue on iOS 26 ([#466](https://www.github.com/guoyingtao/Mantis/issues/466)) ([7462405](https://www.github.com/guoyingtao/Mantis/commit/74624054cdef2d8bee1ac3daf55ca1589bc42167))
* fix crop view displaying issue on iOS 26 ([#476](https://www.github.com/guoyingtao/Mantis/issues/476)) ([c19db4a](https://www.github.com/guoyingtao/Mantis/commit/c19db4a0613e829a5274f19b3910f73b415f645d))
* publishing changes from not main thread ([#474](https://www.github.com/guoyingtao/Mantis/issues/474)) ([4ddb8ff](https://www.github.com/guoyingtao/Mantis/commit/4ddb8ff72a8cfb05a84cc3f32cc930f53dd2e45b))

## [2.26.0](https://www.github.com/guoyingtao/Mantis/compare/v2.25.3...v2.26.0) (2025-06-20)


### Features

* add headless crop support ([#463](https://www.github.com/guoyingtao/Mantis/issues/463)) ([22994b8](https://www.github.com/guoyingtao/Mantis/commit/22994b8a642c2b10752f27a91c4bdb5ba394f6bf))

### [2.25.3](https://www.github.com/guoyingtao/Mantis/compare/v2.25.2...v2.25.3) (2025-05-30)


### Bug Fixes

* Add macCatalyst as a supported platform in Package.swift ([941d4c4](https://www.github.com/guoyingtao/Mantis/commit/941d4c45fa393a2e937e69f5d365d46743d5583c))

### [2.25.2](https://www.github.com/guoyingtao/Mantis/compare/v2.25.1...v2.25.2) (2025-05-25)


### Bug Fixes

* drop macOS support and update min support version to v12 for iOS ([#452](https://www.github.com/guoyingtao/Mantis/issues/452)) ([a977c8c](https://www.github.com/guoyingtao/Mantis/commit/a977c8c67ee4934eabc22d4a44a11dcc81a215eb))

### [2.25.1](https://www.github.com/guoyingtao/Mantis/compare/v2.25.0...v2.25.1) (2025-05-16)


### Bug Fixes

* fix the wrong parameter issue for createBackupCGContext ([#447](https://www.github.com/guoyingtao/Mantis/issues/447)) ([d7c7c3b](https://www.github.com/guoyingtao/Mantis/commit/d7c7c3b50c614d01ae6e1d61b058fc0d50820e6c))

## [2.25.0](https://www.github.com/guoyingtao/Mantis/compare/v2.24.0...v2.25.0) (2025-04-06)


### Features

* add ImageCropperView wrapped for SwiftUI users ([fd33295](https://www.github.com/guoyingtao/Mantis/commit/fd332959193801990f7e32ef8c00ca4c0db0fe91))

## [2.24.0](https://www.github.com/guoyingtao/Mantis/compare/v2.23.2...v2.24.0) (2025-03-26)


### Features

* make Transformation and CropRegion completely public ([#437](https://www.github.com/guoyingtao/Mantis/issues/437)) ([0ffcbd7](https://www.github.com/guoyingtao/Mantis/commit/0ffcbd7764c2b662479785c1cefeae78f246b36c))

### [2.23.2](https://www.github.com/guoyingtao/Mantis/compare/v2.23.1...v2.23.2) (2025-02-10)


### Bug Fixes

* fix the issue that rotation control jumps during orientation change ([#433](https://www.github.com/guoyingtao/Mantis/issues/433)) ([2b08f10](https://www.github.com/guoyingtao/Mantis/commit/2b08f10dd9d171a61eadcb72440e17b19555a63c))

### [2.23.1](https://www.github.com/guoyingtao/Mantis/compare/v2.23.0...v2.23.1) (2024-10-28)


### Bug Fixes

* fix a crash for 48 bits bitmap ([#423](https://www.github.com/guoyingtao/Mantis/issues/423)) ([c2ea51a](https://www.github.com/guoyingtao/Mantis/commit/c2ea51aff165dea0712e4ec8ef1e89f52ef1986f))

## [2.23.0](https://www.github.com/guoyingtao/Mantis/compare/v2.22.0...v2.23.0) (2024-10-14)


### Features

* support keyboard zoom in/out for Mac Catalyst ([#416](https://www.github.com/guoyingtao/Mantis/issues/416)) ([291e5a7](https://www.github.com/guoyingtao/Mantis/commit/291e5a70d5b8146025e85ee9889b77e09f34f745))


### Bug Fixes

* use createBackupCGContext in cgImageWithFixedOrientation ([#414](https://www.github.com/guoyingtao/Mantis/issues/414)) ([3430aaf](https://www.github.com/guoyingtao/Mantis/commit/3430aaf1d72db718c6a6be7bde4dd6ca391b6a74))

## [2.22.0](https://www.github.com/guoyingtao/Mantis/compare/v2.21.0...v2.22.0) (2024-07-20)


### Features

* add CropAuxiliaryIndicatorConfig to allow custom CropAuxiliaryIndicator colors ([#405](https://www.github.com/guoyingtao/Mantis/issues/405)) ([bc50ce7](https://www.github.com/guoyingtao/Mantis/commit/bc50ce7e99195328255ba541bc02dd9ab38e47a2))


### Bug Fixes

* fix the rotation issue when undo/redo for a flipped image ([#393](https://www.github.com/guoyingtao/Mantis/issues/393)) ([#394](https://www.github.com/guoyingtao/Mantis/issues/394)) ([2ad6323](https://www.github.com/guoyingtao/Mantis/commit/2ad632377a099824990e15303c5caf736f73bf91))
* fix undo redo rotation issues when flipped ([#396](https://www.github.com/guoyingtao/Mantis/issues/396)) ([29b6fec](https://www.github.com/guoyingtao/Mantis/commit/29b6fec55cfe2d7c5bb59324d0cfb75bd7426c7a))

## [2.21.0](https://www.github.com/guoyingtao/Mantis/compare/v2.20.0...v2.21.0) (2024-04-10)


### Features

* support updating image while cropping ([#387](https://www.github.com/guoyingtao/Mantis/issues/387)) ([e08e341](https://www.github.com/guoyingtao/Mantis/commit/e08e3419a65a26bc09194684f8d7ccfbcf39e5b4))


### Bug Fixes

* fix image zoom center issue ([#390](https://www.github.com/guoyingtao/Mantis/issues/390)) ([c0f892c](https://www.github.com/guoyingtao/Mantis/commit/c0f892c4756eeccbf3544739bfa210b88de1d1eb))

## [2.20.0](https://www.github.com/guoyingtao/Mantis/compare/v2.19.0...v2.20.0) (2024-03-25)


### Features

* Undo/Redo Feature for Mantis ([#379](https://www.github.com/guoyingtao/Mantis/issues/379)) ([9a1e67a](https://www.github.com/guoyingtao/Mantis/commit/9a1e67af3e7d078d4629d43997d4248d2c4cf7a1))

## [2.19.0](https://www.github.com/guoyingtao/Mantis/compare/v2.18.0...v2.19.0) (2024-03-04)


### Features

* Add cropAuxiliaryIndicatorStyle in CropViewConfig for the issue [#366](https://www.github.com/guoyingtao/Mantis/issues/366) ([#367](https://www.github.com/guoyingtao/Mantis/issues/367)) ([4f7e842](https://www.github.com/guoyingtao/Mantis/commit/4f7e842becc54f5fa704e780ff3d2297a6577990))

* Add turkish localizable [(#375)](https://github.com/guoyingtao/Mantis/pull/375) ([f625d81](https://github.com/guoyingtao/Mantis/commit/f625d81723ca8a25c1d7324bc2839a80ac9f9b78))

## [2.18.0](https://www.github.com/guoyingtao/Mantis/compare/v2.17.1...v2.18.0) (2023-12-05)


### Features

* Output realtime transformation for a special use case ([#363](https://www.github.com/guoyingtao/Mantis/issues/363)) ([a5f9728](https://www.github.com/guoyingtao/Mantis/commit/a5f9728a691b1a9c6cbc2785fb0357dbd36d0156))

### [2.17.1](https://www.github.com/guoyingtao/Mantis/compare/v2.17.0...v2.17.1) (2023-11-21)


### Bug Fixes

* update the logic of getting bitmapInfo to honor the original alpha channel information ([#360](https://www.github.com/guoyingtao/Mantis/issues/360)) ([f3180fe](https://www.github.com/guoyingtao/Mantis/commit/f3180fed54bc8c1e0e9ef0d32d4c4c69b171ff15))

## [2.17.0](https://www.github.com/guoyingtao/Mantis/compare/v2.16.1...v2.17.0) (2023-11-16)


### Features

* support a new feature of fixing crop box when rotating 90 degree ([#357](https://www.github.com/guoyingtao/Mantis/issues/357)) ([5e125f0](https://www.github.com/guoyingtao/Mantis/commit/5e125f02abf920dc231c855e207253ee42b28c9d))


### Bug Fixes

* fix flip issue when rotating angle is exact 45 or -45 degrees ([#353](https://www.github.com/guoyingtao/Mantis/issues/353)) ([6f73382](https://www.github.com/guoyingtao/Mantis/commit/6f733820efcfff17c1c50ea59e9134fbce218161))

### [2.16.1](https://www.github.com/guoyingtao/Mantis/compare/v2.16.0...v2.16.1) (2023-11-02)


### Bug Fixes

* fix fix-ratio not changing when switch to free ratio, change crop box then switch back ([#351](https://www.github.com/guoyingtao/Mantis/issues/351)) ([744cc2a](https://www.github.com/guoyingtao/Mantis/commit/744cc2a50efcdd9245f23767eda0071768abd0dc))

## [2.16.0](https://www.github.com/guoyingtao/Mantis/compare/v2.15.0...v2.16.0) (2023-11-02)


### Features

* loose dragging outside restrictions for fix ratios ([0ccd247](https://www.github.com/guoyingtao/Mantis/commit/0ccd247597bd5bf066b876e8de72ef6a53a6e370))

## [2.15.0](https://www.github.com/guoyingtao/Mantis/compare/v2.14.1...v2.15.0) (2023-11-01)


### Features

* support dragging the crop box when touch point outside the crop box ([#339](https://www.github.com/guoyingtao/Mantis/issues/339)) ([646a239](https://www.github.com/guoyingtao/Mantis/commit/646a239ad00fb2d40df2a67e6376c959a07c4ecf))


### Bug Fixes

* fix flip issue for preset transformation ([#342](https://www.github.com/guoyingtao/Mantis/issues/342)) ([2d06e2e](https://www.github.com/guoyingtao/Mantis/commit/2d06e2e37c69da9c9e267328a9aa2a88dad207e6))
* fix initial view show-up issue for preset transformation ([#343](https://www.github.com/guoyingtao/Mantis/issues/343)) ([4b94612](https://www.github.com/guoyingtao/Mantis/commit/4b946120925f4ffecc8128a8bc565a95d3e76f60))
* fix the crop masks become darker and darker when resetting multiple times ([#331](https://www.github.com/guoyingtao/Mantis/issues/331)) ([4f996c1](https://www.github.com/guoyingtao/Mantis/commit/4f996c171d3a63b76906cb372046e9df41776d09))
* remove unnecessary checking logic for image origentations ([#336](https://www.github.com/guoyingtao/Mantis/issues/336)) ([08a684a](https://www.github.com/guoyingtao/Mantis/commit/08a684a55bfd9e90fb6a23ae4c55c87cefbe1338))

### [2.14.1](https://www.github.com/guoyingtao/Mantis/compare/v2.14.0...v2.14.1) (2023-07-13)


### Bug Fixes

* fix wrong image container rect values after rotating ([#325](https://www.github.com/guoyingtao/Mantis/issues/325)) ([a4c5013](https://www.github.com/guoyingtao/Mantis/commit/a4c50137d342e0e561b7fc80ec9603fe621493ab))

## [2.14.0](https://www.github.com/guoyingtao/Mantis/compare/v2.13.0...v2.14.0) (2023-06-28)


### Features

* support auto adjusting an image ([#321](https://www.github.com/guoyingtao/Mantis/issues/321)) ([da22bf5](https://www.github.com/guoyingtao/Mantis/commit/da22bf52b0dd3d7bf2c51f2ccae511258ac0f274))


### Bug Fixes

* fix flip animation issue ([#323](https://www.github.com/guoyingtao/Mantis/issues/323)) ([c8f2fc5](https://www.github.com/guoyingtao/Mantis/commit/c8f2fc5bb1e9dbc8b58d0fbdd6511364bcf77fd0))

## [2.13.0](https://www.github.com/guoyingtao/Mantis/compare/v2.12.0...v2.13.0) (2023-06-22)


### Features

* add a new type of rotation dial ([#312](https://www.github.com/guoyingtao/Mantis/issues/312)) ([9605c3d](https://www.github.com/guoyingtao/Mantis/commit/9605c3d39a0e92a1991d375668cc4d6e90ce4dcd))

## [2.12.0](https://www.github.com/guoyingtao/Mantis/compare/v2.11.0...v2.12.0) (2023-06-22)


### Features

* add new delegate function to output resettable information ([#317](https://www.github.com/guoyingtao/Mantis/issues/317)) ([03a7052](https://www.github.com/guoyingtao/Mantis/commit/03a70527fa8a4507da789105ec5cddbf57ceecf3))

## [2.11.0](https://www.github.com/guoyingtao/Mantis/compare/v2.10.0...v2.11.0) (2023-06-16)


### Features

* add support for Index Color Image ([#314](https://www.github.com/guoyingtao/Mantis/issues/314)) ([f616cfb](https://www.github.com/guoyingtao/Mantis/commit/f616cfb2af43e6baacdcad738d7e107814218b8a))

## [2.10.0](https://www.github.com/guoyingtao/Mantis/compare/v2.9.1...v2.10.0) (2023-05-26)


### Features

* allow user to set CropView background color via config ([#309](https://www.github.com/guoyingtao/Mantis/issues/309)) ([a54521b](https://www.github.com/guoyingtao/Mantis/commit/a54521bbc44bf90c155f8e7a2420ac93e4a307c5))
* make rotation view customizable ([#308](https://www.github.com/guoyingtao/Mantis/issues/308)) ([07d1b32](https://www.github.com/guoyingtao/Mantis/commit/07d1b3243313de1b7dea5fb39619a9434b91be24))
* output image processing errors ([#305](https://www.github.com/guoyingtao/Mantis/issues/305)) ([cdb7117](https://www.github.com/guoyingtao/Mantis/commit/cdb71173e3b84ca19e1baacadbd3ac6346e48604))


### Bug Fixes

* make CropRegion props public ([#299](https://www.github.com/guoyingtao/Mantis/issues/299)) ([d919e54](https://www.github.com/guoyingtao/Mantis/commit/d919e546f49af922df2fcb5de01e742bc82829cf))
* use CGImageAlphaInfo.noneSkipLast.rawValue instead of CGImageAlphaInfo.none.rawValue ([3882317](https://www.github.com/guoyingtao/Mantis/commit/388231755e1f8dc0df002620a45ce4e4d3d8d6ac))

### [2.9.1](https://www.github.com/guoyingtao/Mantis/compare/v2.9.0...v2.9.1) (2023-04-13)


### Bug Fixes

* fix the guard logics for adjustUIForNewCrop ([c093c15](https://www.github.com/guoyingtao/Mantis/commit/c093c157ea1d237a261a15e8fb38848c7de69cb1))

## [2.9.0](https://www.github.com/guoyingtao/Mantis/compare/v2.8.0...v2.9.0) (2023-04-13)


### Features

* Added flag to disable deformation of crop box ([#296](https://www.github.com/guoyingtao/Mantis/issues/296)) ([ba65283](https://www.github.com/guoyingtao/Mantis/commit/ba652836c18414afdb8b62529b12a3af606a7086))
* support custom waiting animation for async crop ([#284](https://www.github.com/guoyingtao/Mantis/issues/284)) ([7800c07](https://www.github.com/guoyingtao/Mantis/commit/7800c0775958a35ecb6bafac7b61092dd28945c5))


### Bug Fixes

* add guard to make sure scaleX and scaleY are not infinite ([#297](https://www.github.com/guoyingtao/Mantis/issues/297)) ([05a418d](https://www.github.com/guoyingtao/Mantis/commit/05a418dc1f08f3ec2b4c5fe983419bc4f2d82fff))
* fix resetting rotation dial caused UI issue ([#287](https://www.github.com/guoyingtao/Mantis/issues/287)) ([f432e36](https://www.github.com/guoyingtao/Mantis/commit/f432e362b7ceda8dba028b71e375bbf735066eaa))
* fix RotationDial reset issue ([82cc00e](https://www.github.com/guoyingtao/Mantis/commit/82cc00ebb9087da3651eac76992b2cb40045c66e))
* fix vertical flip button icon image issue ([643884b](https://www.github.com/guoyingtao/Mantis/commit/643884b050b95c7978b90e86f7959fe605c3f780))

## [2.8.0](https://www.github.com/guoyingtao/Mantis/compare/v2.7.0...v2.8.0) (2023-02-14)


### Features

* add support for changing languages without restarting app ([#276](https://www.github.com/guoyingtao/Mantis/issues/276)) ([5227009](https://www.github.com/guoyingtao/Mantis/commit/522700903683e0c70245298258504a6defb40cd0))


### Bug Fixes

* fix orientation issues on iPad ([#281](https://www.github.com/guoyingtao/Mantis/issues/281)) ([714bf79](https://www.github.com/guoyingtao/Mantis/commit/714bf7979130b95baecc6f5a1e5d09518ed61f64))

## [2.7.0](https://www.github.com/guoyingtao/Mantis/compare/v2.6.2...v2.7.0) (2023-02-05)


### Features

* Open up CropViewController for inheritance. ([#274](https://www.github.com/guoyingtao/Mantis/issues/274)) ([cdeafcd](https://www.github.com/guoyingtao/Mantis/commit/cdeafcd39f1666558160e4fbd47018ed3a8b6f5d))

### [2.6.2](https://www.github.com/guoyingtao/Mantis/compare/v2.6.1...v2.6.2) (2023-02-03)


### Bug Fixes

* solve the gesture conflict when rotating dial for not full screen presentation ([#272](https://www.github.com/guoyingtao/Mantis/issues/272)) ([ca09343](https://www.github.com/guoyingtao/Mantis/commit/ca09343b6a7c3876fb016003718b1ff02956340e))

### [2.6.1](https://www.github.com/guoyingtao/Mantis/compare/v2.6.0...v2.6.1) (2023-02-01)


### Bug Fixes

* add 48 and 24 bit image cases for getBitmapInfo() ([#268](https://www.github.com/guoyingtao/Mantis/issues/268)) ([63242ac](https://www.github.com/guoyingtao/Mantis/commit/63242ac83ed426312aac021a32e90b334eab1b62))

## [2.6.0](https://www.github.com/guoyingtao/Mantis/compare/v2.5.2...v2.6.0) (2023-01-31)


### Features

* add 4 edge line handles on CropAuxiliaryIndicatorView ([#258](https://www.github.com/guoyingtao/Mantis/issues/258)) ([cbbc2e1](https://www.github.com/guoyingtao/Mantis/commit/cbbc2e1b283f2edb10341c96910228d476e576e4))

### [2.5.2](https://www.github.com/guoyingtao/Mantis/compare/v2.5.1...v2.5.2) (2023-01-30)


### Bug Fixes

* fix the issue of output size does not match the crop ratio ([#260](https://www.github.com/guoyingtao/Mantis/issues/260)) ([459aa77](https://www.github.com/guoyingtao/Mantis/commit/459aa77cb19e2805ea7f8e6ef3cf169588766a3e))

### [2.5.1](https://www.github.com/guoyingtao/Mantis/compare/v2.5.0...v2.5.1) (2023-01-28)


### Bug Fixes

* use optional CropToolbarProtocol for CropToolbarDelegate ([#255](https://www.github.com/guoyingtao/Mantis/issues/255)) ([46a3af0](https://www.github.com/guoyingtao/Mantis/commit/46a3af06a2eecaa989970a208f5c5dfebd165432))

## [2.5.0](https://www.github.com/guoyingtao/Mantis/compare/v2.4.0...v2.5.0) (2023-01-27)


### Features

* add CropRegion into CropInfo ([035b079](https://www.github.com/guoyingtao/Mantis/commit/035b07994dbd57157f0831a4c81cfa3ef6553f67))


### Bug Fixes

* fix reset issues ([b10d031](https://www.github.com/guoyingtao/Mantis/commit/b10d031242036149fb8ba2259044e937699eb114))
* fix the issue when using canUseMultiplePresetFixedRatio with default ratio > 0 ([#252](https://www.github.com/guoyingtao/Mantis/issues/252)) ([cbd66dd](https://www.github.com/guoyingtao/Mantis/commit/cbd66dd6419406ec56f266b3aad073981750ffe4))

## [2.4.0](https://www.github.com/guoyingtao/Mantis/compare/v2.3.0...v2.4.0) (2023-01-16)


### Features

* support async crop ([#232](https://www.github.com/guoyingtao/Mantis/issues/232)) ([69e5640](https://www.github.com/guoyingtao/Mantis/commit/69e5640f64bee3c0cfd06526ab4fdecb70450fe9))


### Bug Fixes

* fix the issue that sometimes it is hard to move crop box ([#243](https://www.github.com/guoyingtao/Mantis/issues/243)) ([af51496](https://www.github.com/guoyingtao/Mantis/commit/af51496d8a33894e0f3a8576f75c72b11f75d55f))

## [2.3.0](https://www.github.com/guoyingtao/Mantis/compare/v2.2.1...v2.3.0) (2022-11-13)


### Features

* make CropViewConfig.padding public ([#229](https://www.github.com/guoyingtao/Mantis/issues/229)) ([7f3dedd](https://www.github.com/guoyingtao/Mantis/commit/7f3dedd3061ff4226d9e4d3e815f0896e7254aa8))


### Bug Fixes

* present full screen for mac catalyst ([#226](https://www.github.com/guoyingtao/Mantis/issues/226)) ([3921dbc](https://www.github.com/guoyingtao/Mantis/commit/3921dbc9ffc9da9de7a6e9b6f07a5b32b76bef81))

### [2.2.1](https://www.github.com/guoyingtao/Mantis/compare/v2.2.0...v2.2.1) (2022-11-02)


### Bug Fixes

* solve reset UI issue ([b531628](https://www.github.com/guoyingtao/Mantis/commit/b531628e1d82ae87ca9a8ab203670308a7c5f104))

## [2.2.0](https://www.github.com/guoyingtao/Mantis/compare/v2.1.2...v2.2.0) (2022-10-31)


### Features

* add cropViewControllerDidImageTransformed ([#222](https://www.github.com/guoyingtao/Mantis/issues/222)) ([8fee217](https://www.github.com/guoyingtao/Mantis/commit/8fee217d575dc39c839526fc236f31da198db40e))

### [2.1.2](https://www.github.com/guoyingtao/Mantis/compare/v2.1.1...v2.1.2) (2022-10-28)


### Bug Fixes

* solve pan gesture conflict ([#220](https://www.github.com/guoyingtao/Mantis/issues/220)) ([479bb62](https://www.github.com/guoyingtao/Mantis/commit/479bb625e04a27a0f9a7c5d712f0f1c004c6dce6))

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
