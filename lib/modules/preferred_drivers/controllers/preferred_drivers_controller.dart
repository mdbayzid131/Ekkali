import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/routes/app_pages.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/data/repositories/favorite_chauffeur_repository.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/modules/jobs_posts/controllers/job_post_controller.dart';

class ChauffeurReviewer {
  final String id;
  final String name;
  final String profilePicture;

  ChauffeurReviewer({
    required this.id,
    required this.name,
    required this.profilePicture,
  });

  factory ChauffeurReviewer.fromJson(Map<String, dynamic> json) {
    return ChauffeurReviewer(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Client',
      profilePicture: json['profilePicture']?.toString() ?? '',
    );
  }
}

class ChauffeurReview {
  final String jobId;
  final double rating;
  final String comment;
  final String reviewedAt;
  final ChauffeurReviewer? reviewer;

  ChauffeurReview({
    required this.jobId,
    required this.rating,
    required this.comment,
    required this.reviewedAt,
    this.reviewer,
  });

  factory ChauffeurReview.fromJson(Map<String, dynamic> json) {
    final double ratingVal = (json['rating'] is num)
        ? (json['rating'] as num).toDouble()
        : double.tryParse(json['rating']?.toString() ?? '5') ?? 5.0;

    return ChauffeurReview(
      jobId: json['jobId']?.toString() ?? '',
      rating: ratingVal,
      comment: json['comment']?.toString() ?? '',
      reviewedAt: json['reviewedAt']?.toString() ?? '',
      reviewer: json['reviewer'] is Map<String, dynamic>
          ? ChauffeurReviewer.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
    );
  }
}

class FavoriteChauffeur {
  final String id;
  final String name;
  final String? nickName;
  final String companyName;
  final String companyRole;
  final String carTag;
  final double rating;
  final String ratingCount;
  final String imageUrl;
  final String joinedDate;
  final String vehicleName;
  final String languages;
  final String phone;
  final String email;
  final String serviceArea;
  final List<String> badges;
  final String zelle;
  final String venmo;
  final String cashApp;
  final bool cardPaymentAccepted;
  final String reviewDate;
  final String reviewText;
  final String reviewerName;
  final String reviewerImageUrl;
  final bool isFavorite;

  FavoriteChauffeur({
    required this.id,
    required this.name,
    this.nickName,
    this.companyName = '',
    this.companyRole = 'Chauffeur',
    this.carTag = '',
    this.rating = 0.0,
    this.ratingCount = '',
    this.imageUrl = '',
    this.joinedDate = '',
    this.vehicleName = '',
    this.languages = '',
    this.phone = '',
    this.email = '',
    this.serviceArea = '',
    this.badges = const [],
    this.zelle = '',
    this.venmo = '',
    this.cashApp = '',
    this.cardPaymentAccepted = false,
    this.reviewDate = '',
    this.reviewText = '',
    this.reviewerName = '',
    this.reviewerImageUrl = '',
    this.isFavorite = true,
  });

