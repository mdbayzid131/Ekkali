import 'package:get/get.dart';
import 'package:moeb_26/core/controllers/internet_controller.dart';
import 'package:moeb_26/core/services/expense_service.dart';
import 'package:moeb_26/data/repositories/auth_reporitory.dart';
import 'package:moeb_26/data/repositories/community_repository.dart';
import 'package:moeb_26/data/repositories/job_repository.dart';
import 'package:moeb_26/data/repositories/ratings_feedback_repository.dart';
import 'package:moeb_26/data/repositories/socket_repository.dart';
import 'package:moeb_26/data/repositories/support_repository.dart';
import 'package:moeb_26/data/repositories/user_profile_repository.dart';
import 'package:moeb_26/data/repositories/user_repository.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/auth_service.dart';
import 'package:moeb_26/core/services/job_service.dart';
import 'package:moeb_26/core/services/storege_service.dart';
import 'package:moeb_26/core/services/socket_service.dart';
import 'package:moeb_26/core/services/user_profile_service.dart';
import 'package:moeb_26/core/services/ratings_feedback_service.dart';
import 'package:moeb_26/core/services/user_service.dart';
import 'package:moeb_26/core/services/support_service.dart';
import 'package:moeb_26/core/services/community_service.dart';
import 'package:moeb_26/core/services/notifications_service.dart';
import 'package:moeb_26/core/services/vehicle_config_service.dart';
import 'package:moeb_26/data/repositories/compliance_document_repository.dart';
import 'package:moeb_26/data/repositories/invoice_repository.dart';
import 'package:moeb_26/core/services/invoice_service.dart';
import 'package:moeb_26/data/repositories/subscription_repository.dart';
import 'package:moeb_26/core/services/subscription_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core Infrastructure & Auth (Loaded immediately at startup)
    Get.put(InternetController(), permanent: true);
    Get.put(ApiClient(), permanent: true);
    Get.put(StorageService(), permanent: true);

    Get.put(AuthRepo(apiClient: Get.find()), permanent: true);
    Get.put(UserRepo(apiClient: Get.find()), permanent: true);
    Get.put(UserService(), permanent: true);
    Get.put(SocketRepository(apiClient: Get.find()), permanent: true);
    Get.put(SocketService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(VehicleConfigService(), permanent: true);
    Get.put(SubscriptionRepo(apiClient: Get.find()), permanent: true);
    Get.put(SubscriptionService(), permanent: true);

    // Feature Repositories & Services (Lazy loaded on-demand when accessed)
    Get.lazyPut(() => ComplianceDocumentRepository(apiClient: Get.find()), fenix: true);
    Get.lazyPut(() => UserProfileRepo(apiClient: Get.find()), fenix: true);
    Get.lazyPut(() => UserProfileService(userProfileRepo: Get.find()), fenix: true);

    Get.lazyPut(() => JobRepo(apiClient: Get.find()), fenix: true);
    Get.lazyPut(() => JobService(), fenix: true);

    Get.lazyPut(() => SupportRepo(apiClient: Get.find()), fenix: true);
    Get.lazyPut(() => SupportService(), fenix: true);

    Get.lazyPut(() => CommunityRepo(apiClient: Get.find()), fenix: true);
    Get.lazyPut(() => CommunityService(), fenix: true);

    Get.lazyPut(() => NotificationsService(), fenix: true);
    Get.lazyPut(() => ExpenseService(), fenix: true);

    Get.lazyPut(() => InvoiceService(), fenix: true);
    Get.lazyPut(() => InvoiceRepository(invoiceService: Get.find()), fenix: true);

    Get.lazyPut(() => RatingsFeedbackRepo(apiClient: Get.find()), fenix: true);
    Get.lazyPut(() => RatingsFeedbackService(ratingsFeedbackRepo: Get.find()), fenix: true);
  }
}
