import 'package:get/get.dart';
import '../controllers/support_ticket_detail_controller.dart';

class SupportTicketDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupportTicketDetailController>(
      () => SupportTicketDetailController(),
    );
  }
}
