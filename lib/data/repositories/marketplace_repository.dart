import 'dart:io';

import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class MarketplaceRepo {
  final ApiClient apiClient;
  MarketplaceRepo({required this.apiClient});

  Future<Response> getAllItems({
    String? searchTerm,
    String? condition,
    num? minPrice,
    num? maxPrice,
    int limit = 10,
    String? cursor,
  }) async {
    final Map<String, dynamic> queryParams = {'limit': limit};

    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }

    if (condition != null && condition.isNotEmpty) {
      queryParams['condition'] = condition;
    }

    if (minPrice != null) {
      queryParams['minPrice'] = minPrice;
    }

    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice;
    }

    return await apiClient.getData(ApiConstants.feedItems, query: queryParams);
  }

  Future<Response> getMyItems({
    String? searchTerm,
    String? condition,
    num? minPrice,
    num? maxPrice,
    int limit = 10,
    String? cursor,
  }) async {
    final Map<String, dynamic> queryParams = {'limit': limit};

    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      queryParams['searchTerm'] = searchTerm;
    }

    if (condition != null && condition.isNotEmpty) {
      queryParams['condition'] = condition;
    }

    if (minPrice != null) {
      queryParams['minPrice'] = minPrice;
    }

    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice;
    }

    return await apiClient.getData(ApiConstants.myItems, query: queryParams);
  }

  Future<Response> getItemById(String itemId) async {
    return await apiClient.getData('${ApiConstants.items}/$itemId');
  }

  Future<Response> createItem({
    required String title,
    required String price,
    String? condition,
    required String location,
    String? description,
    List<File>? photos,
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'price': num.tryParse(price) ?? price,
      'location': location,
    };

    if (condition != null && condition.isNotEmpty) {
      body['condition'] = condition;
    }

    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    final List<MultipartBody> multipartBody = photos != null
        ? photos.map((file) => MultipartBody('photos', file)).toList()
        : [];

    return await apiClient.postMultipartData(
      ApiConstants.items,
      body,
      multipartBody: multipartBody,
    );
  }

  Future<Response> updateItem({
    required String itemId,
    required String title,
    required String price,
    String? condition,
    required String location,
    String? description,
    List<File>? photos,
    String? status,
  }) async {
    final Map<String, dynamic> body = {
      'title': title,
      'price': num.tryParse(price) ?? price,
      'location': location,
    };

    if (condition != null && condition.isNotEmpty) {
      body['condition'] = condition;
    }

    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    if (status != null && status.isNotEmpty) {
      body['status'] = status;
    }

    final List<MultipartBody> multipartBody =
        photos != null && photos.isNotEmpty
        ? photos.map((file) => MultipartBody('photos', file)).toList()
        : [];

    return await apiClient.patchMultipartData(
      '${ApiConstants.items}/$itemId',
      body,
      multipartBody: multipartBody,
    );
  }

  Future<Response> markItemAsSold(String itemId) async {
    return await apiClient.patchData('${ApiConstants.items}/$itemId/sold', {});
  }

  Future<Response> deleteItem(String itemId) async {
    return await apiClient.deleteData('${ApiConstants.items}/$itemId');
  }
}
