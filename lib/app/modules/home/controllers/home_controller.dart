import 'package:get/get.dart';
import '../../../data/sqlite/database.dart';

class HomeController extends GetxController {
  RxList<Map<String, dynamic>> detectionList = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;
  RxString selectedDate = ''.obs;

  Future<void> loadAllData() async {
    final data = await DatabaseHelper.instance.getAllDetections();
    detectionList.assignAll(data);

    if (data.isNotEmpty) {
      final today = DateTime.now();
      final todayStr =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      if (uniqueDates.contains(todayStr)) {
        selectedDate.value = todayStr;
      } else {
        selectedDate.value = uniqueDates.first;
      }
    }

    isLoading.value = false;
  }

  List<String> get uniqueDates {
    final dates =
        detectionList.map((e) => e['date'] as String).toSet().toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  List<Map<String, dynamic>> get detectionsBySelectedDate {
    return detectionList
        .where((item) => item['date'] == selectedDate.value)
        .toList();
  }

  Future<void> deleteAllData() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('detection');
  }
}
