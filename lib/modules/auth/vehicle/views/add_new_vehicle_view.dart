import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/utils/validators.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import 'package:moeb_26/core/services/vehicle_config_service.dart';
import 'package:moeb_26/modules/auth/vehicle/controllers/vehicle_action_controller.dart';

class AddNewVehicleView extends StatefulWidget {
  const AddNewVehicleView({super.key});

  @override
  State<AddNewVehicleView> createState() => _AddNewVehicleViewState();
}

class _AddNewVehicleViewState extends State<AddNewVehicleView> {
  // Use a unique tag for each navigation to ensure NO data leaks from previous visits
  late final String tag;
  late final VehicleActionController controller;
  late final VehicleConfigService vehicleConfigService;

  final _formKey = GlobalKey<FormState>();
  final RxBool showErrors = false.obs;

  @override
  void initState() {
    super.initState();
    // Generate a fresh unique tag each time this screen is opened
    tag = DateTime.now().millisecondsSinceEpoch.toString();
    // Inject a completely fresh and unique controller instance
    controller = Get.put(VehicleActionController(), tag: tag);
    vehicleConfigService = Get.isRegistered<VehicleConfigService>()
        ? Get.find<VehicleConfigService>()
        : Get.put(VehicleConfigService());
  }

  @override
  void dispose() {
    // Delete the controller when leaving the screen
    Get.delete<VehicleActionController>(tag: tag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Obx(
          () => CustomSubAppBar(
            title: controller.isEditMode.value
                ? "Edit Vehicle"
                : "Add New Vehicle",
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                _buildVehicleForm(context),
                SizedBox(height: 30.h),
                Obx(
                  () => CustomButton(
                    loading: controller.isLoading.value,
                    text: controller.isEditMode.value
                        ? "Update Vehicle"
                        : "Add Vehicle",
                    onPressed: () {
                      showErrors.value = true;
                      if (_formKey.currentState!.validate()) {
                        if (controller
                            .selectedVehicleType
                            .value
                            .isEmpty) {
                          Helpers.showCustomSnackBar(
                            "Please select a vehicle type",
                            isError: true,
                          );
                          return;
                        }
                        controller.submitVehicle();
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

  Widget _buildVehicleForm(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF262626), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomText(
                text: "Vehicle Type",
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
                color: AppColors.gray100,
              ),
              Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Vehicle Type Chips
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _buildVehicleTypeChip("Sedan"),
              _buildVehicleTypeChip("SUV"),
              _buildVehicleTypeChip("Sprinter"),
              _buildVehicleTypeChip("LimoStretch"),
            ],
          ),

          // Vehicle type validation error
          Obx(() {
            if (showErrors.value &&
                controller.selectedVehicleType.value.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(left: 4.w, top: 6.h),
                child: Text(
                  'Select a Vehicle Type',
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          SizedBox(height: 20.h),
          // Make & Model Dropdown Selection
          Obx(() {
            final type = controller.selectedVehicleType.value;
            final cars = vehicleConfigService.getMakesAndModelsForType(type);
            final currentSelection =
                (controller.makeController.text.isEmpty &&
                    controller.modelController.text.isEmpty)
                ? null
                : "${controller.makeController.text} ${controller.modelController.text}"
                      .trim();
            final value = cars.contains(currentSelection)
                ? currentSelection
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomText(
                      text: "Make & Model",
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                    Text(
                      " *",
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                DropdownButtonFormField<String>(
                  key: ValueKey("${type}_${cars.length}"),
                  value: value,
                  dropdownColor: const Color(0xFF1A1A1E),
                  menuMaxHeight: 260.h,
                  borderRadius: BorderRadius.circular(16.r),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFD5C4AB),
                    size: 22,
                  ),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? "Select Make & Model"
                      : null,
                  decoration: InputDecoration(
                    hintText: type.isEmpty
                        ? "Select Vehicle Type First"
                        : "Select Make & Model",
                    hintStyle: TextStyle(
                      color: AppColors.gray100,
                      fontSize: 14.sp,
                    ),
                    errorStyle: TextStyle(color: Colors.red, fontSize: 11.sp),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14.h,
                      horizontal: 16.w,
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.black200),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: AppColors.black200),
                    ),
                  ),
                  items: cars.map((car) {
                    return DropdownMenuItem<String>(
                      value: car,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Text(
                          car,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: type.isEmpty
                      ? null
                      : (val) {
                          if (val != null) {
                            final parts = val.split(' ');
                            controller.makeController.text = parts.first;
                            controller.modelController.text = parts
                                .sublist(1)
                                .join(' ');
                          }
                        },
                ),
              ],
            );
          }),
          SizedBox(height: 15.h),
          // Row 2: Color (Inside) & Color (Outside)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          text: "Color (Inside)",
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.colorInsideController,
                      hintText: "Black",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter Color (Inside)";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          text: "Color (Outside)",
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Obx(() {
                      final type = controller.selectedVehicleType.value;
                      final colors = vehicleConfigService.getAllowedColorsForType(type);

                      // Auto-populate first allowed color if only 1 color is allowed and current text doesn't match
                      if (colors.length == 1 &&
                          controller.colorOutsideController.text != colors.first) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          controller.colorOutsideController.text = colors.first;
                        });
                      }

                      final currentSelection =
                          controller.colorOutsideController.text;
                      final value = colors.contains(currentSelection)
                          ? currentSelection
                          : (colors.length == 1 ? colors.first : null);

                      return DropdownButtonFormField<String>(
                        key: ValueKey("${type}_${colors.join('_')}"),
                        value: value,
                        dropdownColor: const Color(0xFF1A1A1E),
                        menuMaxHeight: 260.h,
                        borderRadius: BorderRadius.circular(16.r),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFD5C4AB),
                          size: 22,
                        ),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Select Color"
                            : null,
                        decoration: InputDecoration(
                          hintText: "Select Color",
                          hintStyle: TextStyle(
                            color: AppColors.gray100,
                            fontSize: 14.sp,
                          ),
                          errorStyle: TextStyle(
                            color: Colors.red,
                            fontSize: 11.sp,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14.h,
                            horizontal: 16.w,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.black200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.black200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.black200,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.black200,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide: const BorderSide(
                              color: AppColors.black200,
                            ),
                          ),
                        ),
                        items: colors.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              child: Text(
                                c,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.colorOutsideController.text = val;
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          // Row 3: Year & License Plate
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          text: "Year",
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                        Text(
                          " *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.yearController,
                      hintText: "2021",
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final type = controller.selectedVehicleType.value;
                        final maxAge = vehicleConfigService.getMaxAgeForType(type);
                        return Validators.year(
                          value,
                          min: DateTime.now().year - maxAge,
                          max: DateTime.now().year,
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomText(
                          text: "License Plate",
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp,
                        ),
                        Text(
                          " *",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _buildTextField(
                      controller: controller.licensePlateController,
                      hintText: "ABC-1234",
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return "Enter License Plate";
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          /// Commercial Insurance
          _buildUnifiedDocumentCard(
            context: context,
            title: "Commercial Insurance",
            isRequired: true,
            fileRx: controller.commercialInsuranceFile,
            urlRx: controller.commercialInsuranceUrl,
            expireController: controller.commercialInsuranceExpireController,
          ),
          SizedBox(height: 20.h),

          /// Vehicle Registration
          _buildUnifiedDocumentCard(
            context: context,
            title: "Vehicle Registration",
            isRequired: true,
            fileRx: controller.vehicleRegistrationFile,
            urlRx: controller.vehicleRegistrationUrl,
            expireController: controller.vehicleRegistrationExpireController,
          ),
          SizedBox(height: 24.h),

          /// Vehicle Photos
          Row(
            children: [
              CustomText(
                text: "Vehicle Photos",
                fontWeight: FontWeight.w600,
                fontSize: 15.sp,
              ),
              Text(
                " *",
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          /// Front View
          _buildPhotoSection(
            context: context,
            title: "Front View",
            fileRx: controller.frontViewFile,
            urlRx: controller.frontViewUrl,
          ),
          SizedBox(height: 12.h),

          /// Rear View
          _buildPhotoSection(
            context: context,
            title: "Rear View",
            fileRx: controller.rearViewFile,
            urlRx: controller.rearViewUrl,
          ),
          SizedBox(height: 12.h),

          /// Interior View
          _buildPhotoSection(
            context: context,
            title: "Interior View",
            fileRx: controller.interiorViewFile,
            urlRx: controller.interiorViewUrl,
          ),
        ],
      ),
    );
  }

  // ========== UI Helpers ==========

  Widget _buildUnifiedDocumentCard({
    required BuildContext context,
    required String title,
    required bool isRequired,
    required Rx<File?> fileRx,
    required RxnString urlRx,
    required TextEditingController expireController,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      final hasUrl = urlRx.value != null && urlRx.value!.isNotEmpty;
      final canPreview = hasFile || hasUrl;
      final showError = showErrors.value && isRequired && !hasFile && !hasUrl;

      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF262626),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                canPreview
                    ? _buildDocumentThumbnail(context, fileRx, urlRx, title)
                    : _buildDocumentIcon(),
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
                      else if (hasUrl)
                        Text(
                          "Current file on record",
                          style: TextStyle(
                            color: const Color(0xFF9EA3AE),
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        CustomTextgray(
                          text: "PDF, JPG, PNG",
                          fontSize: 11.sp,
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                      onPressed: () => controller.pickFromCamera(fileRx),
                      icon: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      tooltip: "Camera",
                    ),
                    SizedBox(width: 2.w),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
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
                ),
              ],
            ),
            if (showError)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  "Please upload $title",
                  style: TextStyle(color: Colors.redAccent, fontSize: 12.sp),
                ),
              ),
            SizedBox(height: 14.h),
            const Divider(color: Color(0xFF262626), height: 1),
            SizedBox(height: 14.h),
            Row(
              children: [
                CustomText(
                  text: "Expiration Date",
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                  color: const Color(0xFF9EA3AE),
                ),
                if (isRequired)
                  Text(
                    " *",
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            _buildExpireDateField(
              context: context,
              textController: expireController,
              hintText: "Select Expiration Date",
              validator: (value) {
                if (value == null || value.isEmpty) return "Enter expire date";
                return null;
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildDocumentSection({
    required BuildContext context,
    required String title,
    required bool isRequired,
    required Rx<File?> fileRx,
    required RxnString urlRx,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      final hasUrl = urlRx.value != null && urlRx.value!.isNotEmpty;
      final canPreview = hasFile || hasUrl;
      final showError = showErrors.value && isRequired && !hasFile && !hasUrl;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CustomContainer(
            child: Row(
              children: [
                canPreview
                    ? _buildDocumentThumbnail(context, fileRx, urlRx, title)
                    : _buildDocumentIcon(),
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
                              fontWeight: FontWeight.w500,
                              fontSize: 14.sp,
                            ),
                          ),
                          if (isRequired)
                            Text(
                              " *",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14.sp,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      if (hasFile)
                        Text(
                          controller.getFileName(fileRx),
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (hasUrl)
                         Text(
                          "Current file on record",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11.sp,
                          ),
                        )
                      else
                        CustomTextgray(
                          text: "PDF, JPG, PNG",
                          fontSize: 11.sp,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.pickFromCamera(fileRx),
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                IconButton(
                  onPressed: () => controller.pickFromFile(context, fileRx),
                  icon: Icon(
                    Icons.file_upload_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
          if (showError)
            Padding(
              padding: EdgeInsets.only(left: 4.w, top: 6.h),
              child: Text(
                "Please upload $title",
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildPhotoSection({
    required BuildContext context,
    required String title,
    required Rx<File?> fileRx,
    required RxnString urlRx,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      final hasUrl = urlRx.value != null && urlRx.value!.isNotEmpty;
      final canPreview = hasFile || hasUrl;
      final showError = showErrors.value && !hasFile && !hasUrl;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CustomContainer(
            child: Row(
              children: [
                canPreview
                    ? _buildDocumentThumbnail(context, fileRx, urlRx, title)
                    : _buildDocumentIconPhoto(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: title,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                      SizedBox(height: 4.h),
                      if (hasFile)
                        Text(
                          controller.getFileName(fileRx),
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (hasUrl)
                         Text(
                          "Current photo on record",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11.sp,
                          ),
                        )
                      else
                        CustomTextgray(
                          text: "No photo attached",
                          fontSize: 11.sp,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => controller.pickFromCamera(fileRx),
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
          if (showError)
            Padding(
              padding: EdgeInsets.only(left: 4.w, top: 6.h),
              child: Text(
                "Please upload $title",
                style: TextStyle(color: Colors.red, fontSize: 12.sp),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildExpireDateField({
    required BuildContext context,
    required TextEditingController textController,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: textController,
      readOnly: true,
      onTap: () => controller.selectDate(context, textController),
      validator: validator,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.gray100, fontSize: 14.sp),
        errorStyle: TextStyle(color: Colors.red, fontSize: 11.sp),
        errorMaxLines: 2,
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          color: Colors.white,
          size: 18.sp,
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: AppColors.black200),
        ),
      ),
    );
  }

  Widget _buildDocumentIcon() {
    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2939),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(Icons.description_outlined, color: Colors.white, size: 16.sp),
    );
  }

  Widget _buildDocumentIconPhoto() {
    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFF2C2C2C)),
      ),
      child: Icon(Icons.image_outlined, color: Colors.white, size: 16.sp),
    );
  }

  Widget _buildVehicleTypeChip(String vehicleType) {
    return Obx(() {
      final selectedType = controller.selectedVehicleType.value;
      final isSelected =
          selectedType.toLowerCase().trim() == vehicleType.toLowerCase().trim();
      return GestureDetector(
        onTap: () {
          if (controller.selectedVehicleType.value != vehicleType) {
            controller.makeController.clear();
            controller.modelController.clear();
            controller.yearController.clear();
            final allowedColors =
                vehicleConfigService.getAllowedColorsForType(vehicleType);
            if (allowedColors.length == 1) {
              controller.colorOutsideController.text = allowedColors.first;
            } else {
              controller.colorOutsideController.clear();
            }
            controller.selectedVehicleType.value = vehicleType;
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 15.w),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF181F26) : Colors.transparent,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFDCA1)
                  : const Color(0xFF364153),
            ),
          ),
          child: CustomTextgray(
            text: vehicleType,
            color: Colors.white,
            fontSize: 14.sp,
          ),
        ),
      );
    });
  }

  // ignore: non_constant_identifier_names
  Widget _CustomContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.black200),
      ),
      child: child,
    );
  }

  Widget _buildDocumentThumbnail(
    BuildContext context,
    Rx<File?> fileRx,
    RxnString urlRx,
    String title,
  ) {
    final file = fileRx.value;
    final url = urlRx.value;
    final hasLocal = file != null;
    final hasUrl = url != null && url.isNotEmpty;

    final isLocalImage = hasLocal &&
        (file.path.toLowerCase().endsWith('.jpg') ||
            file.path.toLowerCase().endsWith('.jpeg') ||
            file.path.toLowerCase().endsWith('.png'));

    final isNetworkImage = hasUrl &&
        (url.toLowerCase().contains('.jpg') ||
            url.toLowerCase().contains('.jpeg') ||
            url.toLowerCase().contains('.png') ||
            url.toLowerCase().startsWith('http'));

    Widget child;
    if (isLocalImage) {
      child = Image.file(file, fit: BoxFit.cover);
    } else if (isNetworkImage) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.description_outlined,
            color: Color(0xFFD08700),
            size: 16,
          );
        },
      );
    } else {
      child = const Icon(
        Icons.description_outlined,
        color: Color(0xFFD08700),
        size: 16,
      );
    }

    return GestureDetector(
      onTap: () => controller.previewImage(context, fileRx, urlRx, title: title),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.gray100, fontSize: 14.sp),
          errorStyle: TextStyle(color: Colors.red, fontSize: 11.sp),
          errorMaxLines: 2,
          contentPadding: EdgeInsets.symmetric(
            vertical: 12.h,
            horizontal: 12.w,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.black200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.black200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.black200),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.black200),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.black200),
          ),
        ),
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
    );
  }
}
