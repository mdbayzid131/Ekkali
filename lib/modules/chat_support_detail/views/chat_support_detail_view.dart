import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/core/widgets/clickable_message_text.dart';
import '../controllers/chat_support_detail_controller.dart';
import '../../../data/models/chat_message_model.dart';

class SupportChatDetailView extends StatelessWidget {
  SupportChatDetailView({super.key});

  final SupportChatController controller = Get.put(SupportChatController());

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
            const Divider(color: Color(0xffDADADA), height: 1),
            // Messages List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
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
        icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: const Color(0xffE0E0E0),
            child: Icon(Icons.support_agent, color: Colors.black, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            'Support Chat',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: controller.socketService.isConnected.value
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.text.trim().isEmpty) return const SizedBox.shrink();

    return Obx(() {
      final String currentUserId = controller.userService.userId;
      final bool isMe = message.isSentBy(currentUserId);

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: 0.75.sw),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xff1A1A1A)
                      : const Color(0xff2A2A2A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                    bottomLeft: isMe ? Radius.circular(16.r) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : Radius.circular(16.r),
                  ),
                  border: Border.all(color: const Color(0xff333333)),
                ),
                child: ClickableMessageText(
                  text: message.text,
                  textStyle: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14.sp,
                    height: 1.4,
                    fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
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
    return Container(
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        bottom: 30.h,
        top: 10.h,
      ),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xffDADADA))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xff1A1A1A),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xffDADADA)),
              ),
              child: TextField(
                controller: controller.messageController,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(color: Colors.white),
                onSubmitted: (value) => controller.sendMessage(),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 16.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: () => controller.sendMessage(),
            child: SvgPicture.asset(
              AppIcons.send_message_icon,
              height: 24.sp,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