  factory FavoriteChauffeur.fromJson(Map<String, dynamic> json) {
    final double ratingVal = (json['averageRating'] is num)
        ? (json['averageRating'] as num).toDouble()
        : double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0.0;

    final int reviewsVal = (json['totalReviews'] is int)
        ? json['totalReviews']
        : int.tryParse(json['totalReviews']?.toString() ?? '0') ?? 0;

    final List<String> badgesList = [];
    if (json['badges'] is List) {
      for (var b in json['badges']) {
        if (b != null && b.toString().isNotEmpty) {
          badgesList.add(b.toString());
        }
      }
    }

    // Parse paymentMethods object from API
    String zelleVal = '';
    String venmoVal = '';
    String cashAppVal = '';
    bool cardPaymentVal = false;

    if (json['paymentMethods'] is Map<String, dynamic>) {
      final pm = json['paymentMethods'] as Map<String, dynamic>;

      // Zelle
      if (pm['zelle'] is Map) {
        zelleVal =
            pm['zelle']['email']?.toString() ??
            pm['zelle']['phone']?.toString() ??
            pm['zelle']['username']?.toString() ??
            pm['zelle']['identifier']?.toString() ??
            '';
      } else if (pm['zelle'] is String) {
        zelleVal = pm['zelle'] as String;
      }

      // Venmo
      if (pm['venmo'] is Map) {
        venmoVal =
            pm['venmo']['username']?.toString() ??
            pm['venmo']['phone']?.toString() ??
            '';
      } else if (pm['venmo'] is String) {
        venmoVal = pm['venmo'] as String;
      }

      // CashApp
      if (pm['cashApp'] is Map) {
        cashAppVal =
            pm['cashApp']['cashtag']?.toString() ??
            pm['cashApp']['tag']?.toString() ??
            pm['cashApp']['username']?.toString() ??
            '';
      } else if (pm['cashApp'] is String) {
        cashAppVal = pm['cashApp'] as String;
      }

      // Card Payment
      if (pm['cardPayment'] is Map) {
        final status = pm['cardPayment']['status']?.toString();
        cardPaymentVal = (status == 'ACCEPTED' || status == 'ACTIVE');
      } else if (pm['cardPayment'] is bool) {
        cardPaymentVal = pm['cardPayment'] as bool;
      }
    } else {
      zelleVal = json['zelle']?.toString() ?? '';
      venmoVal = json['venmo']?.toString() ?? '';
      cashAppVal = json['cashApp']?.toString() ?? '';
      cardPaymentVal = json['cardPaymentAccepted'] == true;
    }

    return FavoriteChauffeur(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Chauffeur',
      nickName: json['nickname']?.toString() ?? json['nickName']?.toString(),
      phone: json['phone']?.toString() ?? '',
      serviceArea: json['serviceArea'] is Map
          ? (json['serviceArea']['areaName']?.toString() ??
              json['serviceArea']['name']?.toString() ??
              '')
          : (json['serviceArea']?.toString() ?? ''),
      companyName:
          json['company']?.toString() ??
          json['companyName']?.toString() ??
          'Elite Services',
      companyRole: json['companyRole']?.toString() ?? 'Chauffeur',
      imageUrl: json['profilePicture']?.toString() ?? '',
      rating: ratingVal,
      ratingCount: '($reviewsVal)',
      isFavorite: json['isFavorite'] == true,
      email: json['email']?.toString() ?? '',
      carTag: json['carTag']?.toString() ?? '',
      badges: badgesList,
      zelle: zelleVal,
      venmo: venmoVal,
      cashApp: cashAppVal,
      cardPaymentAccepted: cardPaymentVal,
      joinedDate: json['createdAt']?.toString() ?? '',
      languages: json['languages'] is List
          ? (json['languages'] as List).join(', ')
          : json['languages']?.toString() ?? 'English',
    );
  }

