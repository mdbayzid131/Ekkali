import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/models/ratings_feedback_model.dart';
import 'package:moeb_26/core/services/ratings_feedback_service.dart';

class RatingsFeedbackController extends GetxController {
  final RatingsFeedbackService _feedbackService =
      Get.find<RatingsFeedbackService>();

  var isLoading = false.obs;
  var averageRating = 0.0.obs;
  var totalReviews = 0.obs;
  var reviews = <Review>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    isLoading.value = true;
    try {
      var response = await _feedbackService.getReviews();
      if (response.statusCode == 200) {
        var data = response.data['data'];
        var model = RatingsModel.fromJson(data);

        averageRating.value = model.reviewSummary.averageRating;
        totalReviews.value = model.reviewSummary.totalReviews;
        reviews.value = model.reviews;
      } else {
        Helpers.showCustomSnackBar("Failed to load reviews", isError: true);
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
