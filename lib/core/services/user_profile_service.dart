import 'package:dio/dio.dart';
import 'package:moeb_26/data/repositories/user_profile_repository.dart';

class UserProfileService {
  final UserProfileRepo userProfileRepo;

  UserProfileService({required this.userProfileRepo});

  Future<Response> getUserProfile() {
    return userProfileRepo.getUserProfile();
  }

  Future<Response> patchProfile(dynamic body) {
    return userProfileRepo.patchProfile(body);
  }

  Future<Response> getServiceAreas() {
    return userProfileRepo.getServiceAreas();
  }

  Future<Response> getLegals() {
    return userProfileRepo.getLegals();
  }

  Future<Response> getLegalBySlug(String slug) {
    return userProfileRepo.getLegalBySlug(slug);
  }

  Future<Response> getVehicles() {
    return userProfileRepo.getVehicles();
  }

  Future<Response> getVehicleById(String vehicleId) {
    return userProfileRepo.getVehicleById(vehicleId);
  }

  Future<Response> addVehicle(dynamic body) {
    return userProfileRepo.addVehicle(body);
  }

  Future<Response> updateVehicle(String vehicleId, dynamic body) {
    return userProfileRepo.updateVehicle(vehicleId, body);
  }

  Future<Response> selectVehicle(String vehicleId) {
    return userProfileRepo.selectVehicle(vehicleId);
  }

  Future<Response> deleteVehicle(String vehicleId) {
    return userProfileRepo.deleteVehicle(vehicleId);
  }

  Future<Response> deleteAccount(String password) {
    return userProfileRepo.deleteAccount(password);
  }
}
