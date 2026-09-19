import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class ImagePreviewPopup extends StatelessWidget {
  final File? file;
  final String? imageUrl;
  final String title;

  const ImagePreviewPopup({
    super.key,
    this.file,
    this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isLocalPdf = file != null && file!.path.toLowerCase().endsWith('.pdf');
    final isNetworkPdf = imageUrl != null && imageUrl!.toLowerCase().contains('.pdf');
    final isPdf = isLocalPdf || isNetworkPdf;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close Button
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
            ),
          ),
          // Image / PDF Container
          Flexible(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: isPdf
                    ? (file != null
                        ? const PDF(
                            swipeHorizontal: false,
                            enableSwipe: true,
                            autoSpacing: true,
                            pageFling: true,
                          ).fromPath(
                            file!.path,
                          )
                        : const PDF(
                            swipeHorizontal: false,
                            enableSwipe: true,
                            autoSpacing: true,
                            pageFling: true,
                          ).cachedFromUrl(
                            imageUrl!,
                            placeholder: (progress) => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            ),
                            errorWidget: (error) =>
                                _buildErrorWidget('Failed to load network PDF'),
                          ))
                    : InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: file != null
                            ? Image.file(
                                file!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : (imageUrl != null && imageUrl!.isNotEmpty)
                                ? (imageUrl!.startsWith('http')
                                    ? Image.network(
                                        imageUrl!,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primaryColor,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildPlaceholder(),
                                      )
                                    : Image.asset(
                                        imageUrl!,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildPlaceholder(),
                                      ))
                                : _buildPlaceholder(),
                      ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          // Title
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
