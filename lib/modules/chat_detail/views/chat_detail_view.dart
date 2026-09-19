import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/constants/icon_paths.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';
import '../controllers/chat_detail_controller.dart';
import '../../../data/models/chat_message_model.dart';

class ChatDetailView extends StatelessWidget {
  ChatDetailView({super.key});

  final ChatDetailController controller = Get.find<ChatDetailController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          children: [
            // Messages List
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  controller: controller.scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 10.h,
                  ),
                  itemCount: controller.messages.length +
                      (controller.isLoadingMore.value ? 1 : 0),
                  reverse: true, // চ্যাটের জন্য লিস্টটি উল্টো দিক থেকে শুরু হবে
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    if (index == controller.messages.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFEDB9B),
                            ),
                          ),
                        ),
                      );
                    }
                    final message = controller.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              }),
            ),
            // Image Previews (Before sending)
            Obx(
              () => controller.selectedImages.isEmpty
                  ? const SizedBox.shrink()
                  : _buildImagePreviews(),
            ),
            // Reply Preview Bar
            _buildReplyPreviewBar(),
            // Bottom Input Field
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentUserId = controller.userService.userId;
    final other = controller.chat.getOtherParticipant(currentUserId);

    return PreferredSize(
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
          titleSpacing: 0,
          title: GestureDetector(
            onTap: (other?.name.toLowerCase() == 'support team' ||
                    other?.name.toLowerCase().contains('support') == true)
                ? null
                : () {
                    final preferredController =
                        Get.isRegistered<PreferredDriversController>()
                        ? Get.find<PreferredDriversController>()
                        : Get.put(PreferredDriversController());

                    preferredController.openChauffeurProfile(
                      userId: other?.id ?? '',
                      name: other?.name ?? 'Chauffeur',
                      imageUrl: other?.profilePicture ?? '',
                    );
                  },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[700]!, width: 1.5),
                  ),
                  child: ClipOval(
                    child: () {
                      final isSupport = other != null &&
                          (other.name.toLowerCase().contains('support') ||
                              other.email?.toLowerCase().contains('support') == true);
                      if (isSupport) {
                        return Transform.scale(
                          scale: 1.3,
                          child: Image.asset(
                            'assets/images/ekkali support.png',
                            fit: BoxFit.contain,
                          ),
                        );
                      }
                      final pic = other?.profilePicture;
                      final hasImage = pic != null && pic.isNotEmpty;
                      final isNetwork = hasImage && pic.startsWith('http');
                      if (hasImage && !isNetwork) {
                        return Transform.scale(
                          scale: 1.3,
                          child: Image.asset(pic, fit: BoxFit.contain),
                        );
                      } else if (hasImage && isNetwork) {
                        return Image.network(pic, fit: BoxFit.cover);
                      } else {
                        return CircleAvatar(
                          radius: 20.r,
                          backgroundColor: const Color(0xffE0E0E0),
                          child: Text(
                            other?.initials ?? '?',
                            style: GoogleFonts.inter(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                        );
                      }
                    }(),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  other?.name ?? 'Chat',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.w),
                // সকেট স্ট্যাটাস ইন্ডিকেটর
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
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.text.trim().isEmpty && message.attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final String currentUserId = controller.userService.userId;
      final bool isMe = message.isSentBy(currentUserId);
      final other = controller.chat.getOtherParticipant(currentUserId);

      final avatar = GestureDetector(
        onTap: (other?.name.toLowerCase() == 'support team' ||
                other?.name.toLowerCase().contains('support') == true)
            ? null
            : () {
                final preferredController =
                    Get.isRegistered<PreferredDriversController>()
                    ? Get.find<PreferredDriversController>()
                    : Get.put(PreferredDriversController());

                final targetId =
                    message.sender?.id ?? message.senderId ?? other?.id ?? '';
                final targetName =
                    message.sender?.name ?? other?.name ?? 'Chauffeur';
                final targetPic =
                    message.sender?.profilePicture ?? other?.profilePicture ?? '';

                preferredController.openChauffeurProfile(
                  userId: targetId,
                  name: targetName,
                  imageUrl: targetPic,
                );
              },
        child: Container(
          margin: EdgeInsets.only(right: 8.w, bottom: 4.h),
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[850]!, width: 1),
          ),
          child: ClipOval(
            child:
                other?.profilePicture != null && other!.profilePicture!.isNotEmpty
                ? (other.profilePicture!.startsWith('http')
                      ? Image.network(other.profilePicture!, fit: BoxFit.cover)
                      : Image.asset(other.profilePicture!, fit: BoxFit.cover))
                : Container(
                    color: Colors.grey[800],
                    child: Center(
                      child: Text(
                        other?.initials ?? '?',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      );

      final parsed = ReplyParsedMessage.parse(message.text);
      String? replyUser = parsed.replyToUser;
      String? replyText = parsed.replyToText;

      if (replyUser == null && message.replyToMessage != null) {
        final rMsg = message.replyToMessage!;
        replyUser = rMsg.isSentBy(currentUserId)
            ? 'You'
            : (rMsg.sender?.name ?? 'Someone');
        replyText = rMsg.text;
      } else if (replyUser == null && message.replyTo != null) {
        final original =
            controller.messages.firstWhereOrNull((m) => m.id == message.replyTo);
        if (original != null) {
          replyUser = original.isSentBy(currentUserId)
              ? 'You'
              : (original.sender?.name ?? 'Someone');
          replyText = original.text;
        }
      }

      if (replyText != null && replyText.startsWith('[REPLY:')) {
        replyText = replyText.split(']').skip(1).join(']');
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) avatar,
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPress: () => _showMessageOptions(Get.context!, message),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 0.70.sw),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? const Color(0xff1A1A1A)
                              : const Color(0xff2A2A2A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.r),
                            topRight: Radius.circular(16.r),
                            bottomLeft: isMe
                                ? Radius.circular(16.r)
                                : Radius.zero,
                            bottomRight: isMe
                                ? Radius.zero
                                : Radius.circular(16.r),
                          ),
                          border: Border.all(color: const Color(0xff33333E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message.attachments.isNotEmpty)
                              Column(
                                children: message.attachments
                                    .map(
                                      (url) => Padding(
                                        padding: EdgeInsets.only(bottom: 8.h),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            if (replyUser != null && replyText != null)
                              Container(
                                margin: EdgeInsets.only(bottom: 6.h),
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6.r),
                                  border: const Border(
                                    left: BorderSide(
                                      color: Color(0xFFD08700),
                                      width: 3,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      replyUser,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFD08700),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      replyText,
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontSize: 12.sp,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            if (parsed.messageText.trim().isNotEmpty)
                              Text(
                                parsed.messageText,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  height: 1.4,
                                  fontWeight: isMe
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                          ],
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
            ],
          ),
        ),
      );
    });
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 200.w,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: const Color(0xFF161619),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFF24242A), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.reply_rounded, color: Colors.white, size: 20),
                  title: Text(
                    'Reply',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Get.back();
                    controller.replyToMessage(message);
                  },
                ),
                const Divider(color: Color(0xFF22222A), height: 1),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                  title: Text(
                    'Copy',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Get.back();
                    controller.copyMessage(message);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreviewBar() {
    return Obx(() {
      if (controller.replyingTo.value == null) {
        return const SizedBox.shrink();
      }
      final replying = controller.replyingTo.value!;
      final parsed = ReplyParsedMessage.parse(replying.text);
      final senderName = replying.isSentBy(controller.userService.userId)
          ? 'You'
          : (replying.sender?.name ?? 'Someone');
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: const BoxDecoration(
          color: Color(0xFF141416),
          border: Border(
            top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
            left: BorderSide(color: Color(0xFFD08700), width: 4),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Replying to $senderName",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD08700),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    parsed.messageText,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () => controller.cancelReply(),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment
            .end, // Align items to bottom for multiline support
        children: [
          // Attachment Button
          PopupMenuButton<int>(
            offset: Offset(0, -110.h),
            color: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
              side: const BorderSide(color: Color(0xFF262626), width: 1),
            ),
            elevation: 8,
            onSelected: (value) {
              if (value == 1) {
                controller.takePhoto();
              } else if (value == 2) {
                controller.pickImage(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "Camera",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              PopupMenuItem<int>(
                value: 2,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      "Gallery",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              margin: EdgeInsets.only(
                bottom: 6.h,
              ), // align with bottom of textfield
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333), width: 1),
              ),
              child: Icon(Icons.add, color: Colors.white, size: 20.sp),
            ),
          ),
          SizedBox(width: 10.w),
          // Input field container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: const Color(0xFF262626), width: 1),
              ),
              child: TextField(
                controller: controller.messageController,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15.sp),
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF666666),
                    fontSize: 15.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Send Button
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: GestureDetector(
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
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviews() {
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Container(
                width: 80.w,
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  image: DecorationImage(
                    image: FileImage(controller.selectedImages[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => controller.removeImage(index),
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 14.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReplyParsedMessage {
  final String? replyToUser;
  final String? replyToText;
  final String messageText;

  ReplyParsedMessage({
    this.replyToUser,
    this.replyToText,
    required this.messageText,
  });

  factory ReplyParsedMessage.parse(String rawText) {
    final regex = RegExp(r'^\[REPLY:([^|]*)\|([^\]]*)\]([\s\S]*)$');
    final match = regex.firstMatch(rawText);
    if (match != null) {
      return ReplyParsedMessage(
        replyToUser: match.group(1),
        replyToText: match.group(2),
        messageText: match.group(3) ?? '',
      );
    }
    return ReplyParsedMessage(messageText: rawText);
  }
}
