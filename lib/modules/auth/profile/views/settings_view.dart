import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/widgets/DeleteAccountBottomSheet.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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
              'Settings',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security & Account',
              style: GoogleFonts.inter(
                color: const Color(0xFFD5C4AB),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),

            Material(
              color: const Color(0xFF1A1A1A),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
                side: const BorderSide(
                  color: Color(0xFF2C2C2C),
                  width: 0.98,
                ),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.lock_outline_rounded,
                    title: "Password Change",
                    subtitle: "Update your account password",
                    onTap: () => Get.toNamed(Routes.changePasswordView),
                  ),
                  const Divider(
                    color: Color(0xFF2C2C2C),
                    thickness: 1,
                    height: 1,
                  ),
                  _buildSettingTile(
                    icon: Icons.delete_forever_outlined,
                    iconColor: Colors.redAccent,
                    title: "Delete Account",
                    titleColor: Colors.redAccent,
                    subtitle: "Permanently delete your account and data",
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (_) => const DeleteAccountBottomSheet(),
                        isScrollControlled: true,
                        useSafeArea: true,
                        enableDrag: false,
                        backgroundColor: Colors.transparent,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38.w,
        height: 38.w,
        decoration: BoxDecoration(
          color: const Color(0xFF27272A),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFFD5C4AB),
          size: 19.sp,
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: titleColor ?? Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                color: const Color(0xFF71717A),
                fontSize: 11.sp,
              ),
            )
          : null,
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: const Color(0xFF71717A),
        size: 14.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      onTap: onTap,
    );
  }
}
