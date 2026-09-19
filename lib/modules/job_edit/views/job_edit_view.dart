import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText_Field_Hight.dart';
import '../controllers/job_edit_controller.dart';

class JobEditView extends StatefulWidget {
  const JobEditView({super.key});

  @override
  State<JobEditView> createState() => _JobEditViewState();
}

class _JobEditViewState extends State<JobEditView> {
  final pickupController = TextEditingController();
  final dropoffController = TextEditingController();
  final flightController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final payController = TextEditingController();
  final specialController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final JobEditController controller = Get.find<JobEditController>();

  @override
  void initState() {
    super.initState();
    if (controller.job != null) {
      pickupController.text = controller.job!.pickupLocation ?? '';
      dropoffController.text = controller.job!.dropoffLocation ?? '';
      flightController.text = controller.job!.flightNumber ?? '';
      payController.text =
          controller.job!.paymentAmount?.toString() ?? '';
      specialController.text = controller.job!.instruction ?? '';

      if (controller.job!.date != null && controller.job!.date!.isNotEmpty) {
        dateController.text = controller.job!.date!;
      }
      if (controller.job!.time != null && controller.job!.time!.isNotEmpty) {
        timeController.text = controller.job!.time!;
      }
    }
  }

  @override
  void dispose() {
    pickupController.dispose();
    dropoffController.dispose();
    flightController.dispose();
    dateController.dispose();
    timeController.dispose();
    payController.dispose();
    specialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
              'Edit Job',
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup Location
                _buildFieldWithLabel(
                  label: "Pickup Location",
                  ctrl: pickupController,
                  hint: "e.g., JFK Airport, Terminal 4",
                  icon: SvgPicture.asset(
                    AppIcons.fromlocation_icon,
                    height: 20.sp,
                    width: 20.sp,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Pickup location is required"
                      : null,
                ),

                // Drop-off Location
                _buildFieldWithLabel(
                  label: "Drop-off Location",
                  ctrl: dropoffController,
                  hint: "e.g., Manhattan, Times Square",
                  icon: SvgPicture.asset(
                    AppIcons.fromlocation_icon,
                    height: 20.sp,
                    width: 20.sp,
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Drop-off location is required"
                      : null,
                ),

                // Flight Number (Optional)
                _buildFieldWithLabel(
                  label: "Flight Number (Optional)",
                  ctrl: flightController,
                  hint: "e.g., AA 1234",
                  isRequired: false,
                ),

                // ASAP Checkbox
                Obx(
                  () => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24.h,
                          width: 24.w,
                          child: Checkbox(
                            value: controller.isAsap.value,
                            onChanged: (val) => controller.toggleAsap(val),
                            activeColor: AppColors.black200,
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            visualDensity: const VisualDensity(
                              horizontal: VisualDensity.minimumDensity,
                              vertical: VisualDensity.minimumDensity,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () =>
                              controller.toggleAsap(!controller.isAsap.value),
                          child: Text(
                            "ASAP",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Date and Time (if not ASAP)
                Obx(
                  () => controller.isAsap.value
                      ? const SizedBox.shrink()
                      : Column(
                          children: [
                            _buildDateTimeRow(context),
                            SizedBox(height: 16.h),
                          ],
                        ),
                ),

                // Vehicle Selection
                _buildVehicleSelection(),
                SizedBox(height: 16.h),

                // Pay Amount
                _buildFieldWithLabel(
                  label: "Pay Amount",
                  ctrl: payController,
                  hint: "\$150",
                  icon: SvgPicture.asset(
                    AppIcons.payAmount_icon,
                    height: 20.sp,
                    width: 20.sp,
                  ),
                  textInputType: TextInputType.number,
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? "Pay amount is required"
                      : null,
                ),

                // Payment Method Dropdown
                _buildPaymentMethodDropdown(),
                SizedBox(height: 16.h),

                // Special Instructions (Optional)
                _buildFieldWithLabel(
                  label: "Special Instructions (Optional)",
                  ctrl: specialController,
                  hint: "e.g., VIP client, suit required, name sign needed",
                  isRequired: false,
                  textCapitalization: TextCapitalization.sentences,
                ),
                SizedBox(height: 24.h),

                // Action Buttons (Cancel and Save)
                Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFEDB9B),
                      ),
                    );
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: "Cancel",
                          backgroundColor: Colors.transparent,
                          textColor: Colors.white,
                          borderColor: const Color(0xFF364153),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          onPressed: () => Get.back(),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        flex: 2,
                        child: CustomButton(
                          text: "Save Changes",
                          backgroundColor: const Color(0xFFFEDB9B),
                          textColor: Colors.black,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              controller.updateJob(
                                pickupLocation: pickupController.text,
                                dropoffLocation: dropoffController.text,
                                flightNumber: flightController.text,
                                paymentAmount: payController.text,
                                instruction: specialController.text,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldWithLabel({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    Widget? icon,
    bool isRequired = true,
    String? Function(String?)? validator,
    TextInputType textInputType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) icon,
            if (icon != null) SizedBox(width: 8.w),
            Text(
              label + (isRequired ? ' *' : ''),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        CustomtextFieldHight(
          controller: ctrl,
          hintText: hint,
          obscureText: false,
          textInputType: textInputType,
          validator: validator,
          textCapitalization: textCapitalization,
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildDateTimeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateTimeField(
            "Date",
            SvgPicture.asset(AppIcons.date_icon, height: 20.sp, width: 20.sp),
            dateController,
            "Select Date",
            () async {
              await controller.chooseDate(context);
              final date = controller.selectedDate.value;
              if (date != null) {
                dateController.text =
                    "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              }
            },
            validator: (val) {
              if (controller.isAsap.value) return null;
              return (val == null || val.trim().isEmpty) ? "Date is required" : null;
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildDateTimeField(
            "Time",
            SvgPicture.asset(
              AppIcons.time_myjob_icon,
              height: 20.sp,
              width: 20.sp,
            ),
            timeController,
            "Select Time",
            () async {
              await controller.chooseTime(context);
              if (controller.formattedTime.value.isNotEmpty) {
                timeController.text = controller.formattedTime.value;
              }
            },
            validator: (val) {
              if (controller.isAsap.value) return null;
              return (val == null || val.trim().isEmpty) ? "Time is required" : null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(
    String label,
    Widget? icon,
    TextEditingController ctrl,
    String hint,
    VoidCallback onPressed, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) icon,
            if (icon != null) SizedBox(width: 8.w),
            Text(
              '$label *',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: onPressed,
          child: AbsorbPointer(
            child: CustomtextFieldHight(
              controller: ctrl,
              hintText: hint,
              obscureText: false,
              textInputType: TextInputType.none,
              validator: validator,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              AppIcons.vechile_car_icon,
              height: 20.sp,
              width: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Vehicle Type Required *',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Obx(
          () => Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            children: controller.vehicles.map((vehicle) {
              final isSelected = controller.selectedVehicle.value == vehicle;
              return GestureDetector(
                onTap: () => controller.selectVehicle(vehicle),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF364153)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF404040)
                          : const Color(0xFF2A2A2A),
                    ),
                  ),
                  child: Text(
                    vehicle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method *',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(
          () => DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              hint: Text(
                'Select payment',
                style: GoogleFonts.inter(
                  color: AppColors.gray100,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              value: controller.selectedRole.value.isEmpty
                  ? null
                  : controller.selectedRole.value,
              items: controller.roles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(
                        role,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.pickRole(value);
                }
              },
              buttonStyleData: ButtonStyleData(
                padding: EdgeInsets.symmetric(
                  horizontal: 15.w,
                  vertical: 8.h,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.black200),
                  color: Colors.transparent,
                ),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 24.sp,
                  color: AppColors.gray100,
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  color: const Color(0xFF141416),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                ),
                offset: Offset(0, -5.h),
                scrollbarTheme: ScrollbarThemeData(
                  radius: Radius.circular(40.r),
                  thickness: WidgetStateProperty.all(6),
                  thumbVisibility: WidgetStateProperty.all(true),
                ),
              ),
              menuItemStyleData: MenuItemStyleData(
                height: 44.h,
                padding: EdgeInsets.only(left: 14.w, right: 14.w),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
