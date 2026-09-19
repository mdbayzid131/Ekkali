// ignore: file_names
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/validators.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signup_controller.dart';
import 'package:moeb_26/core/services/vehicle_config_service.dart';
import 'package:moeb_26/data/models/vehicle_model.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';

class VehicleInformationView extends StatefulWidget {
  const VehicleInformationView({super.key});

  @override
  State<VehicleInformationView> createState() => _VehicleInformationViewState();
}

class _VehicleInformationViewState extends State<VehicleInformationView> {
  late SignupController controller;
  late VehicleConfigService vehicleConfigService;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    vehicleConfigService = Get.isRegistered<VehicleConfigService>()
        ? Get.find<VehicleConfigService>()
        : Get.put(VehicleConfigService());

    controller = Get.isRegistered<SignupController>()
        ? Get.find<SignupController>()
        : Get.put(SignupController(), permanent: true);

    if (controller.vehiclesList.isEmpty) {
      controller.vehiclesList.add(VehicleModel());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.showErrors.value = false;
        if (controller.vehiclesList.any((v) => v.isDisposed)) {
          controller.vehiclesList.assignAll([VehicleModel()]);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: const CustomSubAppBar(
            title: "Vehicle Information",
            showBackButton: false,
          ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                CustomTextgray(
                  text: "Add your professional vehicles",
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w400,
                ),
                SizedBox(height: 24.h),

                // Vehicle list
                Expanded(
                  child: ListView(
                    children: [
                      Obx(
                        () => Column(
                          children: List.generate(
                            controller.vehiclesList.length,
                            (index) => _buildVehicleCard(
                              context,
                              index,
                              controller.vehiclesList[index],
                              key: ValueKey(controller.vehiclesList[index].id),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 25.h),
                      CustomAddButton(
                        onPressed: () => controller.addVehicle(),
                      ),
                      SizedBox(height: 30.h),

                      Obx(
                        () => CustomButton(
                          loading: controller.isLoading.value,
                          text: "Continue",
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            controller.showErrors.value = true;
                            final bool isFormValid =
                                _formKey.currentState?.validate() ?? false;
                            if (isFormValid) {
                              controller.submitVehicleInfo();
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 60.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),)
    );
  }

  Widget _buildVehicleCard(
    BuildContext context,
    int index,
    VehicleModel model, {
    Key? key,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF262626), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sleek Vehicle Header Banner
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 20.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "VEHICLE ${index + 1}",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                if (controller.vehiclesList.length > 1)
                  GestureDetector(
                    onTap: () => controller.removeVehicle(index),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 6.h,
                        horizontal: 12.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 16.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
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
            spacing: 12.w,
            runSpacing: 10.h,
            children: [
              _buildVehicleTypeChip(model, "Sedan"),
              _buildVehicleTypeChip(model, "SUV"),
              _buildVehicleTypeChip(model, "Sprinter"),
              _buildVehicleTypeChip(model, "LimoStretch"),
            ],
          ),

          // Validation Error
          Obx(() {
            if (controller.showErrors.value &&
                model.selectedVehicleType.value.isEmpty) {
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
            final type = model.selectedVehicleType.value;
            final cars = vehicleConfigService.getMakesAndModelsForType(type);
            final currentSelection =
                (model.makeController.text.isEmpty &&
                    model.modelController.text.isEmpty)
                ? null
                : "${model.makeController.text} ${model.modelController.text}"
                      .trim();
            final value = cars.contains(currentSelection)
                ? currentSelection
                : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Make & Model"),
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
                            model.makeController.text = parts.first;
                            model.modelController.text = parts
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
                    _buildFieldLabel("Color (Inside)", isRequired: true),
                    _buildTextField(
                      controller: model.colorInsideController,
                      hintText: "Black",
                      validator: (value) => (value == null || value.isEmpty)
                          ? "Enter Color (Inside)"
                          : null,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel("Color (Outside)", isRequired: true),
                    Obx(() {
                      final type = model.selectedVehicleType.value;
                      final colors = vehicleConfigService.getAllowedColorsForType(type);
                      final currentSelection =
                          model.colorOutsideController.text;
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
                            model.colorOutsideController.text = val;
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
                    _buildFieldLabel("Year"),
                    _buildTextField(
                      controller: model.yearController,
                      hintText: "2021",
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final type = model.selectedVehicleType.value;
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
                    _buildFieldLabel("License Plate"),
                    _buildTextField(
                      controller: model.licensePlateController,
                      hintText: "ABC-1234",
                      validator: (value) => (value == null || value.isEmpty)
                          ? "Enter License Plate"
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          _buildUnifiedDocumentCard(
            context: context,
            title: "Commercial Insurance",
            fileRx: model.commercialInsuranceFile,
            expireController: model.commercialInsuranceExpireController,
            isRequired: true,
          ),
          SizedBox(height: 16.h),

          _buildUnifiedDocumentCard(
            context: context,
            title: "Vehicle Registration",
            fileRx: model.vehicleRegistrationFile,
            expireController: model.vehicleRegistrationExpireController,
            isRequired: true,
          ),
          SizedBox(height: 24.h),
          CustomText(
            text: "Vehicle Photos",
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
          ),
          SizedBox(height: 10.h),
          _buildPhotoSection(
            context: context,
            title: "Front View",
            fileRx: model.frontViewFile,
            isRequired: true,
          ),
          SizedBox(height: 12.h),
          _buildPhotoSection(
            context: context,
            title: "Rear View",
            fileRx: model.rearViewFile,
            isRequired: true,
          ),
          SizedBox(height: 12.h),
          _buildPhotoSection(
            context: context,
            title: "Interior View",
            fileRx: model.interiorViewFile,
            isRequired: true,
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildFieldLabel(String text, {bool isRequired = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          CustomText(text: text, fontWeight: FontWeight.w500, fontSize: 13.sp),
          if (isRequired)
            Text(
              " *",
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: AppColors.gray100, fontSize: 14.sp),
        errorStyle: TextStyle(color: Colors.red, fontSize: 11.sp),
        errorMaxLines: 2,
        contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
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
    );
  }

  Widget _buildExpireDateField(
    BuildContext context,
    TextEditingController textController,
  ) {
    return TextFormField(
      controller: textController,
      readOnly: true,
      onTap: () => controller.selectDate(context, textController),
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      validator: (value) =>
          (value == null || value.isEmpty) ? "Date required" : null,
      decoration: InputDecoration(
        hintText: "Select Date",
        hintStyle: TextStyle(color: AppColors.gray100, fontSize: 14.sp),
        errorStyle: TextStyle(color: Colors.red, fontSize: 11.sp),
        errorMaxLines: 2,
        suffixIcon: Icon(
          Icons.calendar_today_outlined,
          color: Colors.white,
          size: 18.sp,
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
    );
  }

  Widget _buildUnifiedDocumentCard({
    required BuildContext context,
    required String title,
    required Rx<File?> fileRx,
    required TextEditingController expireController,
    bool isRequired = true,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      return Container(
        padding: EdgeInsets.all(16.w),
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
                hasFile
                    ? _buildDocumentThumbnail(context, fileRx, title)
                    : _buildIcon(Icons.description_outlined),
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
                      else
                        CustomTextgray(
                          text: "No file attached",
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
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
                    SizedBox(width: 4.w),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 4.h,
                      ),
                      onPressed: () => controller.pickFromFile(context, fileRx),
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
            if (controller.showErrors.value && isRequired && !hasFile)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  "Please upload $title",
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),
            SizedBox(height: 14.h),
            const Divider(color: Color(0xFF262626), height: 1),
            SizedBox(height: 14.h),
            _buildFieldLabel("Expiration Date"),
            _buildExpireDateField(context, expireController),
          ],
        ),
      );
    });
  }

  Widget _buildPhotoSection({
    required BuildContext context,
    required String title,
    required Rx<File?> fileRx,
    bool isRequired = false,
  }) {
    return Obx(() {
      final hasFile = fileRx.value != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFF2C2C2C), width: 1.2),
            ),
            child: Row(
              children: [
                hasFile
                    ? _buildDocumentThumbnail(context, fileRx, title)
                    : _buildIcon(Icons.image_outlined),
                SizedBox(width: 10.w),
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
                      if (hasFile)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            controller.getFileName(fileRx),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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

  Widget _buildVehicleTypeChip(VehicleModel model, String type) {
    return Obx(() {
      final selectedType = model.selectedVehicleType.value;
      final isSelected =
          selectedType.toLowerCase().trim() == type.toLowerCase().trim();
      return GestureDetector(
        onTap: () {
          if (model.isDisposed) return;
          if (model.selectedVehicleType.value != type) {
            model.selectedVehicleType.value = type;
            if (!model.isDisposed) model.makeController.clear();
            if (!model.isDisposed) model.modelController.clear();
            if (!model.isDisposed) model.yearController.clear();
            final allowedColors =
                vehicleConfigService.getAllowedColorsForType(type);
            if (allowedColors.length == 1) {
              if (!model.isDisposed) {
                model.colorOutsideController.text = allowedColors.first;
              }
            } else {
              if (!model.isDisposed) model.colorOutsideController.clear();
            }
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
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
            text: type,
            color: Colors.white,
            fontSize: 13.sp,
          ),
        ),
      );
    });
  }
}

class CustomAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CustomAddButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Color(0xFFFAC0C0), size: 20),
            SizedBox(width: 8.w),
            const Text(
              'Add Another Vehicle',
              style: TextStyle(
                color: Color(0xFFFAC0C0),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

