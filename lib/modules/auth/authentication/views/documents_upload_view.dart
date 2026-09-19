import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextGary.dart';
import '../controllers/signup_controller.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';

class DocumentsuploadView extends StatefulWidget {
  const DocumentsuploadView({super.key});

  @override
  State<DocumentsuploadView> createState() => _DocumentsuploadViewState();
}

class _DocumentsuploadViewState extends State<DocumentsuploadView> {
  late SignupController controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SignupController>()
        ? Get.find<SignupController>()
        : Get.put(SignupController(), permanent: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.showErrors.value = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(title: "Documents Upload"),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 15.h),
                CustomTextgray(
                  text:
                      "Upload required documents & set expiration dates for verification",
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: 24.h),

                // 1. Driving License Card
                _buildUnifiedDocumentCard(
                  context: context,
                  title: "Driving License",
                  isRequired: true,
                  fileRx: controller.licensePlateFile,
                  expireController: controller.licensePlateExpireController,
                ),

                // 2. Hack License Card
                _buildUnifiedDocumentCard(
                  context: context,
                  title: "Hack License",
                  isRequired: true,
                  fileRx: controller.hackLicenseFile,
                  expireController: controller.hackLicenseExpireController,
                ),

                // 3. Local Permit Card
                _buildUnifiedDocumentCard(
                  context: context,
                  title: "Local Permit",
                  isRequired: true,
                  fileRx: controller.localPermitFile,
                  expireController: controller.localPermitExpireController,
                ),

                // 4. Profile Picture Card
                _buildUnifiedDocumentCard(
                  context: context,
                  title: "Profile Picture",
                  isRequired: true,
                  fileRx: controller.profilePictureFile,
                  onlyCamera: true,
                ),

                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFF262626)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFF9EA3AE),
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CustomTextgray(
                          text:
                              "All documents will be reviewed by our admin team. This process typically takes 24-48 hours. You'll be notified via email once approved.",
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                Obx(
                  () => CustomButton(
                    text: "Submit for Review",
                    loading: controller.isLoading.value,
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      controller.showErrors.value = true;
                      final bool isFormValid =
                          _formKey.currentState?.validate() ?? false;
                      if (isFormValid) {
                        controller.submitAccountSetup();
                      }
                    },
                  ),
                ),
                SizedBox(height: 60.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Unified Document & Expiry Card ---
  Widget _buildUnifiedDocumentCard({
    required BuildContext context,
    required String title,
    required bool isRequired,
    required Rx<File?> fileRx,
    TextEditingController? expireController,
    bool onlyCamera = false,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      return Container(
        margin: EdgeInsets.only(bottom: 20.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFF262626), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Icon/Thumbnail + Title + Upload Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                hasFile
                    ? _buildDocumentThumbnail(context, fileRx, title)
                    : _buildIcon(
                        title == "Profile Picture"
                            ? Icons.account_box_outlined
                            : Icons.badge_outlined,
                      ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: CustomText(
                              text: title,
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRequired)
                            const Text(
                              " *",
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      if (hasFile)
                        Text(
                          controller.getFileName(fileRx),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (title == "Profile Picture")
                        CustomTextgray(
                          text:
                              "Black suit, white shirt, tie, white background",
                          fontSize: 11.sp,
                        )
                      else
                        CustomTextgray(
                          text: "No document attached",
                          fontSize: 11.sp,
                        ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 4.h,
                      ),
                      onPressed: () => controller.pickFromCamera(fileRx),
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      tooltip: "Camera",
                    ),
                    if (!onlyCamera) ...[
                      SizedBox(width: 4.w),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        onPressed: () =>
                            controller.pickFromFile(context, fileRx),
                        icon: Icon(
                          Icons.file_upload_outlined,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        tooltip: "Upload File",
                      ),
                    ],
                  ],
                ),
              ],
            ),

            if (controller.showErrors.value && isRequired && !hasFile)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  "Please upload $title",
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),

            // Optional Expiration Date Field
            if (expireController != null) ...[
              SizedBox(height: 14.h),
              const Divider(color: Color(0xFF262626), height: 1),
              SizedBox(height: 14.h),
              _buildFieldLabel("Expiration Date"),
              _buildExpireDateField(context, expireController),
            ],
          ],
        ),
      );
    });
  }

  void _previewLocalImage(BuildContext context, File file, String title) {
    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: file.path.toLowerCase().endsWith('.pdf')
                    ? Container(
                        padding: EdgeInsets.all(24.w),
                        color: const Color(0xFF141414),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 48,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              file.path.split('/').last.split('\\').last,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Image.file(file, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail(
    BuildContext context,
    Rx<File?> fileRx,
    String title,
  ) {
    final file = fileRx.value;
    if (file == null) return const SizedBox.shrink();

    final isImage =
        file.path.toLowerCase().endsWith('.jpg') ||
        file.path.toLowerCase().endsWith('.jpeg') ||
        file.path.toLowerCase().endsWith('.png');

    Widget child = isImage
        ? Image.file(file, fit: BoxFit.cover)
        : const Icon(
            Icons.description_outlined,
            color: Color(0xFFD08700),
            size: 16,
          );

    return GestureDetector(
      onTap: () => _previewLocalImage(context, file, title),
      child: Container(
        width: 38.r,
        height: 38.r,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFF2C2C2C)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: child,
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      padding: EdgeInsets.all(6.r),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Icon(icon, color: Colors.white, size: 16.sp),
    );
  }

  Widget _buildFieldLabel(String text, {bool isRequired = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          CustomText(
            text: text,
            fontWeight: FontWeight.w500,
            fontSize: 12.sp,
            color: const Color(0xFF9EA3AE),
          ),
          if (isRequired)
            const Text(
              " *",
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
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
      style: TextStyle(color: Colors.white, fontSize: 13.sp),
      validator: isRequired
          ? (v) => (v == null || v.isEmpty) ? "Date required" : null
          : null,
      decoration: InputDecoration(
        hintText: "Select Expiry Date",
        hintStyle: TextStyle(color: AppColors.gray100, fontSize: 13.sp),
        errorStyle: TextStyle(color: Colors.red, fontSize: 11.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        suffixIcon: Icon(
          Icons.calendar_month_outlined,
          color: const Color(0xFF9EA3AE),
          size: 18.sp,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
      ),
    );
  }
}
