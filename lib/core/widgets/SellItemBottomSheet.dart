import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/modules/market_place/controllers/market_place_controller.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';

class SellItemBottomSheet extends StatelessWidget {
  final String? editItemId;

  SellItemBottomSheet({super.key, this.editItemId});

  final MarketplaceController controller = Get.find<MarketplaceController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0B), // Black background as per image
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2632), // Dark blue header
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    editItemId == null ? "Item Description" : "Edit Item",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    20.h,
                    20.w,
                    MediaQuery.of(context).viewInsets.bottom + 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Item Title *"),
                      //dete hobe
                      _buildTextField(
                        textInputType: TextInputType.text,
                        controller: controller.titleController,
                        hint: "e.g., Professional Car Phone Mount",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Title is required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),

                      _buildLabel("Price *"),
                      //dete hobe
                      _buildTextField(
                        textInputType: TextInputType.number,
                        controller: controller.priceController,
                        hint: "\$50",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Price is required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),

                      _buildLabel("Condition (Optional)"),
                      Obx(
                        () => Wrap(
                          spacing: 10.w,
                          runSpacing: 10.h,
                          children: controller.conditions.map((condition) {
                            bool isSelected =
                                controller.selectedCondition.value == condition;
                            return GestureDetector(
                              onTap: () =>
                                  controller.updateCondition(condition),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1E2632)
                                      : const Color(0xFF1A1A1A),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF323B49)
                                        : const Color(0xFF242424),
                                  ),
                                ),
                                child: Text(
                                  condition,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      _buildLabel("Location *"),
                      //dete hobe
                      _buildTextField(
                        textInputType: TextInputType.text,
                        controller: controller.locationController,
                        hint: "Manhattan, NY",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Location is required";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),

                      _buildLabel("Description (Optional)"),
                      //dete hobe
                      _buildTextField(
                        controller: controller.descriptionController,
                        hint:
                            "Describe the item, its features, and condition...",
                        maxLines: 4,
                      ),
                      SizedBox(height: 20.h),

                      _buildLabel("Photos (Optional)"),
                      Obx(() {
                        final newImages = controller.selectedImages;
                        final existingImages = controller.existingImagePaths;

                        if (newImages.isEmpty && existingImages.isEmpty) {
                          return GestureDetector(
                            onTap: () =>
                                controller.showPhotoSelectionDialog(context),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 40.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.file_upload_outlined,
                                    color: Colors.grey,
                                    size: 32.sp,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    "Upload or take Photos",
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 100.h,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                existingImages.length + newImages.length + 1,
                            separatorBuilder: (context, index) =>
                                SizedBox(width: 10.w),
                            itemBuilder: (context, index) {
                              // Last item is the "+ Add" button
                              if (index ==
                                  existingImages.length + newImages.length) {
                                return GestureDetector(
                                  onTap: () => controller
                                      .showPhotoSelectionDialog(context),
                                  child: Container(
                                    width: 100.h,
                                    height: 100.h,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: const Color(0xFF242424),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 28.sp,
                                    ),
                                  ),
                                );
                              }

                              // Existing Images first
                              if (index < existingImages.length) {
                                final path = existingImages[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16.r),
                                      child: Image.network(
                                        path,
                                        width: 100.h,
                                        height: 100.h,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4.h,
                                      right: 4.w,
                                      child: GestureDetector(
                                        onTap: () =>
                                            existingImages.removeAt(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: EdgeInsets.all(2.w),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.red,
                                            size: 16.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // Newly selected images
                              final newIndex = index - existingImages.length;
                              final file = newImages[newIndex];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16.r),
                                    child: Image.file(
                                      file,
                                      width: 100.h,
                                      height: 100.h,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4.h,
                                    right: 4.w,
                                    child: GestureDetector(
                                      onTap: () => newImages.removeAt(newIndex),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: EdgeInsets.all(2.w),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 16.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }),
                      SizedBox(height: 30.h),

                      Obx(
                        () => CustomButton(
                          text: editItemId == null
                              ? "List Item"
                              : "Update Item",
                          backgroundColor: AppColors.primaryColor,
                          textColor: Colors.black,
                          loading: controller.isLoading.value,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              controller.listItem(editItemId: editItemId);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    TextInputType textInputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      keyboardType: textInputType,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14.sp),
        filled: true,
        fillColor: Colors.black,
        contentPadding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
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
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
