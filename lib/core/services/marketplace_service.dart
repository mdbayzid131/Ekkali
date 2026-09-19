import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/data/repositories/marketplace_repository.dart';
import 'package:moeb_26/core/services/api_client.dart';

class MarketplaceService extends GetxService {
  late MarketplaceRepo _marketplaceRepo;

  @override
  void onInit() {
    super.onInit();
    _marketplaceRepo = MarketplaceRepo(apiClient: Get.find<ApiClient>());
  }

  Future<Response> getAllItems({
    String? searchTerm,
    String? condition,
    num? minPrice,
    num? maxPrice,
    int limit = 10,
    String? cursor,
  }) async {
    try {
      return await _marketplaceRepo.getAllItems(
        searchTerm: searchTerm,
        condition: condition,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: limit,
        cursor: cursor,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getMyItems({
    String? searchTerm,
    String? condition,
    num? minPrice,
    num? maxPrice,
    int limit = 10,
    String? cursor,
  }) async {
    try {
      return await _marketplaceRepo.getMyItems(
        searchTerm: searchTerm,
        condition: condition,
        minPrice: minPrice,
        maxPrice: maxPrice,
        limit: limit,
        cursor: cursor,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getItemById(String itemId) async {
    try {
      return await _marketplaceRepo.getItemById(itemId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> createItem({
    required String title,
    required String price,
    String? condition,
    required String location,
    String? description,
    List<File>? photos,
  }) async {
    try {
      return await _marketplaceRepo.createItem(
        title: title,
        price: price,
        condition: condition,
        location: location,
        description: description,
        photos: photos,
      );
    } catch (e) {
      rethrow;
    }
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
    try {
      return await _marketplaceRepo.updateItem(
        itemId: itemId,
        title: title,
        price: price,
        condition: condition,
        location: location,
        description: description,
        photos: photos,
        status: status,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> markItemAsSold(String itemId) async {
    try {
      return await _marketplaceRepo.markItemAsSold(itemId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> deleteItem(String itemId) async {
    try {
      return await _marketplaceRepo.deleteItem(itemId);
    } catch (e) {
      rethrow;
    }
  }
}
