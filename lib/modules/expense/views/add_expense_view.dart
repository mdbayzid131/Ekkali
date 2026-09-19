import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/expense_controller.dart';
import '../models/expense_model.dart';
import 'expense_detail_sheet.dart';

class AddExpenseView extends StatelessWidget {
  static const Color cardColor = Color(0xFF111111);
  final ExpenseController controller = Get.find<ExpenseController>();
  final _formKey = GlobalKey<FormState>();
  final ExpenseModel? expenseToEdit;

  AddExpenseView({super.key, this.expenseToEdit}) {
    if (expenseToEdit != null) {
      controller.loadExpenseForEdit(expenseToEdit!);
    } else {
      controller.clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = AppColors.black100;
    const borderColor = Color(0xFF1E1E1E);
    const accentColor = AppColors.primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
          ),
          child: AppBar(
            backgroundColor: backgroundColor,
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
              expenseToEdit != null ? "Edit Expense" : "Add New Expense",
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
      body: Obx(() {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.r),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Field
                  _buildFieldLabel("Category"),
                  PopupMenuButton<String>(
                    offset: Offset(0, 52.h),
                    color: const Color(0xFF1E1E20),
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: borderColor.withValues(alpha: 0.3),
                      ),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: 240
                          .w, // Controls the width of the popup menu to keep it compact
                      maxHeight: 280
                          .h, // Controls the height of the popup menu to keep it compact
                    ),
                    onSelected: (val) {
                      controller.setCategory(val);
                    },
                    itemBuilder: (context) {
                      return controller.categories.map((cat) {
                        return PopupMenuItem<String>(
                          value: cat,
                          height: 38.h,
                          child: Row(
                            children: [
                              Icon(
                                _getCategoryIcon(cat),
                                color: const Color(0xFFFFDCA1),
                                size: 16.sp,
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: Text(
                                  cat,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 16.w,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getCategoryIcon(
                                  controller.selectedCategory.value,
                                ),
                                color: const Color(0xFFFFDCA1),
                                size: 18.sp,
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                controller.selectedCategory.value,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFFFDCA1),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Amount Field
                  _buildFieldLabel("Amount (\$)"),
                  TextFormField(
                    controller: controller.amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    decoration: _buildInputDecoration(
                      "Enter amount e.g. 50.00",
                      borderColor,
                      accentColor,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Amount is required";
                      }
                      if (double.tryParse(val) == null ||
                          double.parse(val) <= 0) {
                        return "Enter a valid positive amount";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),

                  // Date Field
                  _buildFieldLabel("Date"),
                  TextFormField(
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: controller.selectedDate.value,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFFFDCA1),
                                onPrimary: Colors.black,
                                surface: Color(0xFF1E1E1E),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        controller.setDate(picked);
                      }
                    },
                    controller: TextEditingController(
                      text: DateFormat(
                        'dd MMM yyyy',
                      ).format(controller.selectedDate.value),
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    decoration:
                        _buildInputDecoration(
                          "Select Date",
                          borderColor,
                          accentColor,
                        ).copyWith(
                          suffixIcon: Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white,
                            size: 18.sp,
                          ),
                        ),
                  ),
                  SizedBox(height: 20.h),

                  // Description Field
                  _buildFieldLabel("Description (Optional)"),
                  TextFormField(
                    controller: controller.descriptionController,
                    maxLines: 3,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    decoration: _buildInputDecoration(
                      "Add description/notes...",
                      borderColor,
                      accentColor,
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Receipt Attachment
                  _buildFieldLabel("Receipt Attachment (Optional)"),
                  Obx(() {
                    final file = controller.selectedImage.value;
                    final networkUrl = controller.existingImageUrl.value;

                    if (file != null) {
                      return GestureDetector(
                        onTap: () => ExpenseDetailSheet.showFullScreenReceipt(
                          context,
                          file.path,
                        ),
                        child: Container(
                          height: 150.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: borderColor),
                            image: DecorationImage(
                              image: FileImage(file),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        "Tap to view",
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => controller.downloadReceiptImage(file.path),
                                      child: Container(
                                        margin: EdgeInsets.only(top: 8.r, bottom: 8.r, right: 4.r),
                                        padding: EdgeInsets.all(6.r),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.file_download_outlined,
                                          color: AppColors.primaryColor,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          controller.selectedImage.value = null,
                                      child: Container(
                                        margin: EdgeInsets.all(8.r),
                                        padding: EdgeInsets.all(6.r),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                          size: 18.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (networkUrl != null && networkUrl.isNotEmpty) {
                      return GestureDetector(
                        onTap: () => ExpenseDetailSheet.showFullScreenReceipt(
                          context,
                          networkUrl,
                        ),
                        child: Container(
                          height: 150.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: borderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    networkUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.grey,
                                          size: 40.sp,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 14.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(30.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 18.sp,
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          "Tap to view",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => controller.downloadReceiptImage(networkUrl),
                                        child: Container(
                                          margin: EdgeInsets.only(top: 8.r, bottom: 8.r, right: 4.r),
                                          padding: EdgeInsets.all(6.r),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.file_download_outlined,
                                            color: AppColors.primaryColor,
                                            size: 18.sp,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () =>
                                            controller.existingImageUrl.value = null,
                                        child: Container(
                                          margin: EdgeInsets.all(8.r),
                                          padding: EdgeInsets.all(6.r),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                            size: 18.sp,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildAttachmentButton(
                              icon: Icons.camera_alt_outlined,
                              label: "Camera",
                              borderColor: borderColor,
                              onTap: () =>
                                  controller.pickImage(ImageSource.camera),
                            ),
                          ),
                          SizedBox(width: 15.w),
                          Expanded(
                            child: _buildAttachmentButton(
                              icon: Icons.photo_library_outlined,
                              label: "Gallery",
                              borderColor: borderColor,
                              onTap: () =>
                                  controller.pickImage(ImageSource.gallery),
                            ),
                          ),
                        ],
                      );
                    }
                  }),
                  SizedBox(height: 40.h),

                  // Submit Button
                  CustomButton(
                    text: expenseToEdit != null
                        ? "Update Expense"
                        : "Add Expense",
                    loading: controller.isLoading.value,
                    backgroundColor: accentColor,
                    textColor: Colors.black,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (expenseToEdit != null) {
                          controller.updateExpense(expenseToEdit!);
                        } else {
                          controller.addExpense();
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFD5C4AB),
          fontSize: 13.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    Color borderColor,
    Color accentColor,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF4B5563),
        fontSize: 13.sp,
      ),
      errorStyle: TextStyle(color: Colors.redAccent, fontSize: 11.sp),
      contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Fuel':
        return Icons.local_gas_station_rounded;
      case 'Oil Changes':
        return Icons.oil_barrel_rounded;
      case 'Tires':
        return Icons.tire_repair_rounded;
      case 'Maintenance & Repairs':
        return Icons.handyman_rounded;
      case 'Car Washes & Detailing':
        return Icons.local_car_wash_rounded;
      case 'Insurance':
        return Icons.security_rounded;
      case 'Toll Expenses':
        return Icons.toll_rounded;
      case 'Parking':
        return Icons.local_parking_rounded;
      case 'Vehicle Payments':
        return Icons.monetization_on_rounded;
      case 'Phone & Internet':
        return Icons.phone_android_rounded;
      case 'Water & Snacks for Clients':
        return Icons.local_cafe_rounded;
      case 'Client Amenities':
        return Icons.card_giftcard_rounded;
      case 'Cleaning Supplies':
        return Icons.cleaning_services_rounded;
      case 'Licenses & Permits':
        return Icons.badge_rounded;
      case 'Business Insurance':
        return Icons.business_center_rounded;
      case 'Marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
          color: cardColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