  FavoriteChauffeur copyWith({
    String? id,
    String? name,
    String? nickName,
    String? companyName,
    String? companyRole,
    String? carTag,
    double? rating,
    String? ratingCount,
    String? imageUrl,
    String? joinedDate,
    String? vehicleName,
    String? languages,
    String? phone,
    String? email,
    String? serviceArea,
    List<String>? badges,
    String? zelle,
    String? venmo,
    String? cashApp,
    bool? cardPaymentAccepted,
    String? reviewDate,
    String? reviewText,
    String? reviewerName,
    String? reviewerImageUrl,
    bool? isFavorite,
  }) {
    return FavoriteChauffeur(
      id: id ?? this.id,
      name: name ?? this.name,
      nickName: nickName ?? this.nickName,
      companyName: companyName ?? this.companyName,
      companyRole: companyRole ?? this.companyRole,
      carTag: carTag ?? this.carTag,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      imageUrl: imageUrl ?? this.imageUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      vehicleName: vehicleName ?? this.vehicleName,
      languages: languages ?? this.languages,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      serviceArea: serviceArea ?? this.serviceArea,
      badges: badges ?? this.badges,
      zelle: zelle ?? this.zelle,
      venmo: venmo ?? this.venmo,
      cashApp: cashApp ?? this.cashApp,
      cardPaymentAccepted: cardPaymentAccepted ?? this.cardPaymentAccepted,
      reviewDate: reviewDate ?? this.reviewDate,
      reviewText: reviewText ?? this.reviewText,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerImageUrl: reviewerImageUrl ?? this.reviewerImageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class PreferredDriversController extends GetxController {
  late final FavoriteChauffeurRepo _favoriteRepo;

  // Tab 1: My Favorites
  final RxList<FavoriteChauffeur> chauffeursList = <FavoriteChauffeur>[].obs;
  final Rxn<FavoriteChauffeur> selectedChauffeur = Rxn<FavoriteChauffeur>();
  final RxString searchQuery = ''.obs;

  final RxBool isLoading = false.obs;
  final RxBool isMoreLoading = false.obs;
  final RxnString nextCursor = RxnString();
  final RxBool hasMore = false.obs;

  final ScrollController scrollController = ScrollController();

  // Tab 2: Find Chauffeurs (Global Platform Directory)
  final RxList<FavoriteChauffeur> globalChauffeursList =
      <FavoriteChauffeur>[].obs;
  final RxString globalSearchQuery = ''.obs;

  final RxBool isGlobalLoading = false.obs;
  final RxBool isGlobalMoreLoading = false.obs;
  final RxnString globalNextCursor = RxnString();
  final RxBool globalHasMore = false.obs;

  final ScrollController globalScrollController = ScrollController();

  // Chauffeur Profile Reviews State
  final RxList<ChauffeurReview> reviewsList = <ChauffeurReview>[].obs;
  final RxBool isReviewsLoading = false.obs;
  final RxBool isMoreReviewsLoading = false.obs;
  final RxnString reviewsNextCursor = RxnString();
  final RxBool hasMoreReviews = false.obs;
  final ScrollController reviewsScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _favoriteRepo = Get.isRegistered<FavoriteChauffeurRepo>()
        ? Get.find<FavoriteChauffeurRepo>()
        : Get.put(FavoriteChauffeurRepo(apiClient: Get.find<ApiClient>()));

    fetchFavorites(isRefresh: true);
    fetchGlobalChauffeurs(isRefresh: true);

    scrollController.addListener(_onScroll);
    globalScrollController.addListener(_onGlobalScroll);
    reviewsScrollController.addListener(_onReviewsScroll);

    // Pure Server-side Search with 400ms Debounce for Tab 1 (Favorites)
    debounce(
      searchQuery,
      (_) => fetchFavorites(isRefresh: true),
      time: const Duration(milliseconds: 400),
    );

    // Pure Server-side Search with 400ms Debounce for Tab 2 (Global Directory)
    debounce(
      globalSearchQuery,
      (_) => fetchGlobalChauffeurs(isRefresh: true),
      time: const Duration(milliseconds: 400),
    );
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        hasMore.value &&
        !isMoreLoading.value &&
        !isLoading.value) {
      loadMoreFavorites();
    }
  }

  void _onGlobalScroll() {
    if (globalScrollController.position.pixels >=
            globalScrollController.position.maxScrollExtent - 200 &&
        globalHasMore.value &&
        !isGlobalMoreLoading.value &&
        !isGlobalLoading.value) {
      loadMoreGlobalChauffeurs();
    }
  }

  void _onReviewsScroll() {
    if (reviewsScrollController.hasClients &&
        reviewsScrollController.position.pixels >=
            reviewsScrollController.position.maxScrollExtent - 150 &&
        hasMoreReviews.value &&
        !isMoreReviewsLoading.value &&
        !isReviewsLoading.value) {
      final currentId = selectedChauffeur.value?.id;
      if (currentId != null && currentId.isNotEmpty) {
        loadMoreReviews(currentId);
      }
    }
  }

  // ===================== TAB 1: FAVORITES API (SERVER-SIDE) =====================
  Future<void> fetchFavorites({bool isRefresh = false}) async {
    if (isRefresh) {
      isLoading.value = true;
      nextCursor.value = null;
      hasMore.value = false;
    }

    try {
      final query = searchQuery.value.trim();
      final response = await _favoriteRepo.getFavorites(
        limit: 10,
        cursor: isRefresh ? null : nextCursor.value,
        searchTerm: query.isNotEmpty ? query : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> dataList = response.data?['data'] ?? [];
        final items = dataList
            .map((e) => FavoriteChauffeur.fromJson(e))
            .toList();

        final cursorData = response.data?['cursor'];
        if (cursorData != null) {
          nextCursor.value = cursorData['nextCursor'];
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        if (isRefresh) {
          chauffeursList.assignAll(items);
        } else {
          chauffeursList.addAll(items);
        }
      }
    } catch (e) {
      debugPrint("Error fetching favorite chauffeurs: $e");
    } finally {
      isLoading.value = false;
      isMoreLoading.value = false;
    }
  }

  Future<void> loadMoreFavorites() async {
    if (!hasMore.value || isMoreLoading.value || nextCursor.value == null) {
      return;
    }
    isMoreLoading.value = true;
    await fetchFavorites(isRefresh: false);
  }

  // Pure Server-side Results
  List<FavoriteChauffeur> get filteredChauffeursList => chauffeursList;

  // ===================== TAB 2: GLOBAL CHAUFFEURS API (SERVER-SIDE) =====================
  Future<void> fetchGlobalChauffeurs({bool isRefresh = false}) async {
    if (isRefresh) {
      isGlobalLoading.value = true;
      globalNextCursor.value = null;
      globalHasMore.value = false;
    }

    try {
      final query = globalSearchQuery.value.trim();
      final response = await _favoriteRepo.getAllChauffeurs(
        limit: 10,
        cursor: isRefresh ? null : globalNextCursor.value,
        searchTerm: query.isNotEmpty ? query : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> dataList = response.data?['data'] ?? [];
        final items = dataList
            .map((e) => FavoriteChauffeur.fromJson(e))
            .toList();

        final cursorData = response.data?['cursor'];
        if (cursorData != null) {
          globalNextCursor.value = cursorData['nextCursor'];
          globalHasMore.value = cursorData['hasMore'] == true;
        } else {
          globalHasMore.value = false;
        }

        if (isRefresh) {
          globalChauffeursList.assignAll(items);
        } else {
          globalChauffeursList.addAll(items);
        }
      }
    } catch (e) {
      debugPrint("Error fetching all chauffeurs: $e");
    } finally {
      isGlobalLoading.value = false;
      isGlobalMoreLoading.value = false;
    }
  }

  Future<void> loadMoreGlobalChauffeurs() async {
    if (!globalHasMore.value ||
        isGlobalMoreLoading.value ||
        globalNextCursor.value == null) {
      return;
    }
    isGlobalMoreLoading.value = true;
    await fetchGlobalChauffeurs(isRefresh: false);
  }

  // Pure Server-side Results
  List<FavoriteChauffeur> get filteredGlobalResults => globalChauffeursList;

  bool isInFavorites(String id) => chauffeursList.any((c) => c.id == id);

  Future<void> addToFavorites(FavoriteChauffeur chauffeur) async {
    if (!isInFavorites(chauffeur.id)) {
      try {
        final response = await _favoriteRepo.addFavorite(chauffeur.id);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final updatedChauffeur = chauffeur.copyWith(isFavorite: true);
          chauffeursList.add(updatedChauffeur);

          // Update current selectedChauffeur if open in profile view
          if (selectedChauffeur.value?.id == chauffeur.id) {
            selectedChauffeur.value = updatedChauffeur;
          }

          // Update in globalChauffeursList as well
          final globalIndex = globalChauffeursList.indexWhere(
            (c) => c.id == chauffeur.id,
          );
          if (globalIndex != -1) {
            globalChauffeursList[globalIndex] = updatedChauffeur;
          }

          if (Get.isRegistered<PostJobController>()) {
            Get.find<PostJobController>().fetchFavoriteDrivers();
          }

          Helpers.showCustomSnackBar(
            response.data?['message'] ??
                "${chauffeur.name} added to your favorites!",
            isError: false,
          );
        } else {
          Helpers.showCustomSnackBar(
            response.data?['message'] ?? "Could not add to favorites",
            isError: true,
          );
        }
      } catch (e) {
        debugPrint("Error adding to favorites: $e");
      }
    }
  }

  final RxBool isProfileLoading = false.obs;

  void viewProfile(FavoriteChauffeur chauffeur) {
    selectedChauffeur.value = chauffeur;
    reviewsList.clear();
    Get.toNamed(Routes.preferredDriverProfileView);
    fetchUserDetails(chauffeur.id);
  }

  void openChauffeurProfile({
    required String userId,
    String? name,
    String? imageUrl,
  }) {
    FavoriteChauffeur? existing;
    if (userId.isNotEmpty) {
      existing =
          chauffeursList.firstWhereOrNull((c) => c.id == userId) ??
          globalChauffeursList.firstWhereOrNull((c) => c.id == userId);
    }

    if (existing == null && name != null && name.trim().isNotEmpty) {
      final nameLower = name.trim().toLowerCase();
      existing =
          chauffeursList.firstWhereOrNull(
            (c) => c.name.toLowerCase() == nameLower,
          ) ??
          globalChauffeursList.firstWhereOrNull(
            (c) => c.name.toLowerCase() == nameLower,
          );
    }

    if (existing != null) {
      selectedChauffeur.value = existing;
    } else {
      selectedChauffeur.value = FavoriteChauffeur(
        id: userId,
        name: name ?? 'Chauffeur',
        imageUrl: imageUrl ?? '',
      );
    }

    reviewsList.clear();
    Get.toNamed(Routes.preferredDriverProfileView);
    if (userId.isNotEmpty) {
      fetchUserDetails(userId);
    }
  }

  Future<void> fetchUserDetails(String userId) async {
    if (userId.isEmpty) return;
    isProfileLoading.value = true;
    try {
      final response = await _favoriteRepo.getUserDetails(userId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final userData = response.data?['data'];
        if (userData != null) {
          final updated = FavoriteChauffeur.fromJson(userData);
          selectedChauffeur.value = updated;

          // If in favorites list, sync isFavorite status
          if (isInFavorites(updated.id)) {
            selectedChauffeur.value = updated.copyWith(isFavorite: true);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching chauffeur profile details: $e");
    } finally {
      isProfileLoading.value = false;
    }

    // Fetch dynamic reviews
    fetchUserReviews(userId, isRefresh: true);
  }

  // ===================== REVIEWS API (CURSOR PAGINATION) =====================
  Future<void> fetchUserReviews(String userId, {bool isRefresh = false}) async {
    if (userId.isEmpty) return;
    if (isRefresh) {
      isReviewsLoading.value = true;
      reviewsNextCursor.value = null;
      hasMoreReviews.value = false;
    }

    try {
      final response = await _favoriteRepo.getUserReviews(
        userId,
        limit: 5,
        cursor: isRefresh ? null : reviewsNextCursor.value,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> dataList = response.data?['data'] ?? [];
        final items = dataList.map((e) => ChauffeurReview.fromJson(e)).toList();

        final cursorData = response.data?['cursor'];
        if (cursorData != null) {
          reviewsNextCursor.value = cursorData['nextCursor'];
          hasMoreReviews.value = cursorData['hasMore'] == true;
        } else {
          hasMoreReviews.value = false;
        }

        if (isRefresh) {
          reviewsList.assignAll(items);
        } else {
          reviewsList.addAll(items);
        }
      }
    } catch (e) {
      debugPrint("Error fetching chauffeur reviews: $e");
    } finally {
      isReviewsLoading.value = false;
      isMoreReviewsLoading.value = false;
    }
  }

  Future<void> loadMoreReviews(String userId) async {
    if (!hasMoreReviews.value ||
        isMoreReviewsLoading.value ||
        reviewsNextCursor.value == null) {
      return;
    }
    isMoreReviewsLoading.value = true;
    await fetchUserReviews(userId, isRefresh: false);
  }

  Future<void> removeFromFavorites(FavoriteChauffeur chauffeur) async {
    try {
      final response = await _favoriteRepo.removeFavorite(chauffeur.id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        chauffeursList.removeWhere((c) => c.id == chauffeur.id);

        final updatedChauffeur = chauffeur.copyWith(isFavorite: false);
        if (selectedChauffeur.value?.id == chauffeur.id) {
          selectedChauffeur.value = updatedChauffeur;
        }

        final globalIndex = globalChauffeursList.indexWhere(
          (c) => c.id == chauffeur.id,
        );
        if (globalIndex != -1) {
          globalChauffeursList[globalIndex] = updatedChauffeur;
        }

        if (Get.isRegistered<PostJobController>()) {
          Get.find<PostJobController>().fetchFavoriteDrivers();
        }

        Helpers.showCustomSnackBar(
          response.data?['message'] ??
              "${chauffeur.name} removed from favorites",
          isError: false,
        );
      } else {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Could not remove from favorites",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error removing from favorites: $e");
    }
  }

  Future<void> startConversation(FavoriteChauffeur chauffeur) async {
    try {
      final SocketRepository socketRepo = Get.find<SocketRepository>();

      final chat = await socketRepo.createChat(chauffeur.id);
      if (chat != null) {
        Get.toNamed(Routes.chatDetailView, arguments: chat);
      } else {
        Helpers.showCustomSnackBar(
          "Could not start chat session with chauffeur.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("Error opening chauffeur chat: $e");
      Helpers.showCustomSnackBar(
        "Could not start chat session with chauffeur.",
        isError: true,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    globalScrollController.dispose();
    reviewsScrollController.dispose();
    super.onClose();
  }
}
