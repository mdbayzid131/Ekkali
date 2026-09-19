import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomText_Field_Hight.dart';
import 'package:moeb_26/core/widgets/Custom_Job_Button.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import '../controllers/job_post_controller.dart';
import 'job_post_sheet_tabbar_view.dart';

class ByTheHour extends StatelessWidget {
  ByTheHour({super.key});

  final fromController = TextEditingController();
  final durationController = TextEditingController();
  final dateController = TextEditingController();
  final pickupTimeController = TextEditingController();
  final payController = TextEditingController();
  final specialController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final PostJobController controller = Get.find<PostJobController>();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobPostSheetTabBarView.buildChauffeurSelection(context, controller),
            SizedBox(height: 16.h),
            _buildFieldWithLabel(
              "From",
              fromController,
              "e.g., JFK Airport, Terminal 4",
              SvgPicture.asset(
                AppIcons.fromlocation_icon,
                height: 20.sp,
                width: 20.sp,
              ),
              validator: (val) =>
                  (val == null || val.isEmpty) ? "Address is required" : null,
            ),
            _buildFieldWithLabel(
              "Duration",
              durationController,
              "e.g., 2 hours",
              SvgPicture.asset(
                AppIcons.duration_icon,
                height: 20.sp,
                width: 20.sp,
              ),
              isRequired: false,
            ),
            _buildDateTimeField(
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
              validator: (val) =>
                  (val == null || val.isEmpty) ? "Date is required" : null,
            ),
            _buildDateTimeField(
              "Pickup Time",
              SvgPicture.asset(
                AppIcons.time_myjob_icon,
                height: 20.sp,
                width: 20.sp,
              ),
              pickupTimeController,
              "Select Time",
              () async {
                await controller.chooseTime(context);
                final time = controller.selectedTime.value;
                if (time != null) {
                  pickupTimeController.text =
                      controller.formattedTime.value;
                }
              },
              validator: (val) =>
                  (val == null || val.isEmpty) ? "Time is required" : null,
            ),
            FormField<String>(
              initialValue: controller.selectedVehicle.value,
              validator: (value) {
                if (controller.selectedVehicle.value.isEmpty) {
                  return "Please select a vehicle type";
                }
                return null;
              },
              builder: (FormFieldState<String> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildVehicleSelection(controller, state),
                    if (state.hasError)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 16.h),
            _buildFieldWithLabel(
              "Pay Amount",
              payController,
              "\$",
              SvgPicture.asset(
                AppIcons.payAmount_icon,
                height: 20.sp,
                width: 20.sp,
              ),
              textInputType: TextInputType.number,
              validator: (val) =>
                  (val == null || val.isEmpty) ? "Amount is required" : null,
            ),
            CustomText(text: "Payment *", fontSize: 13.sp),
            SizedBox(height: 8.h),
            FormField<String>(
              initialValue: controller.selectedRole.value,
              validator: (value) {
                if (controller.selectedRole.value.isEmpty) {
                  return "Select payment";
                }
                return null;
              },
              builder: (FormFieldState<String> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          value:
                              controller
                                  .selectedRole
                                  .value
                                  .isEmpty
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
                              state.didChange(value);
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
                              size: 24,
                              color: AppColors.gray100,
                            ),
                          ),
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              color: Colors.black,
                            ),
                            offset: Offset(0, -5.h),
                            scrollbarTheme: ScrollbarThemeData(
                              radius: Radius.circular(40.r),
                              thickness: WidgetStateProperty.all(6),
                              thumbVisibility: WidgetStateProperty.all(true),
                            ),
                          ),
                          menuItemStyleData: MenuItemStyleData(
                            height: 40.h,
                            padding: EdgeInsets.only(left: 14.w, right: 14.w),
                          ),
                          selectedItemBuilder: (context) {
                            return controller.roles.map((
                              String value,
                            ) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  value,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: EdgeInsets.only(top: 8.h, left: 10.w),
                        child: Text(
                          state.errorText!,
                          style: TextStyle(color: Colors.red, fontSize: 12.sp),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(height: 16.h),
            _buildFieldWithLabel(
              "Special Instructions (Optional)",
              specialController,
              "e.g., VIP client, suit required, name sign needed",
              null,
              isRequired: false,
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 24.h),
            CustomJobButton(
              text: "New Job",
              onPressed: () {
                if (controller.chauffeurSelectionType.value.isEmpty) {
                  Helpers.showCustomSnackBar("Please select a chauffeur or service area", isError: true);
                  return;
                }
                if (controller.chauffeurSelectionType.value == 'global' &&
                    controller.selectedServiceAreas.isEmpty) {
                  Helpers.showCustomSnackBar("Please select at least one service area city", isError: true);
                  return;
                }
                if (controller.chauffeurSelectionType.value == 'favorites' &&
                    controller.selectedDrivers.isEmpty) {
                  Helpers.showCustomSnackBar("Please select at least one preferred chauffeur", isError: true);
                  return;
                }

                if (_formKey.currentState!.validate()) {
                  controller.submitByTheHourJob(
                    pickupLocation: fromController.text,
                    dropoffLocation: "By the hour",
                    duration: durationController.text.isEmpty
                        ? "Not specified"
                        : durationController.text,
                    date: controller.selectedDate.value!,
                    time: controller.selectedTime.value!,
                    paymentAmount: payController.text,
                    paymentType: controller.selectedRole.value,
                    instruction: specialController.text.isEmpty
                        ? null
                        : specialController.text,
                  );
                }
              },
            ),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWithLabel(
    String label,
    TextEditingController ctrl,
    String hint,
    Widget? icon, {
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
            ?icon,
            SizedBox(width: 8.w),
            Text(
              label + (isRequired ? ' *' : ''),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
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
            ?icon,
            SizedBox(width: 8.w),
            Text(
              '$label *',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w400,
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
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildVehicleSelection(
    PostJobController controller,
    FormFieldState<String> state,
  ) {
    final vehicles = [
      'SEDAN',
      'SUV',
      'SPRINTER',
      'LIMO STRETCH',
      'SEDAN/SUV',
    ];

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
                fontWeight: FontWeight.w400,
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
            children: vehicles.map((vehicle) {
              final isSelected = controller.selectedVehicle.value == vehicle;
              return GestureDetector(
                onTap: () {
                  controller.selectVehicle(vehicle);
                  state.didChange(vehicle);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ///select color========================================================
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
                      fontWeight: FontWeight.w400,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }
}
