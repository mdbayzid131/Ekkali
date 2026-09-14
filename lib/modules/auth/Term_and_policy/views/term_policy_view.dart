import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/legal_content_controller.dart';

class TermPolicyView extends StatelessWidget {
  TermPolicyView({super.key});

  final controller = Get.isRegistered<LegalContentController>()
      ? Get.find<LegalContentController>()
      : Get.put(LegalContentController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 22.sp),
        ),
        title: Obx(
          () => Text(
            controller.title.value.isEmpty
                ? "Legal Page"
                : controller.title.value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (controller.content.value.isEmpty) {
            return Center(
              child: Text(
                "No content available",
                style: GoogleFonts.inter(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: HtmlWidget(
              controller.content.value,
              textStyle: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14.sp,
              ),
              customStylesBuilder: (element) {
                if (element.localName == 'h1') {
                  return {
                    'color': 'white',
                    'font-weight': 'bold',
                    'font-size': '24px',
                  };
                }
                if (element.localName == 'h2') {
                  return {
                    'color': 'white',
                    'font-weight': 'bold',
                    'font-size': '20px',
                  };
                }
                return null;
              },
            ),
          );
        }),
      ),
    );
  }
}
