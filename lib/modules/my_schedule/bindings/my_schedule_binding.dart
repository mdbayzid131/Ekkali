import 'package:get/get.dart';
import 'package:moeb_26/modules/my_schedule/controllers/my_schedule_controller.dart';

class MyScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MyScheduleController>(() => MyScheduleController());
  }
}
