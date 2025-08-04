part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH_SCREEN = _Paths.SPLASH_SCREEN;
  static const HOME = _Paths.HOME;
  static const FACE_TRACKING = _Paths.FACE_TRACKING;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH_SCREEN = '/splash_screen';
  static const HOME = '/home';
  static const FACE_TRACKING = '/face-tracking';
}
