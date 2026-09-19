import 'package:get/get.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/data/repositories/favorite_chauffeur_repository.dart';
import '../controllers/preferred_drivers_controller.dart';

class PreferredDriversBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FavoriteChauffeurRepo>()) {
      Get.lazyPut(() => FavoriteChauffeurRepo(apiClient: Get.find<ApiClient>()));
    }
    Get.lazyPut(() => PreferredDriversController());
  }
}
