part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const SPLASH_SCREEN = _Paths.SPLASH_SCREEN;
  static const HOME = _Paths.HOME;
  static const ANALYTICS = _Paths.ANALYTICS;
}

abstract class _Paths {
  _Paths._();
  static const SPLASH_SCREEN = '/splash_screen';
  static const HOME = '/home';
  static const ANALYTICS = '/analytics';
}