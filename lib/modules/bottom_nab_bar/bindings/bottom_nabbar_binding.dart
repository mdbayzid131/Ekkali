import 'package:get/get.dart';
import 'package:moeb_26/modules/bottom_nab_bar/controllers/bottom_nabbar_controller.dart';
import 'package:moeb_26/modules/chat/controllers/chat_controller.dart';
import 'package:moeb_26/modules/deals/controllers/deals_controller.dart';
import 'package:moeb_26/modules/jobs_posts/controllers/job_post_controller.dart';
import 'package:moeb_26/modules/market_place/controllers/market_place_controller.dart';
import 'package:moeb_26/modules/my_jobs/controllers/my_jobs_controller.dart';
import 'package:moeb_26/modules/rides/controllers/rides_controller.dart';
import 'package:moeb_26/modules/preferred_drivers/controllers/preferred_drivers_controller.dart';
import 'package:moeb_26/modules/auth/profile/controllers/profile_controller.dart';

class BottomNabbarBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NavigationController());
    Get.put(ChatController());
    Get.lazyPut(() => RidesController(), fenix: true);
    Get.lazyPut(() => BookingController(), fenix: true);
    Get.lazyPut(() => MarketplaceController(), fenix: true);
    Get.lazyPut(() => DealsController(), fenix: true);
    Get.lazyPut(() => PostJobController(), fenix: true);
    Get.lazyPut(() => PreferredDriversController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
  }
}

