import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/data/repositories/serviceAreas_repository.dart';
import 'package:moeb_26/core/services/api_client.dart';

class ServiceAreaService extends GetxService {
  late ServiceAreasRepo _serviceAreasRepo;

  @override
  void onInit() {
    super.onInit();
    _serviceAreasRepo = ServiceAreasRepo(apiClient: Get.find<ApiClient>());
  }

  Future<Response> getAllServiceAreas({int limit = 50, String? cursor, int? page}) async {
    try {
      return await _serviceAreasRepo.getAllServiceAreas(
        page: page,
        limit: limit,
        cursor: cursor,
      );
    } catch (e) {
      rethrow;
    }
  }
}
