import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/validators.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signup_controller.dart';
import 'package:moeb_26/core/widgets/Custom_dropdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/widgets/CustomButton.dart';
import '../../../../core/widgets/CustomText.dart';
import '../../../../core/widgets/CustomTextField.dart';
import '../../../../core/widgets/CustomTextGary.dart';

class CreateAccountView extends StatefulWidget {
  const CreateAccountView({super.key});
  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  final RxString areaError = ''.obs;
  final RxString roleError = ''.obs;

  // Using the unified SignupController
  SignupController get controller => Get.find<SignupController>();
  final _formKey = GlobalKey<FormState>();
  final ScrollController dropdownScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.fetchServiceAreas();
    dropdownScrollController.addListener(_onDropdownScroll);
  }

  void _onDropdownScroll() {
    if (dropdownScrollController.position.pixels >=
        dropdownScrollController.position.maxScrollExtent - 50) {
      controller.loadMoreCities();
    }
  }

  @override
  void dispose() {
    dropdownScrollController.removeListener(_onDropdownScroll);
    dropdownScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50.h),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  CustomText(
                    text: "Account Create",
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  SizedBox(height: 8.h),
                  CustomTextgray(
                    text: "Tell us about yourself to get started",
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: 32.h),

                  // ========== Full Name ==========
                  _buildInputField(
                    label: "Full Name",
                    isRequired: true,
                    child: Customtextfield(
                      controller: controller.nameController,
                      hintText: "John Smith",
                      obscureText: false,
                      textInputType: TextInputType.name,
                      validator: (value) => Validators.name(value),
                    ),
                  ),

                  // ========== Phone Number ==========
                  _buildInputField(
                    label: "Phone Number",
                    isRequired: true,
                    child: Customtextfield(
                      controller: controller.phoneController,
                      hintText: "Enter your phone number",
                      obscureText: false,
                      textInputType: TextInputType.phone,
                      validator: (value) => Validators.phone(value),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9+()\s-]'),
                        ),
                      ],
                    ),
                  ),

                  // ========== Email Address ==========
                  _buildInputField(
                    label: "Email Address",
                    isRequired: true,
                    child: Customtextfield(
                      controller: controller.emailController,
                      hintText: "Enter your email address",
                      obscureText: false,
                      textInputType: TextInputType.emailAddress,
                      validator: (value) => Validators.email(value),
                    ),
                  ),

                  // ========== Service Area ==========
                  _buildInputField(
                    label: "Service Area",
                    isRequired: true,
                    child: Obx(
                      () => _buildDropdownField(
                        error: areaError.value,
                        isLoading: controller.isCitiesLoading,
                        child: CustomDropdown(
                          hintText: 'Select service area',
                          value: controller.selectedArea.value.isEmpty
                              ? null
                              : controller.selectedArea.value,
                          items: controller.cities,
                          scrollController: dropdownScrollController,
                          isLoadingMore: controller.isMoreCitiesLoading,
                          hasNextPage: controller.hasNextCitiesPage,
                          onLoadMore: () => controller.loadMoreCities(),
                          onChanged: (value) {
                            if (value != null &&
                                value != 'loading' &&
                                value != 'loadMore') {
                              controller.pickArea(value);
                              areaError.value = '';
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  // ========== Years of Experience ==========
                  _buildInputField(
                    label: "Years of Experience",
                    isRequired: false,
                    child: Customtextfield(
                      controller: controller.yearController,
                      hintText: "0",
                      obscureText: false,
                      textInputType: TextInputType.number,
                      validator: (value) => Validators.required(
                        value,
                        message: "Enter your years of experience",
                      ),
                    ),
                  ),

                  // ========== Company Name ==========
                  _buildInputField(
                    label: "Company Name",
                    isRequired: true,
                    child: Customtextfield(
                      controller: controller.companyNameController,
                      hintText: "Example Limo Company LLC",
                      obscureText: false,
                      textInputType: TextInputType.name,
                      validator: (value) => Validators.required(
                        value,
                        message: "Enter your company name",
                      ),
                    ),
                  ),

                  // ========== Company Role ==========
                  _buildInputField(
                    label: "Company Role",
                    isRequired: true,
                    child: Obx(
                      () => _buildDropdownField(
                        error: roleError.value,
                        child: CustomDropdown(
                          hintText: 'Select company role',
                          value: controller.selectedRole.value.isEmpty
                              ? null
                              : controller.selectedRole.value,
                          items: controller.roles,
                          onChanged: (value) {
                            if (value != null) {
                              controller.pickRole(value);
                              roleError.value = '';
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  // ========== Languages Speaking ==========
                  _buildInputField(
                    label: "Languages Speaking",
                    isRequired: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: controller.availableLanguages.map((lang) {
                            final isEnglish = lang == 'English';
                            return Obx(() {
                              final isSelected = controller.selectedLanguages
                                  .contains(lang);
                              return FilterChip(
                                showCheckmark: false,
                                label: Text(
                                  lang,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.white,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13.sp,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: isEnglish
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          controller.selectedLanguages.add(
                                            lang,
                                          );
                                        } else {
                                          controller.selectedLanguages.remove(
                                            lang,
                                          );
                                        }
                                      },
                                selectedColor: AppColors.orange100,
                                backgroundColor: const Color(0xFF1E1E1E),
                                disabledColor: AppColors.orange100.withValues(
                                  alpha: 0.6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.orange100
                                        : const Color(0xFF2C2C2C),
                                    width: 1.w,
                                  ),
                                ),
                              );
                            });
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // ========== Password ==========
                  _buildInputField(
                    label: "Create Password",
                    isRequired: true,
                    child: Obx(
                      () => Customtextfield(
                        controller: controller.passwordController,
                        hintText: "Enter password",
                        obscureText: !controller.showPassword.value,
                        textInputType: TextInputType.visiblePassword,
                        validator: (value) => Validators.password(
                          value,
                          minLength: 8,
                          requireDigit: true,
                          requireUppercase: true,
                          requireSpecialChar: true,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showPassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.gray100,
                          ),
                          onPressed: controller.togglePassword,
                        ),
                      ),
                    ),
                  ),

                  // ========== Confirm Password ==========
                  _buildInputField(
                    label: "Confirm Password",
                    isRequired: true,
                    child: Obx(
                      () => Customtextfield(
                        controller: controller.confirmPasswordController,
                        hintText: "Re-enter password",
                        obscureText: !controller.showConfirmPassword.value,
                        textInputType: TextInputType.visiblePassword,
                        validator: (value) => Validators.confirmPassword(
                          value,
                          controller.passwordController.text,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showConfirmPassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.gray100,
                          ),
                          onPressed: controller.toggleConfirmPassword,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // ========== Submit Button ==========
                  CustomButton(text: "Continue", onPressed: _handleSubmit),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildInputField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomText(
              text: label,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
            if (isRequired)
              Text(
                " *",
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        child,
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildDropdownField({
    required Widget child,
    String? error,
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColors.orange100),
            ),
          )
        else
          child,
        if (error != null && error.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 12.w, top: 6.h),
            child: Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
            ),
          ),
      ],
    );
  }

  // --- Logic ---

  void _handleSubmit() {
    FocusScope.of(context).unfocus();
    Get.toNamed(Routes.vehicleinformationView);
  }
}
