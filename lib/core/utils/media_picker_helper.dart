import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickerHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Picks a single image from the gallery using Google Play-compliant system Photo Picker (No storage permissions required).
  static Future<File?> pickSingleImage([BuildContext? context]) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        return File(picked.path);
      }
    } catch (e) {
      debugPrint("Error picking single image: $e");
    }
    return null;
  }

  /// Picks multiple images from the gallery using Google Play-compliant system Photo Picker.
  static Future<List<File>?> pickMultiImages([
    BuildContext? context,
    int maxImages = 9,
  ]) async {
    try {
      final List<XFile> pickedList = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        limit: maxImages,
      );
      if (pickedList.isNotEmpty) {
        return pickedList.map((x) => File(x.path)).toList();
      }
    } catch (e) {
      debugPrint("Error picking multiple images: $e");
    }
    return null;
  }

  /// Shows dialog popup to choose between picking an image from Gallery or a PDF document.
  static Future<File?> showImageOrPdfPicker(BuildContext context) async {
    final String? action = await Get.dialog<String>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF374151),
                width: 1.w,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Upload Source",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(result: null),
                      child: Icon(Icons.close, color: Colors.grey, size: 20.sp),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                  title: Text(
                    "Image Gallery",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  subtitle: Text(
                    "Choose a photo from your library",
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 11.sp),
                  ),
                  onTap: () => Get.back(result: 'image'),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Colors.grey,
                    ),
                  ),
                  title: Text(
                    "PDF Document",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  subtitle: Text(
                    "Choose a PDF file from storage",
                    style: GoogleFonts.inter(color: Colors.grey, fontSize: 11.sp),
                  ),
                  onTap: () => Get.back(result: 'pdf'),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withAlpha(188),
    );

    if (action == 'image') {
      return await pickSingleImage();
    } else if (action == 'pdf') {
      try {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (result != null && result.files.single.path != null) {
          return File(result.files.single.path!);
        }
      } catch (e) {
        debugPrint("Error picking PDF: $e");
      }
    }

    return null;
  }
}
