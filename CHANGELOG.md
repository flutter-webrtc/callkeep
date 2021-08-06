# Changelog

-----------------------------------------------
[0.3.1] - 2021.07.27

* Add foregroundService for Android 11.

[0.3.0] - 2021.06.12

* null safety
* Add toolkit for testing.
* Fixed receiving Voip push in background mode for iOS 13+.
* Fix crash when iOS push uses the wrong push format (alert).

[0.2.4] - 2021.01.08

* Fix crash when appName is not set.
* hasDefaultPhoneAccount give feedback about the user choice.

[0.2.3] - 2021.01.08

* Fix backToForeground method.

[0.2.2] - 2020.12.27

* Update json format for push payload.

[0.2.1] - 2020.12.23

* Fix: Missing null check.
* Fix: change parameter handle to number.

[0.2.0] - 2020.11.11

* Change FlutterCallKeep as a singleton.
* Add CallKeepPushKitToken event for iOS.
* Add firebase_messaging to example.
* Support waking CallKeep from PushKit when the app is closed.

[0.1.1] - 2020.09.17

* Fix compile error for iOS.

[0.1.0] - 2020.09.15

* Initial release.
* Support iOS 10+ and Android 6.0+.
