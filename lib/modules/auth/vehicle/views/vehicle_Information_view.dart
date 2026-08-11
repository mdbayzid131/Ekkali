import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/validators.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signup_controller.dart';
import 'package:moeb_26/data/models/vehicle_model.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';

class VehicleInformationView extends StatelessWidget {
  VehicleInformationView({super.key});

  // Using the unified SignupController
  final SignupController controller = Get.find<SignupController>();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1.5),
              ),
            ),
            child: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20.sp,
                ),
                onPressed: () => Get.back(),
              ),
              title: Text(
                'Vehicle Information',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                  child: Obx(
                    () => ListView(
                      children: [
                        ...List.generate(
                          controller.vehiclesList.length,
                          (index) => _buildVehicleCard(
                            context,
                            index,
                            controller.vehiclesList[index],
                          ),
                        ),

                        SizedBox(height: 25.h),
                        CustomAddButton(
                          onPressed: () => controller.addVehicle(),
                        ),
                        SizedBox(height: 30.h),

                        CustomButton(
                          text: "Continue",
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            Get.toNamed(Routes.documentsuploadView);
                          },
                        ),
                        SizedBox(height: 60.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Vehicle Card ---
  Widget _buildVehicleCard(
    BuildContext context,
    int index,
    VehicleModel model,
  ) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.black200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(text: "Vehicle ${index + 1}", fontSize: 15.sp),
              if (controller.vehiclesList.length > 1)
                GestureDetector(
                  onTap: () => controller.removeVehicle(index),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 15.w,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black200,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: AppColors.black200, width: 1),
                    ),
                    child: Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
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
            final cars = vehicleMakeModelMap[type] ?? [];
            final currentSelection =
                (model.makeController.text.isEmpty &&
                        model.modelController.text.isEmpty)
                    ? null
                    : "${model.makeController.text} ${model.modelController.text}"
                        .trim();
            final value =
                cars.contains(currentSelection) ? currentSelection : null;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel("Make & Model"),
                DropdownButtonFormField<String>(
                  key: ValueKey(type),
                  value: value,
                  dropdownColor: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16.r),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFD5C4AB),
                    size: 22,
                  ),
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
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
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
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
                      borderSide: const BorderSide(color: Color(0xFFD08700), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
                            model.modelController.text =
                                parts.sublist(1).join(' ');
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
                    _buildFieldLabel("Color (Inside)", isRequired: false),
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
                    _buildFieldLabel("Color (Outside)", isRequired: false),
                    Obx(() {
                      final type = model.selectedVehicleType.value;
                      final isLimo = type == "LimoStretch";
                      final colors = isLimo ? ["Black", "White"] : ["Black"];

                      // Auto-populate "Black" for non-limo
                      if (!isLimo &&
                          model.colorOutsideController.text != "Black") {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          model.colorOutsideController.text = "Black";
                        });
                      }

                      final currentSelection =
                          model.colorOutsideController.text;
                      final value = colors.contains(currentSelection)
                          ? currentSelection
                          : null;

                      return DropdownButtonFormField<String>(
                        key: ValueKey(type),
                        value: value,
                        dropdownColor: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16.r),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFFD5C4AB),
                          size: 22,
                        ),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Select Color"
                            : null,
                        decoration: InputDecoration(
                          hintText: "Select Color",
                          hintStyle: TextStyle(
                            color: AppColors.gray100,
                            fontSize: 14.sp,
                          ),
                          errorStyle:
                              TextStyle(color: Colors.red, fontSize: 11.sp),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14.h,
                            horizontal: 16.w,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                const BorderSide(color: AppColors.black200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                const BorderSide(color: AppColors.black200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                const BorderSide(color: Color(0xFFD08700), width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                const BorderSide(color: Color(0xFFEF4444)),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            borderSide:
                                const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
                        final maxAge = (type == "LimoStretch") ? 15 : 5;
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

          _buildFileSection(
            context: context,
            title: "Commercial Insurance",
            fileRx: model.commercialInsuranceFile,
            isRequired: true,
          ),
          SizedBox(height: 16.h),
          _buildFieldLabel("Expire Date"),
          _buildExpireDateField(
            context,
            model.commercialInsuranceExpireController,
          ),

          SizedBox(height: 24.h),

          _buildFileSection(
            context: context,
            title: "Vehicle Registration",
            fileRx: model.vehicleRegistrationFile,
            isRequired: true,
          ),
          SizedBox(height: 16.h),
          _buildFieldLabel("Expire Date"),
          _buildExpireDateField(
            context,
            model.vehicleRegistrationExpireController,
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
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
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

  Widget _buildFileSection({
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
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.black200),
            ),
            child: Row(
              children: [
                _buildIcon(Icons.description_outlined),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: title,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.sp,
                      ),
                      if (hasFile)
                        Text(
                          controller.getFileName(fileRx),
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11.sp,
                          ),
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
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.black200),
            ),
            child: Row(
              children: [
                _buildIcon(Icons.image_outlined),
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
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Icon(icon, color: Colors.white, size: 20.sp),
    );
  }

  Widget _buildVehicleTypeChip(VehicleModel model, String type) {
    return Obx(() {
      bool isSelected = model.selectedVehicleType.value == type;
      return GestureDetector(
        onTap: () {
          if (model.selectedVehicleType.value != type) {
            model.selectedVehicleType.value = type;
            model.makeController.clear();
            model.modelController.clear();
            model.yearController.clear();
            if (type != "LimoStretch") {
              model.colorOutsideController.text = "Black";
            } else {
              model.colorOutsideController.clear();
            }
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF181F26) : Colors.transparent,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: const Color(0xFF364153)),
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

const Map<String, List<String>> vehicleMakeModelMap = {
  "Sedan": [
    "Mercedes-Benz S-Class",
    "Mercedes-Benz E-Class",
    "Mercedes-Benz GLE",
    "BMW 7 Series",
    "BMW 5 Series",
    "BMW X7",
    "BMW X5",
    "Audi A8",
    "Audi A6",
    "Audi Q5",
    "Audi Q7",
    "Genesis G90",
    "Genesis GV80",
    "Cadillac CT5",
    "Cadillac XT6",
    "Lincoln Aviator",
    "Lincoln Nautilus",
    "Volvo S90",
    "Volvo XC90",
  ],
  "SUV": [
    "Chevrolet Suburban",
    "GMC Yukon XL",
    "Cadillac Escalade",
    "Lincoln Navigator L",
    "Ford Expedition MAX",
    "Jeep Grand Wagoneer L",
  ],
  "Sprinter": [
    "Mercedes-Benz Sprinter",
  ],
  "LimoStretch": [
    "Chrysler 300 Stretch",
    "Lincoln MKT Stretch",
    "Lincoln Town Car Stretch",
    "Lincoln Continental",
    "Cadillac XTS Stretch",
    "Cadilac XT5 Stretch",
    "Cadillac Escalade Stretch",
    "Hummer H2 Stretch",
    "Lincoln Navigator Stretch",
  ],
};
