import 'package:get/get.dart';
import 'package:moeb_26/modules/jobs_offers/controllers/Job_offer_controller.dart';
import 'package:moeb_26/modules/jobs_offers/views/Job_offer_view.dart';

class JobOfferBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobOfferController>(() => JobOfferController());
    Get.lazyPut(() => const JobOfferView());
  }
}

