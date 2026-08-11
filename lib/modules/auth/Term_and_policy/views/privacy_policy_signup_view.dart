import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signup_controller.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';

class PrivacyPolicySignUpView extends StatelessWidget {
  PrivacyPolicySignUpView({super.key});

  final controller = Get.find<SignupController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CustomText(
                              text: "Chauffeur Code of Conduct &",
                              fontSize: 20.sp,
                            ),
                            CustomText(
                              text: "Service Standards",
                              fontSize: 20.sp,
                            ),
                            SizedBox(height: 7.h),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: CustomTextgray(
                                  text:
                                      "This Code of Conduct defines the professional standards required of all chauffeurs operating within the Ekkali Network. Compliance is mandatory.",
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Sections
                        _buildSections(),

                        // Validation error message
                        if (controller.showTermError.value)
                          Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  const Expanded(
                                    child: Text(
                                      "Please agree to all terms before continuing",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        CustomButton(
                          text: "Submit Application",
                          onPressed: () {
                            Get.toNamed(
                              Routes.otpVerificationView,
                              arguments: {
                                'email': controller.emailController.text,
                                'isRegister': true,
                              },
                            );
                          },
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSections() {
    return Column(
      children: [
        _buildSection(
          title: "APPEARANCE & DRESS CODE",
          items: [
            "I confirm that I speak and understand English sufficiently to communicate professionally with passengers and follow trip instructions.",
            "Chauffeurs must wear a full business suit with tie at all times while on duty.",
            "Approved suit colors: Black, Navy Blue, or Dark Grey only.",
            "Shirts must be clean, pressed, and neutral in color (white, black or light blue).",
            "Shoes must be black dress shoes, clean and polished.",
            "Personal grooming must be professional at all times (clean shave or neatly trimmed beard).",
          ],
          startIndex: 0,
        ),
        _buildSection(
          title: "FRAGRANCE & HYGIENE",
          items: [
            "Fragrance must be fragrance-free or extremely light.",
            "Strong colognes, perfumes, or scented products are strictly prohibited.",
            "Breath must be clean and neutral. Smoking, vaping, or strong food odors prior to service are not permitted.",
          ],
          startIndex: 6,
        ),
        _buildSection(
          title: "VEHICLE STANDARDS",
          items: [
            "I confirm that my Sedan, SUV, or Sprinter vehicle is 5 years old or newer and meets Ekkali’s quality standards.",
            "Vehicle must be thoroughly cleaned inside and out before every assignment.",
            "Interior must be free of odors, trash, stains, or personal items.",
            "Windows must be clean; dashboard and seats wiped and presentable.",
            "Vehicle must be mechanically sound and fully fueled prior to pickup.",
            "No warning or service lights may be displayed during service.",
          ],
          startIndex: 9,
        ),
        _buildSection(
          title: "CLIENT AMENITIES",
          items: [
            "Provide bottled water for every client.",
            "Provide Apple (Lightning) and Android (USB-C) charging cables.",
            "Carry a clean umbrella and offer it in case of rain.",
            "Climate control must be set to a comfortable temperature.",
            "Music only upon client request (default setting: silence).",
          ],
          startIndex: 15,
        ),
        _buildSection(
          title: "SERVICE & PROFESSIONAL BEHAVIOR",
          items: [
            "Assist clients with luggage unless declined.",
            "Open and close vehicle doors when appropriate.",
            "Greet clients politely using Mr. / Ms., unless instructed otherwise.",
            "Confirm destination quietly and professionally.",
            "Maintain a calm, discreet, and respectful demeanor at all times.",
          ],
          startIndex: 20,
        ),
        _buildSection(
          title: "STRICT PROFESSIONAL BOUNDARIES",
          items: [
            "Never discuss politics, religion, or sports with clients.",
            "Never argue or express personal opinions.",
            "Never provide personal business cards, phone numbers, or social media.",
            "Never solicit future business from a client.",
            "Always act as a representative exclusively of the assigning company.",
          ],
          startIndex: 25,
        ),
        _buildSection(
          title: "SAFETY & COMMUNICATION",
          items: [
            "No texting or handheld phone use while driving with a client onboard.",
            "Phone use is permitted hands-free only for navigation if necessary.",
            "Obey all traffic laws and drive smoothly at all times.",
            "Aggressive driving, speeding, or sudden braking is prohibited.",
          ],
          startIndex: 30,
        ),
        _buildSection(
          title: "PUNCTUALITY & RELIABILITY",
          items: [
            "Arrive 10–15 minutes early for every pickup.",
            "Monitor flight status when applicable.",
            "Never cancel last-minute except in a true emergency.",
            "Immediately inform the company of any delays or issues.",
          ],
          startIndex: 34,
        ),
        _buildSection(
          title: "CONFIDENTIALITY & RESPECT",
          items: [
            "All client information is strictly confidential.",
            "Do not discuss clients, routes, or conversations with anyone.",
            "Respect client privacy at all times.",
            "Treat all clients with equal respect, regardless of status or appearance.",
          ],
          startIndex: 38,
        ),
        _buildSection(
          title: "JOB ACCEPTANCE & RESPONSIBILITY",
          items: [
            "Chauffeurs must carefully review the full job description before accepting any assignment.",
            "Pickup and drop-off details.",
            "Date and time.",
            "Vehicle requirements.",
            "Client notes and special instructions.",
            "Once accepted, a job may not be canceled, returned, or declined, except in a true emergency and only with company approval.",
            "Job transfers, substitutions, or subcontracting are strictly forbidden without written authorization.",
            "The chauffeur who accepts the job is personally responsible for its completion.",
            "Unauthorized job swapping or replacement may result in immediate suspension or permanent removal from the Elite Chauffeur Network. EKKALI.",
          ],
          startIndex: 42,
        ),
        _buildSection(
          title: "ASAP Jobs",
          items: [
            "\u201CASAP\u201D means immediate service.",
            "Chauffeurs must be on location or within 10 minutes, verified by GPS, to accept the job.",
          ],
          startIndex: 51,
        ),
        _buildSection(
          title: "PAYMENT",
          items: [
            "Once a job is completed, the job poster must pay the chauffeur within a maximum of 48 hours.",
          ],
          startIndex: 53,
        ),
        _buildSection(
          title: "ENFORCEMENT",
          items: [
            "Violations may result in: Warning.",
            "Violations may result in: Temporary suspension.",
            "Permanent removal from the Elite Chauffeur Network.",
            "Repeated low ratings or client complaints will trigger an automatic review.",
          ],
          startIndex: 54,
        ),
        _buildSection(
          title: "CHAUFFEUR AGREEMENT",
          items: [
            "By accepting jobs through the platform, the chauffeur agrees to fully comply with this Ekkali Code of Conduct.",
          ],
          startIndex: 58,
        ),
        _buildSection(
          title: "INDEPENDENT PAYMENT RESPONSIBILITY",
          items: [
            "I acknowledge and agree that Ekkali Inc. does not collect, process, hold, invoice, or distribute payments of any kind.",
            "I acknowledge that I am an independent affiliate, and that Ekkali Inc. is not a payment processor, escrow service, broker, or financial intermediary.",
            "I understand and agree that I am solely and exclusively responsible for issuing invoices, collecting payments from clients, and settling payments with other affiliates when applicable.",
            "I agree that all payments are handled directly between the parties involved and must be completed using accepted professional methods, including credit/debit card, Zelle, Venmo, Cash App, or ACH transfer.",
            "I acknowledge and agree that Ekkali Inc. bears no responsibility or liability for payment disputes, non-payment, delays, chargebacks, or financial losses.",
            "I understand that failure to meet payment or professional obligations may result in temporary suspension or permanent removal from the Ekkali platform.",
          ],
          startIndex: 59,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required int startIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(text: title, fontSize: 13.sp, fontWeight: FontWeight.w600),
        SizedBox(height: 20.h),
        ...List.generate(items.length, (i) => _item(startIndex + i, items[i])),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _item(int index, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () => controller.toggleTermCheck(index),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.black200, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCheckbox(index),
              SizedBox(width: 10.w),
              Expanded(
                child: CustomTextgray(text: text, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(int index) {
    return Obx(() {
      final isChecked = controller.termChecks[index];
      return Container(
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF364153) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isChecked ? const Color(0xFF364153) : Colors.grey,
            width: 2,
          ),
        ),
        child: isChecked
            ? Icon(Icons.check, color: Colors.white, size: 18.sp)
            : null,
      );
    });
  }
}
