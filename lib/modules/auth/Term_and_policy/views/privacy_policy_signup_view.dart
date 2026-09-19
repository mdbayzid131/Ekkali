import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextGary.dart';
import 'package:moeb_26/core/widgets/custom_sub_appbar.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signup_controller.dart';

class TermSection {
  final String title;
  final List<String> items;
  final int startIndex;

  TermSection({
    required this.title,
    required this.items,
    required this.startIndex,
  });
}

class TermStep {
  final List<TermSection> subsections;

  TermStep({
    required this.subsections,
  });
}

class PrivacyPolicySignUpView extends StatefulWidget {
  const PrivacyPolicySignUpView({super.key});

  @override
  State<PrivacyPolicySignUpView> createState() =>
      _PrivacyPolicySignUpViewState();
}

class _PrivacyPolicySignUpViewState extends State<PrivacyPolicySignUpView> {
  late SignupController controller;

  // Reactive section index tracking
  final RxInt currentSectionIndex = 0.obs;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<SignupController>()
        ? Get.find<SignupController>()
        : Get.put(SignupController(), permanent: true);
  }

  final List<TermSection> originalSections = [
    TermSection(
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
    TermSection(
      title: "FRAGRANCE & HYGIENE",
      items: [
        "Fragrance must be fragrance-free or extremely light.",
        "Strong colognes, perfumes, or scented products are strictly prohibited.",
        "Breath must be clean and neutral. Smoking, vaping, or strong food odors prior to service are not permitted.",
      ],
      startIndex: 6,
    ),
    TermSection(
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
    TermSection(
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
    TermSection(
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
    TermSection(
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
    TermSection(
      title: "SAFETY & COMMUNICATION",
      items: [
        "No texting or handheld phone use while driving with a client onboard.",
        "Phone use is permitted hands-free only for navigation if necessary.",
        "Obey all traffic laws and drive smoothly at all times.",
        "Aggressive driving, speeding, or sudden braking is prohibited.",
      ],
      startIndex: 30,
    ),
    TermSection(
      title: "PUNCTUALITY & RELIABILITY",
      items: [
        "Arrive 10–15 minutes early for every pickup.",
        "Monitor flight status when applicable.",
        "Never cancel last-minute except in a true emergency.",
        "Immediately inform the company of any delays or issues.",
      ],
      startIndex: 34,
    ),
    TermSection(
      title: "CONFIDENTIALITY & RESPECT",
      items: [
        "All client information is strictly confidential.",
        "Do not discuss clients, routes, or conversations with anyone.",
        "Respect client privacy at all times.",
        "Treat all clients with equal respect, regardless of status or appearance.",
      ],
      startIndex: 38,
    ),
    TermSection(
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
    TermSection(
      title: "ASAP Jobs",
      items: [
        "“ASAP” means immediate service.",
        "Chauffeurs must be on location or within 10 minutes, verified by GPS, to accept the job.",
      ],
      startIndex: 51,
    ),
    TermSection(
      title: "PAYMENT",
      items: [
        "Once a job is completed, the job poster must pay the chauffeur within a maximum of 48 hours.",
      ],
      startIndex: 53,
    ),
    TermSection(
      title: "ENFORCEMENT",
      items: [
        "Violations may result in: Warning.",
        "Violations may result in: Temporary suspension.",
        "Permanent removal from the Elite Chauffeur Network.",
        "Repeated low ratings or client complaints will trigger an automatic review.",
      ],
      startIndex: 54,
    ),
    TermSection(
      title: "CHAUFFEUR AGREEMENT",
      items: [
        "By accepting jobs through the platform, the chauffeur agrees to fully comply with this Ekkali Code of Conduct.",
      ],
      startIndex: 58,
    ),
    TermSection(
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
  ];

  late final List<TermStep> steps = [
    TermStep(subsections: [originalSections[0]]), // 1. Appearance & Dress Code (6 items)
    TermStep(subsections: [originalSections[1]]), // 2. Fragrance & Hygiene (3 items)
    TermStep(subsections: [originalSections[2]]), // 3. Vehicle Standards (6 items)
    TermStep(subsections: [originalSections[3]]), // 4. Client Amenities (5 items)
    TermStep(subsections: [originalSections[4]]), // 5. Service & Professional Behavior (5 items)
    TermStep(subsections: [originalSections[5]]), // 6. Strict Professional Boundaries (5 items)
    TermStep(subsections: [originalSections[6]]), // 7. Safety & Communication (4 items)
    TermStep(subsections: [originalSections[7]]), // 8. Punctuality & Reliability (4 items)
    TermStep(subsections: [originalSections[8]]), // 9. Confidentiality & Respect (4 items)
    TermStep(subsections: [originalSections[9]]), // 10. Job Acceptance & Responsibility (9 items)
    TermStep(subsections: [originalSections[10], originalSections[11]]), // 11. ASAP Jobs & Payment Standards (3 items)
    TermStep(subsections: [originalSections[12], originalSections[13]]), // 12. Agreement & Enforcement (5 items)
    TermStep(subsections: [originalSections[14]]), // 13. Independent Payment Responsibility (6 items)
  ];

  bool _isAllSectionChecked(TermSection section) {
    for (int i = 0; i < section.items.length; i++) {
      if (!controller.termChecks[section.startIndex + i]) return false;
    }
    return true;
  }

  void _toggleAllInSection(TermSection section, bool check) {
    for (int i = 0; i < section.items.length; i++) {
      controller.termChecks[section.startIndex + i] = check;
    }
  }

  bool _isAllStepChecked(TermStep step) {
    for (var section in step.subsections) {
      if (!_isAllSectionChecked(section)) return false;
    }
    return true;
  }

  void _checkAndAutoAdvance(TermStep activeStep) {
    // 300ms delay for smooth visual feedback before advancing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isAllStepChecked(activeStep)) {
        if (currentSectionIndex.value < steps.length - 1) {
          currentSectionIndex.value++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomSubAppBar(title: "Terms & Conditions"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Obx(() {
            final activeStep = steps[currentSectionIndex.value];
            final progress = (currentSectionIndex.value + 1) / steps.length;

            return Column(
              children: [
                SizedBox(height: 15.h),
                // Core title banner
                Column(
                  children: [
                    CustomText(
                      text: "Chauffeur Code of Conduct &",
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    CustomText(
                      text: "Service Standards",
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                SizedBox(height: 15.h),

                // Step Progress Indicator
                _buildProgressIndicator(progress),
                SizedBox(height: 15.h),

                // Active step and its subsections
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: activeStep.subsections.expand((section) => [
                        // Subsection Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                section.title,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFD5C4AB),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildAgreeAllButton(section),
                          ],
                        ),
                        const Divider(color: Color(0xFF1E1E1E), height: 24),

                        // Section Items List
                        ...List.generate(
                          section.items.length,
                          (i) => _item(
                            section.startIndex + i,
                            section.items[i],
                            activeStep,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ]).toList(),
                    ),
                  ),
                ),

                // Footer Navigation Buttons
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.h),
                  child: Row(
                    children: [
                      if (currentSectionIndex.value > 0) ...[
                        Expanded(
                          flex: 1,
                          child: CustomButton(
                            text: "Back",
                            fontSize: 14.sp,
                            backgroundColor: const Color(0xFF1E1E1E),
                            textColor: Colors.white,
                            borderColor: const Color(0xFF364153),
                            onPressed: () {
                              currentSectionIndex.value--;
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        flex: currentSectionIndex.value == steps.length - 1 ? 2 : 1,
                        child: CustomButton(
                          text: currentSectionIndex.value == steps.length - 1
                              ? "Submit Application"
                              : "Continue",
                          fontSize: 14.sp,
                          loading: controller.isLoading.value,
                          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
                          onPressed: () {
                            // Check if current step items are fully checked
                            if (!_isAllStepChecked(activeStep)) {
                              Helpers.showCustomSnackBar(
                                "Please agree to all items above to continue.",
                                isError: true,
                              );
                              return;
                            }

                            if (currentSectionIndex.value < steps.length - 1) {
                              currentSectionIndex.value++;
                            } else {
                              controller.submitTermsAndContinue();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Stack(
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
    );
  }

  Widget _buildAgreeAllButton(TermSection section) {
    return Obx(() {
      final allChecked = _isAllSectionChecked(section);
      return TextButton.icon(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          _toggleAllInSection(section, !allChecked);
          if (!allChecked) {
            final activeStep = steps.firstWhere((step) => step.subsections.contains(section));
            _checkAndAutoAdvance(activeStep);
          }
        },
        icon: Icon(
          allChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
          color: const Color(0xFF364153),
          size: 18.sp,
        ),
        label: Text(
          allChecked ? "Agreed All" : "Agree All",
          style: GoogleFonts.inter(
            color: const Color(0xFFFFDCA1),
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    });
  }

  Widget _item(int index, String text, TermStep activeStep) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () {
          controller.toggleTermCheck(index);
          _checkAndAutoAdvance(activeStep);
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.black200, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCheckbox(index),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextgray(
                  text: text,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                ),
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
