import 'package:get/get.dart';
import 'package:moeb_26/modules/auth/Term_and_policy/controller/legal_content_controller.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/change_pass_controller.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/otp_verification_controller.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/personal_document_controller.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/reset_password_controller.dart';
import 'package:moeb_26/modules/auth/authentication/controllers/signup_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChangePasswordController(), fenix: true);
    if (!Get.isRegistered<SignupController>()) {
      Get.put(SignupController(), permanent: true);
    }
    Get.lazyPut(() => OtpController(), fenix: true);
    Get.lazyPut(() => PersonalDocumentController(), fenix: true);
    Get.lazyPut(() => ResetPasswordController(), fenix: true);
    Get.lazyPut(() => LegalContentController(), fenix: true);
  }
}
