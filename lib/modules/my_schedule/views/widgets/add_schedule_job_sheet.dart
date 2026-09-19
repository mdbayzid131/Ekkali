import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomText_Field_Hight.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import 'package:moeb_26/modules/my_schedule/controllers/my_schedule_controller.dart';
import 'package:moeb_26/modules/my_schedule/models/my_schedule_job_model.dart';

class AddScheduleJobSheet extends StatefulWidget {
  final MyScheduleJobModel? existingJob;

  const AddScheduleJobSheet({super.key, this.existingJob});

  @override
  State<AddScheduleJobSheet> createState() => _AddScheduleJobSheetState();
}

class _AddScheduleJobSheetState extends State<AddScheduleJobSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  late TextEditingController _fareController;
  late TextEditingController _flightNumberController;
  late TextEditingController _notesController;
  late TextEditingController _paymentInfoController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  late DateTime _selectedDateTime;
  late String _selectedVehicleType;
  late bool _isPaid;
  late String _selectedPaymentMethod;

  final List<String> _vehicles = [
    'SEDAN',
    'SUV',
    'SPRINTER',
    'LIMO STRETCH',
    'SEDAN/SUV',
  ];

  final List<String> _paymentMethods = [
    'Credit Card on File',
    'Collect Payment',
  ];

  @override
  void initState() {
    super.initState();
    final job = widget.existingJob;
    final controller = Get.find<MyScheduleController>();

    _nameController = TextEditingController(text: job?.clientName ?? '');
    _phoneController = TextEditingController(text: job?.clientPhone ?? '');
    _pickupController = TextEditingController(text: job?.pickupLocation ?? '');
    _dropoffController = TextEditingController(text: job?.dropoffLocation ?? '');
    _fareController = TextEditingController(text: job?.fare ?? '');
    _flightNumberController = TextEditingController(text: job?.flightNumber ?? '');
    _notesController = TextEditingController(text: job?.notes ?? '');
    _paymentInfoController = TextEditingController(text: job?.paymentInfo ?? '');

    _selectedDateTime = job?.pickupDateTime ?? controller.selectedDate.value;
    _dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(_selectedDateTime),
    );
    _timeController = TextEditingController(
      text: DateFormat('hh:mm a').format(_selectedDateTime),
    );
    _isPaid = job?.isPaid ?? false;

    final rawPayment = job?.paymentMethod ?? _paymentMethods.first;
    if (_paymentMethods.contains(rawPayment)) {
      _selectedPaymentMethod = rawPayment;
    } else if (rawPayment.toUpperCase().contains('COLLECT')) {
      _selectedPaymentMethod = 'Collect Payment';
    } else {
      _selectedPaymentMethod = 'Credit Card on File';
    }

    final existingType = job?.vehicleType.toUpperCase().trim() ?? 'SEDAN';
    if (_vehicles.contains(existingType)) {
      _selectedVehicleType = existingType;
    } else if (existingType == 'EXECUTIVE SEDAN') {
      _selectedVehicleType = 'SEDAN';
    } else if (existingType == 'LUXURY SUV') {
      _selectedVehicleType = 'SUV';
    } else if (existingType == 'CHAUFFEUR VAN') {
      _selectedVehicleType = 'SPRINTER';
    } else {
      _selectedVehicleType = 'SEDAN';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _fareController.dispose();
    _flightNumberController.dispose();
    _notesController.dispose();
    _paymentInfoController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedDateTime.hour,
        _selectedDateTime.minute,
      );
      _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDateTime);
    });
  }

  Future<void> _pickTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryColor,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E22),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        _selectedDateTime.year,
        _selectedDateTime.month,
        _selectedDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _timeController.text = DateFormat('hh:mm a').format(_selectedDateTime);
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final controller = Get.find<MyScheduleController>();
      final isEdit = widget.existingJob != null;

      final job = MyScheduleJobModel(
        id: isEdit ? widget.existingJob!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        clientName: _nameController.text.trim(),
        clientPhone: _phoneController.text.trim(),
        pickupDateTime: _selectedDateTime,
        pickupLocation: _pickupController.text.trim(),
        dropoffLocation: _dropoffController.text.trim(),
        vehicleType: _selectedVehicleType,
        fare: _fareController.text.trim(),
        notes: _notesController.text.trim(),
        flightNumber: _flightNumberController.text.trim().isNotEmpty
            ? _flightNumberController.text.trim()
            : null,
        isDispatchedToNetwork: widget.existingJob?.isDispatchedToNetwork ?? false,
        status: widget.existingJob?.status ?? "Scheduled",
        isPaid: _isPaid,
        assignedChauffeurId: widget.existingJob?.assignedChauffeurId,
        assignedChauffeurName: widget.existingJob?.assignedChauffeurName,
        paymentMethod: _selectedPaymentMethod,
        paymentInfo: _paymentInfoController.text.trim(),
      );

      if (isEdit) {
        final success = await controller.updateDirectBooking(job);
        if (success && mounted) {
          Navigator.of(context).pop();
        }
      } else {
        final success = await controller.createDirectBooking(job);
        if (success && mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MyScheduleController>();
    final isEdit = widget.existingJob != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: CustomSubAppBar(
        title: isEdit ? "Edit Direct Booking" : "Add Direct Booking",
        onBackPressed: () => Get.back(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 16.h,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextgray(
                text: "Logged as a private direct booking for your personal schedule",
                fontSize: 12.sp,
              ),
              SizedBox(height: 16.h),

              // Client Name
              _buildFieldWithLabel(
                "Client Name",
                _nameController,
                "e.g. John Smith",
                Icon(
                  Icons.person_outline,
                  size: 20.sp,
                  color: Colors.white,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Client name required" : null,
              ),

              // Client Phone
              _buildFieldWithLabel(
                "Client Phone Number",
                _phoneController,
                "e.g. +1 (555) 019-2834",
                Icon(
                  Icons.phone_outlined,
                  size: 20.sp,
                  color: Colors.white,
                ),
                textInputType: TextInputType.phone,
                validator: (v) => v == null || v.trim().isEmpty ? "Phone number required" : null,
              ),

              // Date & Time Row (Matching JobPost Screen)
              Row(
                children: [
                  Expanded(
                    child: _buildDateTimeField(
                      "Date",
                      SvgPicture.asset(
                        AppIcons.date_icon,
                        height: 20.sp,
                        width: 20.sp,
                      ),
                      _dateController,
                      "Select Date",
                      () => _pickDate(context),
                      validator: (v) => v == null || v.isEmpty ? "Date is required" : null,
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
                      _timeController,
                      "Select Time",
                      () => _pickTime(context),
                      validator: (v) => v == null || v.isEmpty ? "Time is required" : null,
                    ),
                  ),
                ],
              ),

              // Pickup Location
              _buildFieldWithLabel(
                "Pickup Location",
                _pickupController,
                "e.g. JFK Terminal 4 / Address",
                SvgPicture.asset(
                  AppIcons.fromlocation_icon,
                  height: 20.sp,
                  width: 20.sp,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Pickup location required" : null,
              ),

              // Drop-off Location
              _buildFieldWithLabel(
                "Drop-off Location",
                _dropoffController,
                "e.g. Hotel / Destination",
                SvgPicture.asset(
                  AppIcons.fromlocation_icon,
                  height: 20.sp,
                  width: 20.sp,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Drop-off location required" : null,
              ),

              // Vehicle Type Chip Pills Selector (Matching JobPost Screen)
              FormField<String>(
                initialValue: _selectedVehicleType,
                validator: (val) {
                  if (_selectedVehicleType.isEmpty) {
                    return "Please select a vehicle type";
                  }
                  return null;
                },
                builder: (FormFieldState<String> state) {
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
                      Wrap(
                        spacing: 12.w,
                        runSpacing: 12.h,
                        children: _vehicles.map((vehicle) {
                          final isSelected = _selectedVehicleType == vehicle;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVehicleType = vehicle;
                              });
                              state.didChange(vehicle);
                            },
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
                                  fontWeight: FontWeight.w400,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            state.errorText!,
                            style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12.sp),
                          ),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Price / Fare
              _buildFieldWithLabel(
                "Price / Fare",
                _fareController,
                "e.g. \$150.00",
                SvgPicture.asset(
                  AppIcons.payAmount_icon,
                  height: 20.sp,
                  width: 20.sp,
                ),
                isRequired: false,
              ),

              // Payment Status (Paid / Not Paid)
              Text(
                "Payment Status *",
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPaid = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: !_isPaid
                              ? const Color(0xFF2C1618)
                              : const Color(0xFF1F1C1C),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: !_isPaid
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF364153),
                            width: !_isPaid ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pending_actions_rounded,
                              size: 16.sp,
                              color: !_isPaid
                                  ? const Color(0xFFF87171)
                                  : Colors.white38,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Unpaid",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: !_isPaid ? FontWeight.bold : FontWeight.w500,
                                color: !_isPaid
                                    ? const Color(0xFFF87171)
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPaid = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _isPaid
                              ? const Color(0xFF102A1C)
                              : const Color(0xFF1F1C1C),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: _isPaid
                                ? const Color(0xFF166534)
                                : const Color(0xFF364153),
                            width: _isPaid ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16.sp,
                              color: _isPaid
                                  ? const Color(0xFF4ADE80)
                                  : Colors.white38,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "Paid",
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: _isPaid ? FontWeight.bold : FontWeight.w500,
                                color: _isPaid
                                    ? const Color(0xFF4ADE80)
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Payment Method
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method *',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 13.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1C1C),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.black200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPaymentMethod,
                        isExpanded: true,
                        dropdownColor: Colors.black,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 20.sp),
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
                        items: _paymentMethods.map((method) {
                          return DropdownMenuItem<String>(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedPaymentMethod = val);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),



              // Flight Number (Optional)
              _buildFieldWithLabel(
                "Flight Number",
                _flightNumberController,
                "e.g. BA-178 (Optional)",
                null,
                isRequired: false,
              ),

              // Notes
              _buildFieldWithLabel(
                "Notes / Special Requests",
                _notesController,
                "e.g. Special instructions, luggage specs",
                null,
                isRequired: false,
              ),
              SizedBox(height: 24.h),

              Obx(
                () => controller.isSubmitting.value
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : CustomButton(
                        text: isEdit ? "Update Booking" : "Save Direct Booking",
                        onPressed: _submit,
                      ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              icon,
              SizedBox(width: 8.w),
            ],
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
            if (icon != null) ...[
              icon,
              SizedBox(width: 8.w),
            ],
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
}
