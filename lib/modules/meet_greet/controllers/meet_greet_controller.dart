import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moeb_26/core/utils/helpers.dart';

class MeetGreetThemeData {
  final Color backgroundColor;
  final Color cardColor;
  final Color borderColor;
  final Color headerColor;
  final Color nameColor;
  final Color subtitleColor;
  final Color accentColor;

  const MeetGreetThemeData({
    this.backgroundColor = const Color(0xFF000000),
    this.cardColor = const Color(0xFF161618),
    this.borderColor = const Color(0xFF364153),
    this.headerColor = const Color(0xFFD5C4AB),
    this.nameColor = Colors.white,
    this.subtitleColor = const Color(0xFFC5A880),
    this.accentColor = const Color(0xFFD5C4AB),
  });
}

class MeetGreetController extends GetxController {
  // Main reactive fields
  var passengerName = 'JOHN SMITH'.obs;
  var subtitleText = 'FLIGHT BG-088'.obs;
  var showCompanyLogo = false.obs;
  var customLogoPath = RxnString();
  var isLandscape = false.obs;
  var isFullscreen = false.obs;
  var fontSizeScale = 1.0.obs;

  Future<void> pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        customLogoPath.value = image.path;
      }
    } catch (e) {
      Helpers.showCustomSnackBar('Could not access gallery: $e', isError: true);
    }
  }

  static const MeetGreetThemeData defaultTheme = MeetGreetThemeData();
  MeetGreetThemeData get currentTheme => defaultTheme;

  @override
  void onInit() {
    super.onInit();
    resetOrientation();
  }

  @override
  void onClose() {
    exitFullscreen();
    resetOrientation();
    super.onClose();
  }

  void enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    isFullscreen.value = true;
  }

  void exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    isFullscreen.value = false;
  }

  void unlockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void resetOrientation() {
    isLandscape.value = false;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
