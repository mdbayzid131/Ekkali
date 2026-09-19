import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class FavoriteChauffeurRepo {
  final ApiClient apiClient;
  FavoriteChauffeurRepo({required this.apiClient});

  /// GET /api/v1/users/favorites
  Future<Response> getFavorites({
    int limit = 10,
    String? cursor,
    String? searchTerm,
  }) async {
    final Map<String, dynamic> queryParams = {'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }
    return await apiClient.getData(ApiConstants.favorites, query: queryParams);
  }

  /// GET /api/v1/users/chauffeurs
  Future<Response> getAllChauffeurs({
    int limit = 10,
    String? cursor,
    String? searchTerm,
  }) async {
    final Map<String, dynamic> queryParams = {'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }
    return await apiClient.getData(ApiConstants.chauffeurs, query: queryParams);
  }

  /// POST /api/v1/users/favorites/:chauffeurId
  Future<Response> addFavorite(String chauffeurId) async {
    return await apiClient.postData('${ApiConstants.favorites}/$chauffeurId', {});
  }

  /// DELETE /api/v1/users/favorites/:chauffeurId
  Future<Response> removeFavorite(String chauffeurId) async {
    return await apiClient.deleteData('${ApiConstants.favorites}/$chauffeurId');
  }

  /// GET /api/v1/users/:userId
  Future<Response> getUserDetails(String userId) async {
    return await apiClient.getData('${ApiConstants.users}/$userId');
  }

  /// GET /api/v1/users/:userId/reviews
  Future<Response> getUserReviews(
    String userId, {
    int limit = 5,
    String? cursor,
  }) async {
    final Map<String, dynamic> queryParams = {'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    return await apiClient.getData(
      '${ApiConstants.users}/$userId/reviews',
      query: queryParams,
    );
  }
}
