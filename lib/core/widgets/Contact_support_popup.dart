import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';
import 'package:moeb_26/core/widgets/CustomText.dart';
import 'package:moeb_26/core/widgets/CustomTextField.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/widgets/Custom_ButtonIcon.dart';
import '../../modules/auth/authentication/controllers/support_controller.dart';

// ============================================
// FUNCTION: Navigation helper for Contact Support
// ============================================
void showContactSupportBottomSheet() {
  Get.to(() => const ContactSupportView());
}

// ============================================
// WIDGET 1: Contact Support Tickets List View
// ============================================
class ContactSupportView extends StatefulWidget {
  const ContactSupportView({super.key});

  @override
  State<ContactSupportView> createState() => _ContactSupportViewState();
}

class _ContactSupportViewState extends State<ContactSupportView> {
  late final SupportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SupportController());
    controller.fetchMyTickets();
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
              'Support Tickets',
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
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.fetchMyTickets();
          },
          color: Colors.white,
          backgroundColor: const Color(0xFF111827),
          child: Obx(() {
            if (controller.isLoading.value && controller.tickets.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (controller.tickets.isEmpty) {
              return _buildEmptyState(context);
            }

            return ListView.builder(
              padding: EdgeInsets.all(20.w),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: controller.tickets.length,
              itemBuilder: (context, index) {
                final ticket = controller.tickets[index];
                return _buildTicketListItem(ticket);
              },
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const CreateSupportTicketView())?.then((_) {
            // Refresh list when returning
            controller.fetchMyTickets();
          });
        },
        backgroundColor: AppColors.primaryColor,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(
          "Create Ticket",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 0.75.sh,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF374151), width: 2),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                color: Colors.grey[500],
                size: 64.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "No Support Tickets Yet",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              "Have a question, issue, or need help? Create a support ticket and our team will get back to you shortly.",
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14.sp,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketListItem(dynamic ticket) {
    final hasMessages =
        ticket['messages'] != null && ticket['messages'].isNotEmpty;
    final lastMessage = hasMessages
        ? ticket['messages'].last['message']
        : 'No messages';
    final subject = ticket['subject'] ?? 'No Subject';
    final dateStr = _formatDate(ticket['createdAt']);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => controller.handleTicketTap(ticket),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      lastMessage,
                      style: GoogleFonts.inter(
                        color: Colors.grey[400],
                        fontSize: 13.sp,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        color: Colors.grey[600],
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[600],
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "";
    }
  }
}

// ============================================
// WIDGET 2: Contact Support Create Ticket View
// ============================================
class CreateSupportTicketView extends StatefulWidget {
  const CreateSupportTicketView({super.key});

  @override
  State<CreateSupportTicketView> createState() =>
      _CreateSupportTicketViewState();
}

class _CreateSupportTicketViewState extends State<CreateSupportTicketView> {
  final _formKey = GlobalKey<FormState>();
  late final SupportController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<SupportController>();
    controller.subjectController.clear();
    controller.messageController.clear();
    controller.selectedFiles.clear();
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
              'Create Support Ticket',
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
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSubjectField(controller.subjectController),
                  SizedBox(height: 24.h),

                  _buildMessageField(controller.messageController),
                  SizedBox(height: 24.h),

                  _buildAttachmentsField(context),
                  SizedBox(height: 24.h),

                  _buildInfoBox(),
                  SizedBox(height: 32.h),

                  _buildActionButtons(),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectField(TextEditingController textController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Customtextfield(
          controller: textController,
          hintText: "Enter subject",
          obscureText: false,
          textInputType: TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a subject";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageField(TextEditingController textController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: textController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a message";
            }
            if (value.length < 10) {
              return "Message must be at least 10 characters";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Describe your issue or question in detail...',
            hintStyle: TextStyle(
              color: const Color(0xFF6B7280),
              fontSize: 16.sp,
            ),
            filled: true,
            fillColor: const Color(0xFF111827),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Color(0xFF374151), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attachments (e.g. screenshots)',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => controller.pickAttachment(context),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryColor,
                    size: 20.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Add File',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),

        Obx(() {
          if (controller.selectedFiles.isEmpty) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: GestureDetector(
                onTap: () => controller.pickAttachment(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file, color: Colors.grey, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "No attachments selected. Tap to add.",
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SizedBox(
            height: 90.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.selectedFiles.length,
              itemBuilder: (context, index) {
                final file = controller.selectedFiles[index];
                final isImage =
                    file.path.toLowerCase().endsWith('.png') ||
                    file.path.toLowerCase().endsWith('.jpg') ||
                    file.path.toLowerCase().endsWith('.jpeg') ||
                    file.path.toLowerCase().endsWith('.webp');

                return Container(
                  margin: EdgeInsets.only(right: 12.w),
                  width: 90.w,
                  height: 90.h,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: const Color(0xFF374151)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: isImage
                                ? Image.file(file, fit: BoxFit.cover)
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.insert_drive_file,
                                          color: Colors.white70,
                                          size: 28.sp,
                                        ),
                                        SizedBox(height: 4.h),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4.w,
                                          ),
                                          child: Text(
                                            file.path.split('/').last,
                                            style: GoogleFonts.inter(
                                              color: Colors.white70,
                                              fontSize: 8.sp,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2.h,
                        right: 2.w,
                        child: GestureDetector(
                          onTap: () => controller.removeAttachment(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(4.r),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border.all(color: const Color(0xFF384555)),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2.h),
            child: SvgPicture.asset(
              AppIcons.message_icon,
              width: 24.w,
              height: 24.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Response Time',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Our support team typically responds within 24 hours during business days.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: const Color(0xFFC5B6B6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: "Cancel",
            backgroundColor: Colors.transparent,
            textColor: Colors.white,
            borderColor: Colors.white.withValues(alpha: 0.15),
            padding: EdgeInsets.symmetric(vertical: 14.h),
            onPressed: () {
              Get.back();
            },
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Obx(
            () => CustomButtonIcon(
              text: controller.isSubmitting.value
                  ? "Sending..."
                  : "Send Message",
              backgroundColor: AppColors.primaryColor,
              textColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              iconWidget: controller.isSubmitting.value
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : SvgPicture.asset(
                      AppIcons.send_icon,
                      width: 18.sp,
                      height: 18.sp,
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
              iconColor: Colors.black,
              iconOnRight: false,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  controller.createSupportTicket();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
