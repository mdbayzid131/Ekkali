import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class ExpenseService extends GetxService {
  late ApiClient _apiClient;

  @override
  void onInit() {
    super.onInit();
    _apiClient = Get.find<ApiClient>();
  }

  Future<ExpenseService> init() async {
    return this;
  }

  /// Fetch list of expenses with optional date range filters and cursor pagination
  Future<Response> fetchExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? cursor,
    int limit = 1000,
  }) async {
    final Map<String, dynamic> query = {
      'limit': limit,
    };
    if (cursor != null && cursor.isNotEmpty) {
      query['cursor'] = cursor;
    }
    if (startDate != null) {
      query['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      query['endDate'] = endDate.toUtc().toIso8601String();
    }

    return await _apiClient.getData(
      ApiConstants.expenses,
      query: query,
    );
  }

  /// Fetch total expense amount with optional date range filters
  Future<Response> fetchTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final Map<String, dynamic> query = {};
    if (startDate != null) {
      query['startDate'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      query['endDate'] = endDate.toUtc().toIso8601String();
    }

    return await _apiClient.getData(
      ApiConstants.expensesTotal,
      query: query,
    );
  }

  /// Create a new expense (supports optional receipt file upload)
  Future<Response> createExpense({
    required String category,
    required double amount,
    required DateTime date,
    String? description,
    File? receiptFile,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    if (receiptFile != null) {
      return await _apiClient.postMultipartData(
        ApiConstants.expenses,
        body,
        multipartBody: [MultipartBody('receipt', receiptFile)],
      );
    } else {
      return await _apiClient.postData(
        ApiConstants.expenses,
        body,
      );
    }
  }

  /// Update an existing expense by ID
  Future<Response> updateExpense(
    String id, {
    String? category,
    double? amount,
    DateTime? date,
    String? description,
    File? receiptFile,
  }) async {
    final body = <String, dynamic>{};
    if (category != null) body['category'] = category;
    if (amount != null) body['amount'] = amount;
    if (date != null) body['date'] = date.toUtc().toIso8601String();
    if (description != null) body['description'] = description;

    final uri = '${ApiConstants.expenses}/$id';

    if (receiptFile != null) {
      return await _apiClient.patchMultipartData(
        uri,
        body,
        multipartBody: [MultipartBody('receipt', receiptFile)],
      );
    } else {
      return await _apiClient.patchData(
        uri,
        body,
      );
    }
  }

  /// Delete an expense by ID
  Future<Response> deleteExpense(String id) async {
    return await _apiClient.deleteData('${ApiConstants.expenses}/$id');
  }
}
