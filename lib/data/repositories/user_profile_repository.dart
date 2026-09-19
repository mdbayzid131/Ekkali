import 'package:dio/dio.dart';
import 'package:moeb_26/config/constants/api_constants.dart';
import 'package:moeb_26/core/services/api_client.dart';

class UserProfileRepo {
  final ApiClient apiClient;

  UserProfileRepo({required this.apiClient});

  Future<Response> getUserProfile() {
    return apiClient.getData(ApiConstants.userProfile);
  }

  Future<Response> patchProfile(dynamic body) {
    return apiClient.patchData(ApiConstants.userProfile, body);
  }

  Future<Response> getServiceAreas() {
    return apiClient.getData(ApiConstants.serviceAreas);
  }

  Future<Response> getLegals() {
    return apiClient.getData(ApiConstants.legals);
  }

  Future<Response> getLegalBySlug(String slug) {
    return apiClient.getData(
      ApiConstants.legalsBySlug.replaceFirst('{{slug}}', slug),
    );
  }

  Future<Response> getVehicles() {
    return apiClient.getData(ApiConstants.vehicles);
  }

  Future<Response> getVehicleById(String vehicleId) {
    return apiClient.getData('${ApiConstants.vehicles}/$vehicleId');
  }

  Future<Response> addVehicle(dynamic body) {
    return apiClient.postData(ApiConstants.vehicles, body);
  }

  Future<Response> updateVehicle(String vehicleId, dynamic body) {
    return apiClient.patchData(
      '${ApiConstants.vehicles}/$vehicleId',
      body,
    );
  }

  Future<Response> selectVehicle(String vehicleId) {
    return apiClient.patchData(
      '${ApiConstants.vehicles}/$vehicleId/select',
      {},
    );
  }

  Future<Response> deleteVehicle(String vehicleId) {
    return apiClient.deleteData(
      '${ApiConstants.vehicles}/$vehicleId',
    );
  }

  Future<Response> deleteAccount(String password) {
    return apiClient.deleteData(
      ApiConstants.deleteAccount,
      body: {'password': password},
    );
  }
}
