import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/market_place_model.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'CustomButton.dart';

class ContactSellerPopup extends StatefulWidget {
  final ItemData item;

  const ContactSellerPopup({super.key, required this.item});

  @override
  State<ContactSellerPopup> createState() => _ContactSellerPopupState();
}

class _ContactSellerPopupState extends State<ContactSellerPopup> {
  final TextEditingController _messageController = TextEditingController();
  final SocketRepository _socketRepo = Get.find();
  int _charCount = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _charCount = _messageController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24.r),
        ),
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Contact Seller",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(Icons.close, color: Colors.grey, size: 24.sp),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // Item Info Card
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1E1E1E,
                  ), // Slightly lighter than background to stand out
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFF242424)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child:
                          (widget.item.photos != null &&
                              widget.item.photos!.isNotEmpty)
                          ? Image.network(
                              widget.item.photos!.first,
                              height: 60.w,
                              width: 60.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildNoImagePlaceholder(),
                            )
                          : _buildNoImagePlaceholder(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.title ?? '',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            "\$${widget.item.price}",
                            style: GoogleFonts.inter(
                              color: AppColors.primaryColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // Message Label
              Text(
                "Your Message",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10.h),
              // Message Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 500,
                  style: GoogleFonts.inter(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 14.sp,
                    ),
                    counterText: "",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(15.w),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "$_charCount/500 characters",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12.sp),
              ),
              SizedBox(height: 24.h),
              _isSending
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    )
                  : CustomButton(
                      text: "Send Message",
                      backgroundColor: AppColors.primaryColor,
                      textColor: Colors.black,
                      onPressed: () async {
                        final text = _messageController.text.trim();
                        if (text.isEmpty) {
                          Helpers.showCustomSnackBar('Please enter a message', isError: true);
                          return;
                        }

                        setState(() => _isSending = true);
                        try {
                          final chat = await _socketRepo.createChat(
                            widget.item.createdBy?.id ?? '',
                          );
                          if (chat != null) {
                            await _socketRepo.sendMessage(chat.id, text);
                            Get.back(); // Close popup
                            Get.toNamed(Routes.chatDetailView, arguments: chat);
                          }
                        } catch (e) {
                          Helpers.showCustomSnackBar('Failed to contact seller', isError: true);
                        } finally {
                          if (mounted) setState(() => _isSending = false);
                        }
                      },
                    ),
              SizedBox(height: 12.h),
              CustomButton(
                text: "Cancel",
                backgroundColor: const Color(0xFF1E1E1E),
                textColor: Colors.white,
                borderColor: const Color(0xFF242424),
                onPressed: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      height: 60.w,
      width: 60.w,
      color: Colors.grey[900],
      child: Icon(Icons.image_not_supported, color: Colors.grey, size: 24.sp),
    );
  }
}
