import 'package:flutter/material.dart';

import 'app/routes/app_pages.dart';
import 'app/themes/themes.dart';

import 'package:get/get.dart';


void main() async {
    WidgetsFlutterBinding.ensureInitialized();
  
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MobileNet FER',
      debugShowCheckedModeBanner: true,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: ThemeData(
        primaryColor: AppColor.blue,
        primarySwatch: AppPalette.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins',
      ),
    );
  }
}