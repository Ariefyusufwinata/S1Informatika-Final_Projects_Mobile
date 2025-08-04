import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

import '../../../themes/themes.dart';
import '../../../utils/utils.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final controller = Get.put(HomeController());

  @override
  void initState() {
    controller.loadAllData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      bottomNavigationBar: ConvexAppBar(
        top: 0,
        height: 50,
        color: AppColor.black,
        activeColor: AppColor.blue,
        backgroundColor: AppColor.white,
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.home, title: ''),
          TabItem(icon: Icons.face, title: ''),
        ],
        initialActiveIndex: 0,
        onTap: (i) => Utils.changePage(index: i),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedDate = controller.selectedDate.value;
        final data = controller.detectionsBySelectedDate;

        if (selectedDate.isEmpty || data.isEmpty) {
          return const Center(
            child: Text(
              "Belum ada data deteksi hari ini!",
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        final counts = {'Drowsy': 0, 'Neutral': 0, 'Distracted': 0};
        for (var item in data) {
          final detect = item['detect'];
          if (counts.containsKey(detect)) {
            counts[detect] = counts[detect]! + 1;
          }
        }

        final total = counts.values.fold(0, (a, b) => a + b);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(
            top: 40,
            left: 10,
            right: 10,
            bottom: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pilih Tanggal",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: controller.selectedDate.value,
                      isExpanded: true,
                      items:
                          controller.uniqueDates.map((date) {
                            return DropdownMenuItem(
                              value: date,
                              child: Text(date),
                            );
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.selectedDate.value = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) {
                          return AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text(
                              'Yakin ingin menghapus semua data?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Get.back();
                                },
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await controller.deleteAllData();
                                  controller.selectedDate.value = '';
                                  controller.update();
                                  Navigator.of(context).pop();
                                  Get.snackbar(
                                    'Berhasil',
                                    'Data deteksi telah dihapus.',
                                    snackPosition: SnackPosition.TOP,
                                  );
                                },
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus Data'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Distribusi Ekspresi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (total == 0)
                const Center(
                  child: Text(
                    "Belum ada data deteksi untuk tanggal ini.",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections:
                          counts.entries.map((e) {
                            final percent = (e.value / total * 100)
                                .toStringAsFixed(1);
                            return PieChartSectionData(
                              color:
                                  e.key == 'Drowsy'
                                      ? Colors.redAccent
                                      : e.key == 'Neutral'
                                      ? Colors.blue
                                      : Colors.orange,
                              value: e.value.toDouble(),
                              title: '${e.key}\n$percent%\n${e.value}',
                              radius: 90,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              const Text(
                "List Deteksi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = data[index];
                  return ListTile(
                    leading: Icon(Icons.face, color: AppColor.blue),
                    title: Text('${item['detect']}'),
                    subtitle: Text('${item['date']} ${item['time']}'),
                    trailing: Text('${item['feature']}'),
                  );
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
