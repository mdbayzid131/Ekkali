import 'package:get/get.dart';
import 'package:moeb_26/modules/auth/Term_and_policy/controller/legal_content_controller.dart';

class TermPolicyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LegalContentController(), fenix: true);
  }
}
