import 'package:get/get.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/data/repositories/compliance_document_repository.dart';
import '../controllers/personal_document_controller.dart';

class PersonalDocumentBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ComplianceDocumentRepository>()) {
      Get.lazyPut<ComplianceDocumentRepository>(
        () => ComplianceDocumentRepository(apiClient: Get.find<ApiClient>()),
        fenix: true,
      );
    }

    Get.lazyPut<PersonalDocumentController>(
      () => PersonalDocumentController(),
      fenix: true,
    );
  }
}
