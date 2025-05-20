import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

class SplashScreenController extends GetxController {
  void movePage() async {
    await Future.delayed(
      const Duration(seconds: 3),
      () => Get.offNamed(Routes.HOME),
    );
  }
}
