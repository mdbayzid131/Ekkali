// Test doubles skip production service initialization and networking.
// ignore_for_file: must_call_super

import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moeb_26/config/constants/storage_constants.dart';
import 'package:moeb_26/core/services/account_status_sync.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/job_service.dart';
import 'package:moeb_26/core/services/marketplace_service.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/data/models/account_status.dart';
import 'package:moeb_26/data/repositories/user_profile_repository.dart';
import 'package:moeb_26/modules/jobs_offers/controllers/Job_offer_controller.dart';
import 'package:moeb_26/modules/market_place/controllers/market_place_controller.dart';

class _User extends UserService {
  @override
  void onInit() {}
}

Response feedResponse({int code = 200}) => Response(
  requestOptions: RequestOptions(path: '/feed'),
  statusCode: code,
  data: code == 403
      ? {'message': 'Your account is currently suspended.'}
      : {'data': []},
);

class _Jobs extends JobService {
  Completer<Response>? pending;
  @override
  void onInit() {}
  @override
  Future<Response> getAllJobOffers({String? cursor, int? limit}) =>
      pending?.future ?? Future.value(feedResponse());
}

class _Market extends MarketplaceService {
  Completer<Response>? pending;
  @override
  void onInit() {}
  @override
  Future<Response> getAllItems({
    String? searchTerm,
    String? condition,
    num? minPrice,
    num? maxPrice,
    int limit = 10,
    String? cursor,
  }) => pending?.future ?? Future.value(feedResponse());
}

class _JobController extends JobOfferController {
  int calls = 0;
  @override
  void onInit() {
    fetchJobOffers();
  }

  @override
  Future<void> fetchJobOffers({bool isRefresh = false}) async {
    calls++;
  }
}

class _MarketController extends MarketplaceController {
  int calls = 0;
  @override
  void onInit() {
    fetchItems();
  }

  @override
  Future<void> fetchItems({String? query, String? condition}) async {
    calls++;
  }
}

class _Adapter implements HttpClientAdapter {
  final started = Completer<void>();
  final result = Completer<ResponseBody>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancelFuture,
  ) {
    started.complete();
    return result.future;
  }

  @override
  void close({bool force = false}) {}
}

class _ProfileRepo implements UserProfileRepo {
  final started = Completer<void>();
  final result = Completer<Response>();
  @override
  Future<Response> getUserProfile() {
    started.complete();
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late _User user;
  late _Jobs jobs;
  late _Market market;
  setUp(() async {
    Get.testMode = true;
    await StorageService.clearAll();
    user = Get.put<UserService>(_User()) as _User;
    jobs = _Jobs();
    market = _Market();
    Get.put<JobService>(jobs);
    Get.put<MarketplaceService>(market);
  });
  tearDown(Get.reset);

  test('unknown status cannot reactivate a suspended account', () async {
    user.isRestricted = true;
    await AccountStatusSync.apply({'status': 'PENDING'});
    await AccountStatusSync.apply({'isRestricted': null});
    expect(user.isRestricted, isTrue);
    expect(AccountStatus.restrictionFrom({'isRestricted': 'false'}), isFalse);
    expect(
      AccountStatus.isSuspensionError({
        'message': 'Restricted to group members',
      }),
      isFalse,
    );
  });

  test(
    'socket and push refresh lazy feeds once per transition and persist',
    () async {
      Get.lazyPut<JobOfferController>(() => _JobController());
      Get.lazyPut<MarketplaceController>(() => _MarketController());
      await AccountStatusSync.apply({'isRestricted': true});
      await AccountStatusSync.apply({'status': 'SUSPENDED'});
      expect((Get.find<JobOfferController>() as _JobController).calls, 1);
      expect((Get.find<MarketplaceController>() as _MarketController).calls, 1);
      await AccountStatusSync.apply({'isRestricted': false});
      await AccountStatusSync.apply({'status': 'VERIFIED'});
      expect((Get.find<JobOfferController>() as _JobController).calls, 2);
      expect((Get.find<MarketplaceController>() as _MarketController).calls, 2);
      expect(
        await StorageService.getBool(StorageConstants.isRestricted),
        isFalse,
      );
      expect(Get.isSnackbarOpen, isFalse);
    },
  );

  test('feed response from an older restriction revision is ignored', () async {
    final controller = Get.put(JobOfferController());
    await Future<void>.delayed(Duration.zero);
    jobs.pending = Completer<Response>();
    final request = controller.fetchJobOffers();
    user.applyRealtimeRestriction(false);
    jobs.pending!.complete(feedResponse(code: 403));
    await request;
    expect(user.isRestricted, isFalse);
    expect(controller.errorMessage.value, isEmpty);
  });

  test(
    'marketplace response from an older restriction revision is ignored',
    () async {
      final controller = Get.put(MarketplaceController());
      await Future<void>.delayed(Duration.zero);
      market.pending = Completer<Response>();
      final request = controller.fetchItems();
      user.applyRealtimeRestriction(false);
      market.pending!.complete(feedResponse(code: 403));
      await request;
      expect(user.isRestricted, isFalse);
      expect(controller.errorMessage.value, isEmpty);
    },
  );

  test('Dio interceptor ignores stale suspension responses', () async {
    final client = Get.put(ApiClient());
    final adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    final request = client.getData('/jobs/feed');
    await adapter.started.future;
    user.applyRealtimeRestriction(false);
    adapter.result.complete(
      ResponseBody.fromString(
        '{"message":"Your account is currently suspended."}',
        403,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    await request;
    expect(user.isRestricted, isFalse);
  });

  test('Dio interceptor records a current suspension error', () async {
    final client = Get.put(ApiClient());
    final adapter = _Adapter();
    client.dio.httpClientAdapter = adapter;
    final request = client.getData('/jobs/feed');
    await adapter.started.future;
    adapter.result.complete(
      ResponseBody.fromString(
        '{"message":"Your account is currently suspended."}',
        403,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      ),
    );
    await request;
    expect(user.isRestricted, isTrue);
    expect(await StorageService.getBool(StorageConstants.isRestricted), isTrue);
  });

  test('late profile cannot overwrite realtime restriction', () async {
    await StorageService.setString(StorageConstants.bearerToken, 'test-token');
    await StorageService.setBool(StorageConstants.isApproved, true);
    final repo = _ProfileRepo();
    Get.put(UserProfileService(userProfileRepo: repo));
    final request = user.fetchUserId();
    await repo.started.future;
    user.applyRealtimeRestriction(true);
    repo.result.complete(
      Response(
        requestOptions: RequestOptions(path: '/profile'),
        statusCode: 200,
        data: {
          'data': {'_id': 'me', 'status': 'VERIFIED'},
        },
      ),
    );
    await request;
    expect(user.isRestricted, isTrue);
  });
}
