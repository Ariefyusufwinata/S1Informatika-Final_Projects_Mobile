import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../themes/themes.dart';
import '../../../utils/utils.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
  final _controller = Get.put(HomeController());

    return Scaffold(
      backgroundColor: AppColor.white,
      bottomNavigationBar: ConvexAppBar(
        top: 0,
        height: 60,
        color: AppColor.black,
        activeColor: AppColor.blue,
        backgroundColor: AppColor.white,
        style: TabStyle.react,
        items: const [
          TabItem(icon: Icons.home, title: ''),
          TabItem(icon: Icons.analytics, title: ''),
        ],
        initialActiveIndex: 0,
        onTap: (int i) => Utils.changePage(index: i),
      ),
    );
  }
}