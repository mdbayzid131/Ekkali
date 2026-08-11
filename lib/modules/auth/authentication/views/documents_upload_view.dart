import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextGary.dart';
import '../controllers/signup_controller.dart';

class DocumentsuploadView extends GetView<SignupController> {
  DocumentsuploadView({super.key});
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.showErrors.value = false;
    });
    return Scaffold(
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50.w),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                SizedBox(height: 50.w),
                CustomText(text: "Documents Upload", fontSize: 20.sp),
                SizedBox(height: 7.h),
                CustomTextgray(
                  text: "Upload required documents for verification",
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: 30.h),

                _buildDocumentSection(
                  context: context,
                  title: "Driving License",
                  isRequired: true,
                  fileRx: controller.licensePlateFile,
                ),
                SizedBox(height: 16.h),
                _buildFieldLabel("Expire Date"),
                _buildExpireDateField(
                  context,
                  controller.licensePlateExpireController,
                ),

                SizedBox(height: 24.h),
                _buildDocumentSection(
                  context: context,
                  title: "Hack License",
                  isRequired: true,
                  fileRx: controller.hackLicenseFile,
                ),
                SizedBox(height: 16.h),
                _buildFieldLabel("Expire Date"),
                _buildExpireDateField(
                  context,
                  controller.hackLicenseExpireController,
                ),

                SizedBox(height: 24.h),
                _buildDocumentSection(
                  context: context,
                  title: "Local Permit",
                  isRequired: true,
                  fileRx: controller.localPermitFile,
                ),
                SizedBox(height: 16.h),
                _buildFieldLabel("Expire Date"),
                _buildExpireDateField(
                  context,
                  controller.localPermitExpireController,
                  isRequired: true,
                ),

                SizedBox(height: 24.h),
                _buildDocumentSection(
                  context: context,
                  title: "Profile Picture",
                  isRequired: true,
                  fileRx: controller.profilePictureFile,
                  onlyCamera: true,
                ),

                SizedBox(height: 30.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2939),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: const CustomTextgray(
                    text:
                        "All documents will be reviewed by our admin team. This process typically takes 24-48 hours. You'll be notified via email once approved.",
                  ),
                ),
                SizedBox(height: 40.h),

                CustomButton(
                  text: "Continue",
                  onPressed: () {
                    Get.toNamed(Routes.privacyPolicySignUpView);
                  },
                ),
                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: CustomText(
        text: text,
        fontWeight: FontWeight.w500,
        fontSize: 13.sp,
      ),
    );
  }

  Widget _buildDocumentSection({
    required BuildContext context,
    required String title,
    required bool isRequired,
    required Rx<File?> fileRx,
    bool onlyCamera = false,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.black200),
            ),
            child: Row(
              children: [
                _buildIcon(
                  title == "Profile Picture"
                      ? Icons.image_outlined
                      : Icons.description_outlined,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomText(
                            text: title,
                            fontWeight: FontWeight.w500,
                            fontSize: 13.sp,
                          ),
                          if (isRequired)
                            const Text(
                              " *",
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      if (hasFile)
                        Text(
                          controller.getFileName(fileRx),
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11.sp,
                          ),
                        )
                      else if (title == "Profile Picture")
                        CustomTextgray(
                          text:
                              "Black suit, white shirt, tie, white background",
                          fontSize: 10.sp,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.pickFromCamera(fileRx),
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                  ),
                ),

                if (!onlyCamera)
                  IconButton(
                    onPressed: () => controller.pickFromFile(context, fileRx),
                    icon: const Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          if (controller.showErrors.value && isRequired && !hasFile)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                "Please upload $title",
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2939),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(icon, color: Colors.white, size: 22.sp),
    );
  }

  Widget _buildExpireDateField(
    BuildContext context,
    TextEditingController textController, {
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: textController,
      readOnly: true,
      onTap: () => controller.selectDate(context, textController),
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      validator: isRequired
          ? (v) => (v == null || v.isEmpty) ? "Date required" : null
          : null,
      decoration: InputDecoration(
        hintText: "Select Expiry Date",
        hintStyle: TextStyle(color: AppColors.gray100, fontSize: 14.sp),
        suffixIcon: Icon(
          Icons.calendar_month,
          color: AppColors.gray100,
          size: 20.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.black200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.black200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: AppColors.black200),
        ),
      ),
    );
  }
}
