import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../themes/themes.dart';
import '../../../utils/constant.dart';

import '../controllers/splash_screen_controller.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> {
  final _controller = Get.put(SplashScreenController());

  @override
  void initState() {
    _controller.movePage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: Center(
        child: SizedBox(
          width: Get.width * 0.9,
          height: Get.height * 0.9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                child: Center(
                  child: Image.asset(
                    logo,
                    height: 220,
                    width: 220,
                  ),
                ),
              ),
              const SizedBox(height: 200),
              const CircularProgressIndicator(
                backgroundColor: AppColor.grey,
                color: AppColor.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
