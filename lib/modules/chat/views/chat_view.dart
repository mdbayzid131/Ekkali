import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/services/subscription_service.dart';
import 'package:moeb_26/core/widgets/premium_lock_widget.dart';
import 'package:moeb_26/core/widgets/Custom_AppBar.dart';
import 'package:moeb_26/data/models/chat_model.dart';
import '../controllers/chat_controller.dart';
import 'package:moeb_26/core/services/chat_draft_service.dart';
import '../../../data/models/chat_community_model.dart';

class ChatView extends StatelessWidget {
  ChatView({super.key});

  final ChatController controller = Get.find<ChatController>();
  final UserService userService = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Chats', notificationCount: 3),
      body: GestureDetector(
        onTap: () => controller.clearDeleteSelection(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Obx(() {
              final isPrem = Get.isRegistered<SubscriptionService>()
                  ? Get.find<SubscriptionService>().isPremium.value
                  : false;

              if (!isPrem) {
                return const PremiumLockWidget(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "Unlock Chauffeur Community & Chat",
                  description:
                      "Subscribe to Ekkali Premium to message operators, network in community channels, and coordinate ride logistics.",
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),

                  // ── Search Bar ──
                  TextFormField(
                    onChanged: (value) => controller.filterChats(value),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search messages...',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 16.sp,
                      ),
                      filled: true,
                      fillColor: const Color(0xff1A1A1A),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(left: 12.w, right: 8.w),
                        child: Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 24.sp,
                        ),
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 40.w,
                        minHeight: 40.h,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: const Color(0xff242424),
                          width: 1.w,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: AppColors.primaryColor,
                          width: 1.w,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(
                          color: const Color(0xff242424),
                          width: 1.w,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // ── Chat List ──
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await controller.fetchChats();
                        await controller.fetchCommunityRoom();
                      },
                      color: AppColors.primaryColor,
                      backgroundColor: const Color(0xff1A1A1A),
                      child: Obx(() {
                        if (controller.isLoading.value &&
                            controller.chats.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final communityRoom = controller.communityRoom.value;

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount:
                              controller.filteredChats.length +
                              (communityRoom != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (communityRoom != null && index == 0) {
                            return _buildCommunityChatTile(communityRoom);
                          }

                          final chatIndex = communityRoom != null
                              ? index - 1
                              : index;
                          final chat = controller.filteredChats[chatIndex];
                          return _buildChatTile(chat);
                        },
                      );
                    }),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    ),
  );
}

  /// ── Community Chat Tile ──
  Widget _buildCommunityChatTile(CommunityRoom room) {
    final isUnread = !room.isRead || room.unreadCount > 0;

    return InkWell(
      onTap: () {
        controller.markCommunityAsRead();
        Get.toNamed(Routes.chatCommunityDetailView, arguments: room)?.then((_) {
          controller.markCommunityAsRead();
        });
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 56.r,
              height: 56.r,
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[700]!, width: 1.5),
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.8,
                  child: Image.asset(
                    'assets/images/ekkali chat.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "Live Chat",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (room.lastMessageAt != null)
                        Text(
                          _formatTime(room.lastMessageAt!),
                          style: GoogleFonts.inter(
                            color: isUnread ? Colors.white : Colors.grey,
                            fontSize: 12.sp,
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Obx(() {
                          final draft = ChatDraftService.drafts['community_${room.id}'];
                          if (draft != null && draft.trim().isNotEmpty) {
                            return RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Draft: ',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFEF5350),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: draft,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFA1A1AA),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Text(
                            room.lastMessage ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isUnread ? Colors.white : Colors.grey,
                              fontSize: 14.sp,
                              fontWeight:
                                  isUnread ? FontWeight.w700 : FontWeight.w400,
                            ),
                          );
                        }),
                      ),
                      if (isUnread) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ── Single Chat Tile ──
  Widget _buildChatTile(ChatPreview chat) {
    final other = chat.getOtherParticipant(userService.userId);
    final isUnread = !chat.isRead || chat.unreadCount > 0;

    return Dismissible(
      key: Key('chat_tile_${chat.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(chat);
      },
      background: Container(
        margin: EdgeInsets.symmetric(vertical: 4.h),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Delete",
              style: GoogleFonts.inter(
                color: const Color(0xFFF87171),
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.delete_outline_rounded,
              color: const Color(0xFFF87171),
              size: 20.sp,
            ),
          ],
        ),
      ),
      child: InkWell(
        onTap: () {
          // Mark locally as read when user taps to open
          controller.markChatAsRead(chat.id);
          Get.toNamed(Routes.chatDetailView, arguments: chat)?.then((_) {
            controller.markChatAsRead(chat.id);
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        splashColor: Colors.white10,
        highlightColor: Colors.white10,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              // ── Avatar ──
              _buildAvatar(chat),
              SizedBox(width: 12.w),

              // ── Chat Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            other?.name ?? 'Chat',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight:
                                  isUnread ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (chat.lastMessageAt != null)
                          Text(
                            _formatTime(chat.lastMessageAt!),
                            style: GoogleFonts.inter(
                              color: isUnread ? Colors.white : Colors.grey,
                              fontSize: 12.sp,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Last Message & Unread Dot
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Obx(() {
                            final draft = ChatDraftService.drafts[chat.id];
                            if (draft != null && draft.trim().isNotEmpty) {
                              return RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Draft: ',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFEF5350),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: draft,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFA1A1AA),
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Text(
                              (chat.lastMessage != null &&
                                      chat.lastMessage!.trim().isNotEmpty)
                                  ? chat.lastMessage!
                                  : 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: isUnread ? Colors.white : Colors.grey,
                                fontSize: 14.sp,
                                fontWeight:
                                    isUnread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            );
                          }),
                        ),
                        if (isUnread) ...[
                          SizedBox(width: 8.w),
                          Container(
                            width: 8.r,
                            height: 8.r,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(ChatPreview chat) async {
    final bool? confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: const Color(0xff1A1A1A),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Delete Chat?",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "Are you sure you want to delete this chat? This action cannot be undone.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 14.sp),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back(result: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        "Delete",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await controller.deleteChat(chat.id);
      return true;
    }
    return false;
  }

  /// ── Avatar Widget ──
  Widget _buildAvatar(ChatPreview chat) {
    final other = chat.getOtherParticipant(userService.userId);
    final isSupport = other != null &&
        (other.name.toLowerCase().contains('support') ||
            other.email?.toLowerCase().contains('support') == true);

    if (isSupport) {
      return Container(
        width: 56.r,
        height: 56.r,
        padding: EdgeInsets.all(2.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[700]!, width: 1.5),
        ),
        child: ClipOval(
          child: Transform.scale(
            scale: 1.3,
            child: Image.asset(
              'assets/images/ekkali support.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    final hasImage =
        other?.profilePicture != null && other!.profilePicture!.isNotEmpty;
    final isNetwork = hasImage && other.profilePicture!.startsWith('http');
    final isAsset = hasImage && !isNetwork;

    return Container(
      width: 56.r,
      height: 56.r,
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[700]!, width: 1.5),
      ),
      child: ClipOval(
        child: isAsset
            ? Transform.scale(
                scale: 1.3,
                child: Image.asset(other.profilePicture!, fit: BoxFit.contain),
              )
            : isNetwork
            ? Image.network(
                other.profilePicture!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _avatarFallback(other.initials),
              )
            : _avatarFallback(other?.initials),
      ),
    );
  }

  Widget _avatarFallback(String? initials) {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Text(
          initials ?? '?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        final hour = date.hour > 12 ? date.hour - 12 : date.hour;
        final minute = date.minute.toString().padLeft(2, '0');
        final period = date.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
