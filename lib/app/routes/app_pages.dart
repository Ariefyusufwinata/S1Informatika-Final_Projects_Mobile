import 'package:get/get.dart';

import '../modules/splash_screen/views/splash_screen_view.dart';
import '../modules/home/views/home_view.dart';
import '../modules/face_tracking/views/face_tracking_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH_SCREEN;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH_SCREEN,
      transition: Transition.fade,
      page: () => const SplashScreenView(),
    ),
    GetPage(
      name: _Paths.HOME,
      transition: Transition.fade,
      page: () => const HomeView(),
    ),
    GetPage(
      name: _Paths.FACE_TRACKING,
      transition: Transition.fade,
      page: () => FaceTrackingView(),
    ),
  ];
}
