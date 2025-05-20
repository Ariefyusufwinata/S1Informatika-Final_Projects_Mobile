import 'package:get/get.dart';

import '../routes/app_pages.dart';

class Utils {
  static void changePage({
    required int index,
  }) {
    switch (index) {
      case 0:
        Get.offNamed(Routes.HOME);
        break;
      case 1:
        Get.offNamed(Routes.ANALYTICS);
      default:
        Get.offNamed(Routes.HOME);
    }
  }
}