import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/data/models/support_ticket_model.dart';
import '../controllers/support_ticket_detail_controller.dart';

class SupportTicketDetailView extends GetView<SupportTicketDetailController> {
  const SupportTicketDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            const Divider(color: Color(0xff2A2A2A), height: 1),

            // Top Ticket Status Header Banner
            _buildTicketInfoBanner(),

            // Messages Stream
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (controller.messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  itemCount: controller.messages.length,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              }),
            ),

            // Bottom Input Field
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xff222222),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => Text(
                    controller.subject.value,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Support Ticket",
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Container(
              margin: EdgeInsets.only(right: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _getStatusBgColor(controller.status.value),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: _getStatusColor(
                    controller.status.value,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                controller.status.value.toUpperCase(),
                style: GoogleFonts.inter(
                  color: _getStatusColor(controller.status.value),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfoBanner() {
    return Obx(() {
      final subject = controller.subject.value;
      final createdAt = controller.createdAt.value;
      if (subject.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: const Border(
            bottom: BorderSide(color: Color(0xFF222222), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 16.sp,
              color: Colors.grey[500],
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                subject,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (createdAt.isNotEmpty)
              Text(
                _formatDate(createdAt),
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 11.sp,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: const Color(0xFF181818),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333)),
              ),
              child: Icon(
                Icons.mark_chat_unread_outlined,
                color: AppColors.primaryColor,
                size: 40.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "No Messages Yet",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Your ticket has been received. You can reply below to send additional info to our support team.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey[400],
                fontSize: 12.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    if (message.text.trim().isEmpty && message.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final bool isMe = controller.isMessageFromMe(message);
      final String displayName = message.senderName.isNotEmpty
          ? message.senderName
          : 'Support Team';

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.support_agent_rounded,
                        size: 14.sp,
                        color: AppColors.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        displayName,
                        style: GoogleFonts.inter(
                          color: AppColors.primaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                constraints: BoxConstraints(maxWidth: 0.78.sw),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xff1A1A1A)
                      : const Color(0xff2A2A2D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: isMe
                        ? Radius.circular(16.r)
                        : Radius.circular(4.r),
                    bottomRight: isMe
                        ? Radius.circular(4.r)
                        : Radius.circular(16.r),
                  ),
                  border: Border.all(
                    color: isMe
                        ? const Color(0xff33333E)
                        : const Color(0xff3D3D42),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (message.text.trim().isNotEmpty)
                      Text(
                        message.text,
                        textAlign: isMe ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          height: 1.4,
                          fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    if (message.attachments.isNotEmpty) ...[
                      if (message.text.trim().isNotEmpty) SizedBox(height: 8.h),
                      ...message.attachments.map(
                        (url) => Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              url,
                              width: 180.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  message.time,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildMessageInput() {
    return Obx(() {
      if (controller.isTicketClosed) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 14.h,
            bottom: 24.h,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF141414),
            border: Border(top: BorderSide(color: Color(0xFF222222))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "This ticket is ${controller.status.value.toLowerCase()}. Replies are disabled.",
                style: GoogleFonts.inter(
                  color: Colors.grey[400],
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          bottom: 24.h,
          top: 8.h,
        ),
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Color(0xff222222))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment Preview Thumbnails (if selected)
            Obx(() {
              if (controller.selectedAttachments.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                height: 70.h,
                margin: EdgeInsets.only(bottom: 8.h),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.selectedAttachments.length,
                  itemBuilder: (context, index) {
                    final file = controller.selectedAttachments[index];
                    return Container(
                      margin: EdgeInsets.only(right: 8.w),
                      width: 70.w,
                      height: 70.h,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 2.h,
                            right: 2.w,
                            child: GestureDetector(
                              onTap: () => controller.removeAttachment(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                padding: EdgeInsets.all(3.r),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
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

            // Input Row
            Row(
              children: [
                // Attachment Picker Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.attach_file_rounded,
                    color: Colors.grey[400],
                    size: 24.sp,
                  ),
                  onPressed: () => controller.pickAttachments(),
                ),
                SizedBox(width: 8.w),

                // Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff1A1A1A),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: const Color(0xff333333)),
                    ),
                    child: TextField(
                      controller: controller.messageController,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                      onSubmitted: (_) => controller.sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Reply to this ticket...",
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 14.sp,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),

                // Send Button
                Obx(
                  () => GestureDetector(
                    onTap: controller.isSending.value
                        ? null
                        : () => controller.sendMessage(),
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: controller.isSending.value
                          ? SizedBox(
                              width: 18.sp,
                              height: 18.sp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : SvgPicture.asset(
                              AppIcons.send_message_icon,
                              height: 18.sp,
                              colorFilter: const ColorFilter.mode(
                                Colors.black,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
      case 'COMPLETED':
        return const Color(0xFF22C55E);
      case 'IN_PROGRESS':
        return AppColors.primaryColor;
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Color _getStatusBgColor(String status) {
    return _getStatusColor(status).withValues(alpha: 0.15);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return "";
    }
  }
}
