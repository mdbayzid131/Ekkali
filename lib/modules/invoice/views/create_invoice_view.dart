import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/invoice_controller.dart';

import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';

class CreateInvoiceView extends GetView<InvoiceController> {
  const CreateInvoiceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomSubAppBar(
        title: 'Create Invoice',
        onBackPressed: () => controller.previousStep(),
      ),
      body: Obx(() {
        return Column(
          children: [
            // Progress Bar / Step Info
            _buildProgressBar(),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: _buildStepContent(context),
              ),
            ),

            // Bottom Buttons
            _buildBottomButtons(context),
          ],
        );
      }),
    );
  }

  // --- PROGRESS BAR ---
  Widget _buildProgressBar() {
    double progress = 0.33;
    String stepTitle = 'Basic Information';
    int percentage = 33;

    if (controller.currentStep.value == 2) {
      progress = 0.66;
      stepTitle = 'Client Details';
      percentage = 66;
    } else if (controller.currentStep.value == 3) {
      progress = 1.0;
      stepTitle = 'Message Details';
      percentage = 100;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${controller.currentStep.value} of 3 - $stepTitle',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD5C4AB),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  color: const Color(0xFFD5C4AB),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 4.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- STEP CONTENTS ---
  Widget _buildStepContent(BuildContext context) {
    switch (controller.currentStep.value) {
      case 1:
        return _buildStep1(context);
      case 2:
        return _buildStep2(context);
      case 3:
        return _buildStep3(context);
      default:
        return _buildStep1(context);
    }
  }

  // STEP 1: Basic Information
  Widget _buildStep1(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice Amount
        _buildFieldLabel('Invoice amount*'),
        _buildInputField(
          controller: controller.invoiceAmountController,
          hint: '0.00',
          prefixText: 'USD ',
          errorText: controller.invoiceAmountError.value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: 20.h),

        // Issued Date
        _buildFieldLabel('Issued'),
        GestureDetector(
          onTap: () => controller.pickIssuedDate(context),
          child: AbsorbPointer(
            child: _buildInputField(
              controller: TextEditingController(
                text: controller.formattedIssuedDate,
              ),
              hint: 'Select Date',
              suffixIcon: Icon(
                Icons.calendar_today_outlined,
                color: const Color(0xFFD5C4AB),
                size: 20.sp,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),

        // Due Date
        _buildFieldLabel('Due date'),
        _buildDueDateSection(context),
        SizedBox(height: 20.h),

        // Currency
        _buildFieldLabel('Currency'),
        _buildCurrencyDropdown(context),
        SizedBox(height: 10.h),
      ],
    );
  }

  // STEP 2: Client Details
  Widget _buildStep2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- CLIENT INFORMATION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CLIENT INFORMATION',
              style: GoogleFonts.inter(
                color: const Color(0xFFD5C4AB),
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Obx(() {
              if (controller.savedClients.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _showSavedClientPickerBottomSheet(context),
                child: Text(
                  'Select Saved Client',
                  style: GoogleFonts.inter(
                    color: AppColors.primaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
          ],
        ),
        SizedBox(height: 12.h),

        // Select Saved Client Card/Dropdown
        Obx(() {
          if (controller.savedClients.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _showSavedClientPickerBottomSheet(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161410),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_pin_rounded,
                          color: const Color(0xFFFEDB9B),
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          controller.selectedSavedClient.value != null
                              ? 'Selected: ${controller.selectedSavedClient.value!.name}'
                              : 'Choose from saved clients...',
                          style: GoogleFonts.inter(
                            color: controller.selectedSavedClient.value != null
                                ? const Color(0xFFFEDB9B)
                                : const Color(0xFFA1A1AA),
                            fontSize: 13.5.sp,
                            fontWeight: controller.selectedSavedClient.value != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFFFEDB9B),
                        size: 22.sp,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          );
        }),

        // Client Name
        _buildFieldLabel('Client Name*'),
        _buildInputField(
          controller: controller.clientNameController,
          hint: 'e.g. Johnathan Smith',
          errorText: controller.clientNameError.value,
        ),
        SizedBox(height: 16.h),

        // Business Name
        _buildFieldLabel('Business Name (Optional)'),
        _buildInputField(
          controller: controller.clientBusinessNameController,
          hint: 'e.g. Smith & Associates',
        ),
        SizedBox(height: 16.h),

        // Email Address
        _buildFieldLabel('Email Address*'),
        _buildInputField(
          controller: controller.clientEmailController,
          hint: 'client@example.com',
          errorText: controller.clientEmailError.value,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16.h),

        // Phone Number
        _buildFieldLabel('Phone Number (Optional)'),
        _buildInputField(
          controller: controller.clientPhoneController,
          hint: 'e.g. 555-000-0000',
          errorText: controller.clientPhoneError.value,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 24.h),

        // --- BILLING ADDRESS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BILLING ADDRESS',
              style: GoogleFonts.inter(
                color: const Color(0xFFD5C4AB),
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Icon(
              Icons.map_outlined,
              color: const Color(0xFFD5C4AB),
              size: 20.sp,
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Street Address
        _buildFieldLabel('Street Address*'),
        _buildInputField(
          controller: controller.clientStreetAddressController,
          hint: '123 Luxury Avenue',
          errorText: controller.clientStreetAddressError.value,
        ),
        SizedBox(height: 16.h),

        // City & State Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('City*'),
                  _buildInputField(
                    controller: controller.clientCityController,
                    hint: 'Beverly Hills',
                    errorText: controller.clientCityError.value,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('State/Province*'),
                  _buildInputField(
                    controller: controller.clientStateController,
                    hint: 'CA',
                    errorText: controller.clientStateError.value,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),

        // Zip & Country Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('ZIP/Postal Code*'),
                  _buildInputField(
                    controller: controller.clientZipController,
                    hint: '90210',
                    errorText: controller.clientZipError.value,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Country'),
                  _buildCountryDropdown(context),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  // STEP 3: Message to Client
  Widget _buildStep3(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Optional',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD5C4AB),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                height: 100.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: controller.invoiceDescriptionController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Briefly describe the work or services rendered...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF4B5563),
                      fontSize: 14.sp,
                    ),
                    contentPadding: EdgeInsets.all(14.w),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Message to Client Card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Message to Client',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Optional',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD5C4AB),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                height: 100.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextField(
                  controller: controller.messageToClientController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Add a personal note or thank you message for your client...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF4B5563),
                      fontSize: 14.sp,
                    ),
                    contentPadding: EdgeInsets.all(14.w),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- REUSABLE UI BUILDERS ---

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFD5C4AB),
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    Widget? suffixIcon,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? errorText,
  }) {
    final bool hasError = errorText != null && errorText.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111), // Dark container background
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF1E1E1E),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixText: prefixText,
              prefixStyle: GoogleFonts.inter(
                color: const Color(0xFFD5C4AB),
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF4B5563),
                fontSize: 15.sp,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: maxLines > 1 ? 12.h : 16.h,
              ),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 4.w),
            child: Text(
              errorText,
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDueDateSection(BuildContext context) {
    final hasDueDateError = controller.customDueDateError.value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: controller.dueDateOptions.map((option) {
            final isSelected = controller.selectedDueDateOption.value == option;

            // Label logic for Custom Due Date representation
            String displayLabel = option;
            if (option == 'Custom Due Date' &&
                controller.customDueDate.value != null) {
              displayLabel = controller.formattedDueDate;
            }

            return GestureDetector(
              onTap: () => controller.selectDueDateOption(option, context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFEDB9B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFEDB9B)
                        : const Color(0xFF1E1E1E),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  displayLabel,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (hasDueDateError)
          Padding(
            padding: EdgeInsets.only(top: 6.h, left: 4.w),
            child: Text(
              controller.customDueDateError.value,
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrencyDropdown(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
      ),
      child: Text(
        controller.selectedCurrency.value,
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCountryDropdown(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5),
      ),
      child: Text(
        'United States',
        style: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 15.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // --- BOTTOM BUTTONS ---
  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
      ),
      child: Row(
        children: [
          // Back Button
          Expanded(
            child: CustomButton(
              text: 'Back',
              backgroundColor: Colors.transparent,
              textColor: Colors.white,
              borderColor: const Color(0xFF1E1E1E),
              onPressed: () => controller.previousStep(),
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
          SizedBox(width: 15.w),

          // Next/Create Button
          Expanded(
            child: Obx(
              () => CustomButton(
                text: controller.currentStep.value == 3 ? 'Preview' : 'Next',
                loading: controller.isLoading.value,
                onPressed: () => controller.nextStep(),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- SAVED CLIENT PICKER BOTTOM SHEET ---
  void _showSavedClientPickerBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: 450.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Saved Client',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: Obx(() {
                if (controller.savedClients.isEmpty) {
                  return Center(
                    child: Text(
                      'No saved clients available',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF71717A),
                        fontSize: 14.sp,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: controller.savedClients.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final client = controller.savedClients[index];
                    final isSelected =
                        controller.selectedSavedClient.value?.id == client.id;

                    return GestureDetector(
                      onTap: () {
                        controller.selectSavedClient(client);
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2A1C08)
                              : const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : const Color(0xFF2C2C2C),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: const Color(0xFFFEDB9B),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.name,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (client.businessName.isNotEmpty &&
                                      client.businessName != client.name) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      client.businessName,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFFEDB9B),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                  if (client.email.isNotEmpty) ...[
                                    SizedBox(height: 2.h),
                                    Text(
                                      client.email,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFA1A1AA),
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primaryColor,
                                size: 22.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
