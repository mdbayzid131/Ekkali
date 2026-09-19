import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/utils/validators.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import '../controllers/invoice_controller.dart';

class SavedClientsView extends GetView<InvoiceController> {
  const SavedClientsView({super.key});

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
              'Saved Clients',
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
      body: RefreshIndicator(
        color: AppColors.primaryColor,
        backgroundColor: Colors.black,
        onRefresh: () => controller.fetchClientsFromApi(),
        child: Obx(() {
          if (controller.isLoading.value && controller.savedClients.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor),
            );
          }

          if (controller.savedClients.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 150.h),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: const Color(0xFF364153),
                        size: 64.sp,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No Saved Clients',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD5C4AB),
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Clients are saved automatically when creating invoices.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF52525B),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            itemCount: controller.savedClients.length,
            separatorBuilder: (context, index) => SizedBox(height: 14.h),
            itemBuilder: (context, index) {
              final client = controller.savedClients[index];
              return _buildClientCard(context, client);
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.black,
        elevation: 6,
        onPressed: () => _showAddOrEditClientBottomSheet(context),
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          'New Client',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, SavedClient client) {
    return Container(
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
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: const Color(0xFFFEDB9B),
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (client.businessName.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        client.businessName,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFEDB9B),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  AppIcons.edit_icon,
                  width: 20.sp,
                  height: 20.sp,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFD5C4AB),
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () =>
                    _showAddOrEditClientBottomSheet(context, client: client),
              ),
              IconButton(
                icon: SvgPicture.asset(
                  AppIcons.delete_icon,
                  width: 20.sp,
                  height: 20.sp,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFEF4444),
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => _showDeleteConfirmDialog(context, client),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          const Divider(color: Color(0xFF1E1E1E), height: 1),
          SizedBox(height: 12.h),
          if (client.email.isNotEmpty)
            _buildInfoRow(Icons.email_outlined, client.email),
          if (client.phone.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _buildInfoRow(Icons.phone_outlined, client.phone),
          ],
          if (client.streetAddress.isNotEmpty || client.city.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _buildInfoRow(
              Icons.location_on_outlined,
              [
                if (client.streetAddress.isNotEmpty) client.streetAddress,
                if (client.city.isNotEmpty) client.city,
                if (client.state.isNotEmpty) client.state,
                if (client.zip.isNotEmpty) client.zip,
                if (client.country.isNotEmpty) client.country,
              ].join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF71717A), size: 14.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFFA1A1AA),
              fontSize: 12.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showAddOrEditClientBottomSheet(
    BuildContext context, {
    SavedClient? client,
  }) {
    final isEditing = client != null;
    final nameController = TextEditingController(text: client?.name ?? '');
    final businessController = TextEditingController(
      text: client?.businessName ?? '',
    );
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final streetController = TextEditingController(
      text: client?.streetAddress ?? '',
    );
    final cityController = TextEditingController(text: client?.city ?? '');
    final stateController = TextEditingController(text: client?.state ?? '');
    final zipController = TextEditingController(text: client?.zip ?? '');
    String selectedCountry = client?.country ?? 'United States';

    // Reactive error state variables for inline validation (no snackbar)
    final nameError = ''.obs;
    final emailError = ''.obs;
    final phoneError = ''.obs;
    final streetError = ''.obs;
    final cityError = ''.obs;
    final stateError = ''.obs;
    final zipError = ''.obs;

    // Auto-clear error when user types
    nameController.addListener(() {
      if (nameError.value.isNotEmpty) nameError.value = '';
    });
    emailController.addListener(() {
      if (emailError.value.isNotEmpty) emailError.value = '';
    });
    phoneController.addListener(() {
      if (phoneError.value.isNotEmpty) phoneError.value = '';
    });
    streetController.addListener(() {
      if (streetError.value.isNotEmpty) streetError.value = '';
    });
    cityController.addListener(() {
      if (cityError.value.isNotEmpty) cityError.value = '';
    });
    stateController.addListener(() {
      if (stateError.value.isNotEmpty) stateError.value = '';
    });
    zipController.addListener(() {
      if (zipError.value.isNotEmpty) zipError.value = '';
    });

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: 600.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Client' : 'Add New Client',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildModalFieldLabel('Client Name*'),
                    _buildModalInput(
                      nameController,
                      'e.g. Johnathan Smith',
                      errorText: nameError,
                    ),
                    SizedBox(height: 12.h),

                    _buildModalFieldLabel('Business Name (Optional)'),
                    _buildModalInput(
                      businessController,
                      'e.g. Smith & Associates',
                    ),
                    SizedBox(height: 12.h),

                    _buildModalFieldLabel('Email Address*'),
                    _buildModalInput(
                      emailController,
                      'client@example.com',
                      keyboardType: TextInputType.emailAddress,
                      errorText: emailError,
                    ),
                    SizedBox(height: 12.h),

                    _buildModalFieldLabel('Phone Number (Optional)'),
                    _buildModalInput(
                      phoneController,
                      'e.g. 555-000-0000',
                      keyboardType: TextInputType.phone,
                      errorText: phoneError,
                    ),
                    SizedBox(height: 12.h),

                    _buildModalFieldLabel('Street Address*'),
                    _buildModalInput(
                      streetController,
                      'e.g. 123 Luxury Avenue',
                      errorText: streetError,
                    ),
                    SizedBox(height: 12.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('City*'),
                              _buildModalInput(
                                cityController,
                                'e.g. Beverly Hills',
                                errorText: cityError,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('State*'),
                              _buildModalInput(
                                stateController,
                                'e.g. CA',
                                errorText: stateError,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('ZIP/Postal Code*'),
                              _buildModalInput(
                                zipController,
                                'e.g. 90210',
                                errorText: zipError,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildModalFieldLabel('Country'),
                              TextField(
                                enabled: false,
                                controller: TextEditingController(
                                  text: 'United States',
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 14.sp,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF1E1E1E),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 12.h,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2C2C2C),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Obx(
              () => CustomButton(
                text: isEditing ? 'Save Changes' : 'Add Client',
                loading: controller.isLoading.value,
                onPressed: () async {
                  bool isValid = true;

                  final nErr = Validators.name(
                    nameController.text,
                    message: 'Client name is required',
                    minLength: 2,
                  );
                  nameError.value = nErr ?? '';
                  if (nErr != null) isValid = false;

                  final eErr = Validators.email(
                    emailController.text,
                    message: 'Enter a valid email address',
                  );
                  emailError.value = eErr ?? '';
                  if (eErr != null) isValid = false;

                  if (phoneController.text.trim().isNotEmpty) {
                    final pErr = Validators.phone(
                      phoneController.text,
                      message: 'Enter a valid phone number',
                    );
                    phoneError.value = pErr ?? '';
                    if (pErr != null) isValid = false;
                  } else {
                    phoneError.value = '';
                  }

                  final stErr = Validators.required(
                    streetController.text,
                    message: 'Street address is required',
                  );
                  streetError.value = stErr ?? '';
                  if (stErr != null) isValid = false;

                  final cErr = Validators.required(
                    cityController.text,
                    message: 'City is required',
                  );
                  cityError.value = cErr ?? '';
                  if (cErr != null) isValid = false;

                  final sErr = Validators.required(
                    stateController.text,
                    message: 'State is required',
                  );
                  stateError.value = sErr ?? '';
                  if (sErr != null) isValid = false;

                  final zErr = Validators.required(
                    zipController.text,
                    message: 'ZIP/Postal code is required',
                  );
                  zipError.value = zErr ?? '';
                  if (zErr != null) isValid = false;

                  if (!isValid) return;

                  final newClient = SavedClient(
                    id: isEditing ? client.id : '',
                    name: nameController.text.trim(),
                    businessName: businessController.text.trim(),
                    email: emailController.text.trim(),
                    phone: phoneController.text.trim(),
                    streetAddress: streetController.text.trim(),
                    city: cityController.text.trim(),
                    state: stateController.text.trim(),
                    zip: zipController.text.trim(),
                    country: selectedCountry,
                  );

                  final success = await controller.addOrUpdateSavedClient(
                    newClient,
                  );
                  if (success) {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildModalFieldLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFFD5C4AB),
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModalInput(
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboardType,
    RxString? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF52525B),
              fontSize: 13.sp,
            ),
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 12.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: const BorderSide(color: Color(0xFFFEDB9B)),
            ),
          ),
        ),
        if (errorText != null)
          Obx(() {
            if (errorText.value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.only(top: 4.h, left: 4.w),
              child: Text(
                errorText.value,
                style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, SavedClient client) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFF27272A), width: 1),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: const BoxDecoration(
                  color: Color(0xFF271515),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: const Color(0xFFEF4444),
                  size: 28.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Client',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Are you sure you want to delete ${client.name}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFFA1A1AA),
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel',
                      backgroundColor: Colors.transparent,
                      textColor: Colors.white,
                      borderColor: const Color(0xFF3F3F46),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CustomButton(
                      text: 'Delete',
                      backgroundColor: const Color(0xFFEF4444),
                      textColor: Colors.white,
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await controller.deleteSavedClient(client.id);
                        Helpers.showCustomSnackBar(
                          'Client removed successfully',
                          title: 'Deleted',
                          isError: false,
                        );
                      },
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
