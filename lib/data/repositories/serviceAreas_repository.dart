// ignore: file_names
import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class ServiceAreasRepo {
  final ApiClient apiClient;

  ServiceAreasRepo({required this.apiClient});

  /// GET /api/v1/service-areas/options
  Future<Response> getAllServiceAreas({int? page, int? limit, String? cursor}) async {
    final Map<String, dynamic> queryParams = {};
    if (cursor != null && cursor.isNotEmpty) queryParams['cursor'] = cursor;
    if (limit != null) queryParams['limit'] = limit;

    return await apiClient.getData(
      ApiConstants.serviceAreas,
      query: queryParams.isNotEmpty ? queryParams : null,
    );
  }
}
