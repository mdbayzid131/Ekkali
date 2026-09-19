import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:moeb_26/data/models/invoice_model.dart';
import 'package:moeb_26/data/repositories/invoice_repository.dart';
import 'package:moeb_26/modules/invoice/views/invoice_preview_view.dart';
import 'package:moeb_26/core/utils/validators.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import 'package:moeb_26/core/widgets/CustomButton.dart';

class InvoiceHistoryRecord {
  final String? id;
  final String invoiceNumber;
  final String clientName;
  final String clientEmail;
  final DateTime issuedDate;
  final String currency;
  final String status; // 'Paid', 'Unpaid'
  final double totalAmount;

  // New fields to preserve full invoice details
  final String clientBusinessName;
  final String clientPhone;
  final String invoiceDescription;
  final String clientStreetAddress;
  final String clientCity;
  final String clientState;
  final String clientZip;
  final String clientCountry;
  final String messageToClient;
  final String dueDate;
  final String businessName;
  final String businessEmail;
  final String businessPhone;
  final String businessWebsite;
  final String businessAddress;
  final String businessLogoPath;

  InvoiceHistoryRecord({
    this.id,
    required this.invoiceNumber,
    required this.clientName,
    required this.clientEmail,
    required this.issuedDate,
    required this.currency,
    required this.status,
    required this.totalAmount,
    required this.clientBusinessName,
    required this.clientPhone,
    required this.invoiceDescription,
    required this.clientStreetAddress,
    required this.clientCity,
    required this.clientState,
    required this.clientZip,
    required this.clientCountry,
    required this.messageToClient,
    required this.dueDate,
    required this.businessName,
    required this.businessEmail,
    required this.businessPhone,
    required this.businessWebsite,
    required this.businessAddress,
    required this.businessLogoPath,
  });

  InvoiceHistoryRecord copyWith({String? status, String? id}) {
    return InvoiceHistoryRecord(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber,
      clientName: clientName,
      clientEmail: clientEmail,
      issuedDate: issuedDate,
      currency: currency,
      status: status ?? this.status,
      totalAmount: totalAmount,
      clientBusinessName: clientBusinessName,
      clientPhone: clientPhone,
      invoiceDescription: invoiceDescription,
      clientStreetAddress: clientStreetAddress,
      clientCity: clientCity,
      clientState: clientState,
      clientZip: clientZip,
      clientCountry: clientCountry,
      messageToClient: messageToClient,
      dueDate: dueDate,
      businessName: businessName,
      businessEmail: businessEmail,
      businessPhone: businessPhone,
      businessWebsite: businessWebsite,
      businessAddress: businessAddress,
      businessLogoPath: businessLogoPath,
    );
  }
}

class SavedClient {
  final String id;
  final String name;
  final String businessName;
  final String email;
  final String phone;
  final String streetAddress;
  final String city;
  final String state;
  final String zip;
  final String country;

  SavedClient({
    required this.id,
    required this.name,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
  });

  SavedClient copyWith({
    String? id,
    String? name,
    String? businessName,
    String? email,
    String? phone,
    String? streetAddress,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) {
    return SavedClient(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      country: country ?? this.country,
    );
  }

  factory SavedClient.fromJson(Map<String, dynamic> json) {
    final billing = json['billingAddress'] as Map<String, dynamic>?;
    return SavedClient(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['clientName'] as String? ?? json['name'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      email: json['emailAddress'] as String? ?? json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String? ?? '',
      streetAddress:
          json['streetAddress'] as String? ??
          billing?['streetAddress'] as String? ??
          '',
      city: json['city'] as String? ?? billing?['city'] as String? ?? '',
      state: json['state'] as String? ?? billing?['state'] as String? ?? '',
      zip:
          json['zipCode'] as String? ??
          billing?['zipCode'] as String? ??
          json['zip'] as String? ??
          '',
      country:
          json['country'] as String? ??
          billing?['country'] as String? ??
          'United States',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clientName': name,
      'businessName': businessName,
      'emailAddress': email,
      'phoneNumber': phone,
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'zipCode': zip,
      'country': country,
    };
  }
}

class InvoiceController extends GetxController {
  final InvoiceRepository _invoiceRepo = Get.find<InvoiceRepository>();
  var isLoading = false.obs;

  // Navigation / Page Step
  var currentStep = 1.obs;
  var editingRecordIndex = (-1).obs;

  // Step 1: Basic Information
  late TextEditingController invoiceNumberController;
  late TextEditingController invoiceAmountController;
  var issuedDate = DateTime.now().obs;
  var selectedDueDateOption = 'On Receipt'.obs;
  var customDueDate = Rxn<DateTime>();
  var selectedCurrency = 'USD - US Dollar'.obs;
  var invoiceStatus = 'Unpaid'.obs;

  // Step 1 Validation Errors
  var invoiceNumberError = ''.obs;
  var invoiceAmountError = ''.obs;
  var customDueDateError = ''.obs;

  // Step 2: Client Details
  late TextEditingController clientNameController;
  late TextEditingController clientBusinessNameController;
  late TextEditingController clientEmailController;
  late TextEditingController clientPhoneController;

  // Billing Address
  late TextEditingController clientStreetAddressController;
  late TextEditingController clientCityController;
  late TextEditingController clientStateController;
  late TextEditingController clientZipController;
  var clientCountry = 'United States'.obs;

  // Step 2 Validation Errors
  var clientNameError = ''.obs;
  var clientEmailError = ''.obs;
  var clientPhoneError = ''.obs;
  var clientStreetAddressError = ''.obs;
  var clientCityError = ''.obs;
  var clientStateError = ''.obs;
  var clientZipError = ''.obs;

  // Step 3: Message to Client
  late TextEditingController invoiceDescriptionController;
  late TextEditingController messageToClientController;

  // --- PROFILE SETTING FIELDS ---
  late TextEditingController businessNameController;
  late TextEditingController businessEmailController;
  late TextEditingController businessPhoneController;
  late TextEditingController businessWebsiteController;
  late TextEditingController businessAddressController;
  var businessLogoPath = RxnString();
  var savedBusinessName = ''.obs;

  // --- INVOICE HISTORY & SAVED CLIENTS ---
  var invoiceHistory = <InvoiceHistoryRecord>[].obs;
  var savedClients = <SavedClient>[].obs;
  var selectedSavedClient = Rxn<SavedClient>();
  var selectedFilter = 'All'.obs;
  var selectedTemplateIndex = 0.obs;
  var selectedColorIndex = 0.obs;

  final List<Color> templateColors = [
    Colors.black, // White/Black theme
    const Color(0xFF2563EB), // Blue
    const Color(0xFF16A34A), // Green
    const Color(0xFFEA580C), // Orange
    const Color(0xFF7C3AED), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFF78350F), // Brown
  ];

  // Available options
  final List<String> dueDateOptions = ['On Receipt', 'Custom Due Date'];

  final List<String> currencyOptions = ['USD - US Dollar'];

  final List<String> countryOptions = [
    'United States',
    'Bangladesh',
    'United Kingdom',
    'Canada',
    'Germany',
    'India',
    'United Arab Emirates',
  ];

  @override
  void onInit() {
    super.onInit();
    invoiceNumberController = TextEditingController();
    invoiceAmountController = TextEditingController();

    // Step 2: Client Details
    clientNameController = TextEditingController();
    clientBusinessNameController = TextEditingController();
    clientEmailController = TextEditingController();
    clientPhoneController = TextEditingController();

    // Billing Address
    clientStreetAddressController = TextEditingController();
    clientCityController = TextEditingController();
    clientStateController = TextEditingController();
    clientZipController = TextEditingController();

    // Step 3: Message
    invoiceDescriptionController = TextEditingController();
    messageToClientController = TextEditingController(
      text: 'Thank you for your business!',
    );

    // Profile Settings controllers
    businessNameController = TextEditingController();
    businessEmailController = TextEditingController();
    businessPhoneController = TextEditingController();
    businessWebsiteController = TextEditingController();
    businessAddressController = TextEditingController();

    // Auto-clear error messages on text change
    invoiceNumberController.addListener(() {
      if (invoiceNumberError.value.isNotEmpty) invoiceNumberError.value = '';
    });
    invoiceAmountController.addListener(() {
      if (invoiceAmountError.value.isNotEmpty) invoiceAmountError.value = '';
    });
    clientNameController.addListener(() {
      if (clientNameError.value.isNotEmpty) clientNameError.value = '';
    });
    clientEmailController.addListener(() {
      if (clientEmailError.value.isNotEmpty) clientEmailError.value = '';
    });
    clientPhoneController.addListener(() {
      if (clientPhoneError.value.isNotEmpty) clientPhoneError.value = '';
    });
    clientStreetAddressController.addListener(() {
      if (clientStreetAddressError.value.isNotEmpty) {
        clientStreetAddressError.value = '';
      }
    });
    clientCityController.addListener(() {
      if (clientCityError.value.isNotEmpty) clientCityError.value = '';
    });
    clientStateController.addListener(() {
      if (clientStateError.value.isNotEmpty) clientStateError.value = '';
    });
    clientZipController.addListener(() {
      if (clientZipError.value.isNotEmpty) clientZipError.value = '';
    });

    // Fetch data from backend API
    fetchInvoicesFromApi();
    fetchClientsFromApi();
    fetchInvoiceProfileFromApi();

    // Ensure all validation errors start empty
    clearValidationErrors();
  }

  void clearValidationErrors() {
    invoiceNumberError.value = '';
    invoiceAmountError.value = '';
    customDueDateError.value = '';
    clientNameError.value = '';
    clientEmailError.value = '';
    clientPhoneError.value = '';
    clientStreetAddressError.value = '';
    clientCityError.value = '';
    clientStateError.value = '';
    clientZipError.value = '';
  }

  // --- SAVED CLIENTS ACTIONS ---
  void selectSavedClient(SavedClient client) {
    selectedSavedClient.value = client;
    clientNameController.text = client.name;
    clientBusinessNameController.text = client.businessName;
    clientEmailController.text = client.email;
    clientPhoneController.text = client.phone;
    clientStreetAddressController.text = client.streetAddress;
    clientCityController.text = client.city;
    clientStateController.text = client.state;
    clientZipController.text = client.zip;
    if (countryOptions.contains(client.country)) {
      clientCountry.value = client.country;
    }
    Helpers.showCustomSnackBar(
      'Loaded details for ${client.name}',
      isError: false,
    );
  }

  Future<void> fetchClientsFromApi() async {
    try {
      isLoading.value = true;
      final response = await _invoiceRepo.fetchClients();
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'];
          final clients = list
              .map((item) => SavedClient.fromJson(item as Map<String, dynamic>))
              .toList();
          savedClients.assignAll(clients);
        }
      }
    } catch (e) {
      debugPrint('Error fetching clients from API: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String _extractErrorMessage(dynamic error, {String defaultMsg = 'Something went wrong.'}) {
    if (error is dio.DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data['message'] != null &&
              data['message'].toString().trim().isNotEmpty) {
            return data['message'].toString();
          }
          if (data['errorMessages'] is List &&
              (data['errorMessages'] as List).isNotEmpty) {
            final first = (data['errorMessages'] as List)[0];
            if (first is Map && first['message'] != null) {
              return first['message'].toString();
            }
          }
        }
      }
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    } else if (error is Map) {
      if (error['message'] != null &&
          error['message'].toString().trim().isNotEmpty) {
        return error['message'].toString();
      }
      if (error['errorMessages'] is List &&
          (error['errorMessages'] as List).isNotEmpty) {
        final first = (error['errorMessages'] as List)[0];
        if (first is Map && first['message'] != null) {
          return first['message'].toString();
        }
      }
    }
    return error?.toString() ?? defaultMsg;
  }

  Future<bool> addOrUpdateSavedClient(SavedClient client) async {
    // Only genuine 24-character MongoDB hex ObjectIDs represent existing backend clients
    final isEditing =
        client.id.isNotEmpty &&
        !client.id.startsWith('temp_') &&
        RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(client.id);

    try {
      isLoading.value = true;
      final dio.Response response;
      if (isEditing) {
        response = await _invoiceRepo.updateClient(
          client.id,
          client.toJson(),
        );
      } else {
        // Send POST /api/v1/invoices/client to create new client on backend
        response = await _invoiceRepo.createClient(client.toJson());
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data['data'] != null) {
          final saved = SavedClient.fromJson(response.data['data']);
          if (isEditing) {
            final idx = savedClients.indexWhere((c) => c.id == client.id);
            if (idx != -1) savedClients[idx] = saved;
          } else {
            final existingIndex = savedClients.indexWhere(
              (c) =>
                  c.id == saved.id ||
                  (c.name.toLowerCase() == saved.name.toLowerCase() &&
                      saved.name.isNotEmpty),
            );
            if (existingIndex != -1) {
              savedClients[existingIndex] = saved;
            } else {
              savedClients.add(saved);
            }
          }
        }
        Helpers.showCustomSnackBar(
          isEditing
              ? 'Client updated successfully'
              : 'New client added successfully',
          isError: false,
        );
        return true;
      } else {
        final errorMsg = _extractErrorMessage(
          response.data,
          defaultMsg: 'Failed to save client.',
        );
        Helpers.showCustomSnackBar(errorMsg, isError: true);
        return false;
      }
    } catch (e) {
      debugPrint('Error saving client to API: $e');
      final errorMsg = _extractErrorMessage(e, defaultMsg: 'Failed to save client.');
      Helpers.showCustomSnackBar(errorMsg, isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSavedClient(String id) async {
    savedClients.removeWhere((c) => c.id == id);
    if (selectedSavedClient.value?.id == id) {
      selectedSavedClient.value = null;
    }
    if (id.isNotEmpty &&
        !id.startsWith('temp_') &&
        RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(id)) {
      try {
        await _invoiceRepo.deleteClient(id);
      } catch (e) {
        debugPrint('Error deleting client from API: $e');
      }
    }
  }

  @override
  void onClose() {
    invoiceNumberController.dispose();
    invoiceAmountController.dispose();
    clientNameController.dispose();
    clientBusinessNameController.dispose();
    clientEmailController.dispose();
    clientPhoneController.dispose();
    clientStreetAddressController.dispose();
    clientCityController.dispose();
    clientStateController.dispose();
    clientZipController.dispose();
    invoiceDescriptionController.dispose();
    messageToClientController.dispose();

    businessNameController.dispose();
    businessEmailController.dispose();
    businessPhoneController.dispose();
    businessWebsiteController.dispose();
    businessAddressController.dispose();
    super.onClose();
  }

  // Getters
  String get formattedIssuedDate =>
      DateFormat('MMM dd, yyyy').format(issuedDate.value);

  String get formattedDueDate {
    if (selectedDueDateOption.value == 'No Due Date') {
      return 'No Due Date';
    } else if (selectedDueDateOption.value == 'On Receipt') {
      return 'On Receipt';
    } else if (selectedDueDateOption.value == 'Custom Due Date') {
      if (customDueDate.value != null) {
        return DateFormat('MMM dd, yyyy').format(customDueDate.value!);
      }
      return 'Select Date';
    } else {
      // Days options like '10 days'
      final days = int.tryParse(selectedDueDateOption.value.split(' ')[0]) ?? 0;
      final dueDate = issuedDate.value.add(Duration(days: days));
      return DateFormat('MMM dd, yyyy').format(dueDate);
    }
  }

  // Actions
  void selectDueDateOption(String option, BuildContext context) async {
    selectedDueDateOption.value = option;
    if (option == 'Custom Due Date') {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate:
            customDueDate.value ??
            issuedDate.value.add(const Duration(days: 1)),
        firstDate: issuedDate.value,
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFEDB9B), // Soft peach-yellow
                onPrimary: Colors.black,
                surface: Color(0xFF1E1E1E),
                onSurface: Colors.white,
              ),
              dialogTheme: const DialogThemeData(
                backgroundColor: Color(0xFF1E1E1E),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        customDueDate.value = picked;
      } else {
        // Fallback if cancelled
        selectedDueDateOption.value = 'On Receipt';
      }
    }
  }

  void pickIssuedDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: issuedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFEDB9B), // Soft peach-yellow
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      issuedDate.value = picked;
      // Reset custom due date if it becomes before the issued date
      if (customDueDate.value != null &&
          customDueDate.value!.isBefore(issuedDate.value)) {
        customDueDate.value = null;
        selectedDueDateOption.value = 'On Receipt';
      }
    }
  }

  bool validateStep1() {
    bool isValid = true;

    final amountErr = Validators.amount(
      invoiceAmountController.text,
      message: 'Enter a valid amount (> 0)',
      min: 0.01,
    );
    invoiceAmountError.value = amountErr ?? '';
    if (amountErr != null) isValid = false;

    if (selectedDueDateOption.value == 'Custom Due Date' &&
        customDueDate.value == null) {
      customDueDateError.value = 'Please select a custom due date';
      isValid = false;
    } else {
      customDueDateError.value = '';
    }

    return isValid;
  }

  bool validateStep2() {
    bool isValid = true;

    final nameErr = Validators.name(
      clientNameController.text,
      message: 'Client name is required',
      minLength: 2,
    );
    clientNameError.value = nameErr ?? '';
    if (nameErr != null) isValid = false;

    final emailErr = Validators.email(
      clientEmailController.text,
      message: 'Enter a valid email address',
    );
    clientEmailError.value = emailErr ?? '';
    if (emailErr != null) isValid = false;

    if (clientPhoneController.text.trim().isNotEmpty) {
      final phoneErr = Validators.phone(
        clientPhoneController.text,
        message: 'Enter a valid phone number',
      );
      clientPhoneError.value = phoneErr ?? '';
      if (phoneErr != null) isValid = false;
    } else {
      clientPhoneError.value = '';
    }

    final streetErr = Validators.required(
      clientStreetAddressController.text,
      message: 'Street address is required',
    );
    clientStreetAddressError.value = streetErr ?? '';
    if (streetErr != null) isValid = false;

    final cityErr = Validators.required(
      clientCityController.text,
      message: 'City is required',
    );
    clientCityError.value = cityErr ?? '';
    if (cityErr != null) isValid = false;

    final stateErr = Validators.required(
      clientStateController.text,
      message: 'State/Province is required',
    );
    clientStateError.value = stateErr ?? '';
    if (stateErr != null) isValid = false;

    final zipErr = Validators.required(
      clientZipController.text,
      message: 'ZIP/Postal code is required',
    );
    clientZipError.value = zipErr ?? '';
    if (zipErr != null) isValid = false;

    return isValid;
  }

  bool validateAll() {
    final v1 = validateStep1();
    final v2 = validateStep2();
    if (!v1) {
      currentStep.value = 1;
      return false;
    }
    if (!v2) {
      currentStep.value = 2;
      return false;
    }
    return true;
  }

  void nextStep() {
    if (currentStep.value == 1) {
      if (!validateStep1()) return;
      currentStep.value = 2;
    } else if (currentStep.value == 2) {
      if (!validateStep2()) return;
      currentStep.value = 3;
    } else if (currentStep.value == 3) {
      if (!validateAll()) return;
      Get.to(() => const InvoicePreviewView());
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    } else {
      Get.back();
    }
  }

  // --- PROFILE ACTIONS ---
  Future<void> pickBusinessLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        businessLogoPath.value = image.path;
      }
    } catch (e) {
      Helpers.showCustomSnackBar('Could not access gallery: $e', isError: true);
    }
  }

  Future<void> fetchInvoiceProfileFromApi() async {
    try {
      final response = await _invoiceRepo.fetchInvoiceProfile();
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        if (body['success'] == true && body['data'] != null) {
          final profile = InvoiceProfileModel.fromJson(
            body['data'] as Map<String, dynamic>,
          );
          if (profile.businessName != null &&
              profile.businessName!.isNotEmpty) {
            businessNameController.text = profile.businessName!;
            savedBusinessName.value = profile.businessName!;
          }
          if (profile.email != null && profile.email!.isNotEmpty) {
            businessEmailController.text = profile.email!;
          }
          if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
            businessPhoneController.text = profile.phoneNumber!;
          }
          if (profile.website != null && profile.website!.isNotEmpty) {
            businessWebsiteController.text = profile.website!;
          }
          if (profile.address != null && profile.address!.isNotEmpty) {
            businessAddressController.text = profile.address!;
          }
          if (profile.logo != null && profile.logo!.isNotEmpty) {
            businessLogoPath.value = profile.logo;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching invoice profile from API: $e');
    }
  }

  Future<void> saveProfileSettings() async {
    if (businessNameController.text.trim().isEmpty) {
      Helpers.showCustomSnackBar('Business name is required.', isError: true);
      return;
    }

    File? logoFile;
    if (businessLogoPath.value != null &&
        businessLogoPath.value!.isNotEmpty &&
        !businessLogoPath.value!.startsWith('http://') &&
        !businessLogoPath.value!.startsWith('https://')) {
      final file = File(businessLogoPath.value!);
      if (file.existsSync()) {
        logoFile = file;
      }
    }

    final profile = InvoiceProfileModel(
      businessName: businessNameController.text.trim(),
      email: businessEmailController.text.trim(),
      phoneNumber: businessPhoneController.text.trim(),
      website: businessWebsiteController.text.trim(),
      address: businessAddressController.text.trim(),
      logo: businessLogoPath.value ?? '',
    );

    try {
      isLoading.value = true;
      final response = await _invoiceRepo.upsertInvoiceProfile(
        profile,
        logoFile: logoFile,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        if (body != null && body['data'] != null) {
          final updatedProfile = InvoiceProfileModel.fromJson(body['data']);
          if (updatedProfile.businessName != null &&
              updatedProfile.businessName!.isNotEmpty) {
            savedBusinessName.value = updatedProfile.businessName!;
          }
          if (updatedProfile.logo != null && updatedProfile.logo!.isNotEmpty) {
            businessLogoPath.value = updatedProfile.logo!;
          }
        } else {
          savedBusinessName.value = businessNameController.text.trim();
        }

        Get.back(); // Return to settings page

        Helpers.showCustomSnackBar(
          'Profile settings saved successfully.',
          isError: false,
        );
      } else {
        final errorMsg = _extractErrorMessage(
          response.data,
          defaultMsg: 'Failed to save profile. Code: ${response.statusCode}',
        );
        Helpers.showCustomSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      final errorMsg = _extractErrorMessage(e, defaultMsg: 'Profile update failed.');
      Helpers.showCustomSnackBar(errorMsg, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void populateFromRecord(InvoiceHistoryRecord record) {
    clearValidationErrors();
    invoiceNumberController.text = record.invoiceNumber;
    invoiceAmountController.text = record.totalAmount.toStringAsFixed(2);
    clientNameController.text = record.clientName;
    clientEmailController.text = record.clientEmail;
    issuedDate.value = record.issuedDate;
    final matchingCurrency = currencyOptions.firstWhere(
      (opt) => opt.startsWith(record.currency),
      orElse: () => currencyOptions.first,
    );
    selectedCurrency.value = matchingCurrency;

    clientBusinessNameController.text = record.clientBusinessName;
    clientPhoneController.text = record.clientPhone;
    clientStreetAddressController.text = record.clientStreetAddress;
    clientCityController.text = record.clientCity;
    clientStateController.text = record.clientState;
    clientZipController.text = record.clientZip;
    clientCountry.value = record.clientCountry;
    invoiceDescriptionController.text = record.invoiceDescription;
    messageToClientController.text = record.messageToClient;
    selectedDueDateOption.value = record.dueDate;

    businessNameController.text = record.businessName;
    businessEmailController.text = record.businessEmail;
    businessPhoneController.text = record.businessPhone;
    businessWebsiteController.text = record.businessWebsite;
    businessAddressController.text = record.businessAddress;
    businessLogoPath.value = record.businessLogoPath;
    invoiceStatus.value = record.status;
  }

  void prepareNewInvoice() {
    clearValidationErrors();
    editingRecordIndex.value = -1;
    invoiceStatus.value = 'Unpaid';
    invoiceAmountController.clear();
    clientNameController.clear();
    clientBusinessNameController.clear();
    clientEmailController.clear();
    clientPhoneController.clear();
    clientStreetAddressController.clear();
    clientCityController.clear();
    clientStateController.clear();
    clientZipController.clear();
    invoiceDescriptionController.clear();
    messageToClientController.text = 'Thank you for your business!';
    invoiceNumberController.clear();

    issuedDate.value = DateTime.now();
    selectedDueDateOption.value = 'On Receipt';
    customDueDate.value = null;
    currentStep.value = 1;

    // Fetch fresh profile & client data for invoice creation
    fetchInvoiceProfileFromApi();
    fetchClientsFromApi();
  }

  Future<void> deleteInvoiceAtIndex(int index) async {
    if (index >= 0 && index < invoiceHistory.length) {
      final record = invoiceHistory[index];
      if (record.id != null && record.id!.isNotEmpty) {
        try {
          await _invoiceRepo.deleteInvoice(record.id!);
        } catch (e) {
          debugPrint('Error deleting invoice from backend: $e');
        }
      }
      invoiceHistory.removeAt(index);
    }
  }

  Future<void> toggleInvoiceStatus(int index, bool isPaid) async {
    if (index >= 0 && index < invoiceHistory.length) {
      final record = invoiceHistory[index];
      final newStatus = isPaid ? 'Paid' : 'Unpaid';

      // Immediate UI feedback
      final updated = record.copyWith(status: newStatus);
      invoiceHistory[index] = updated;
      if (editingRecordIndex.value == index) {
        invoiceStatus.value = newStatus;
      }

      if (record.id != null && record.id!.isNotEmpty) {
        try {
          final response = await _invoiceRepo.updateInvoice(record.id!, {
            'invoiceAmount': record.totalAmount,
            'status': isPaid ? 'paid' : 'unpaid',
          });
          if (response.statusCode == 200 || response.statusCode == 201) {
            Helpers.showCustomSnackBar(
              'Invoice marked as $newStatus.',
              isError: false,
            );
          } else {
            final reverted = record.copyWith(
              status: isPaid ? 'Unpaid' : 'Paid',
            );
            invoiceHistory[index] = reverted;
            Helpers.showCustomSnackBar(
              'Failed to update status. Code: ${response.statusCode}',
              isError: true,
            );
          }
        } catch (e) {
          final reverted = record.copyWith(status: isPaid ? 'Unpaid' : 'Paid');
          invoiceHistory[index] = reverted;
          debugPrint('Error updating invoice status on backend: $e');
          Helpers.showCustomSnackBar(
            'Failed to update invoice status.',
            isError: true,
          );
        }
      }
    }
  }

  Future<void> deleteInvoice() async {
    final wasEditing = editingRecordIndex.value != -1;
    if (wasEditing && editingRecordIndex.value < invoiceHistory.length) {
      await deleteInvoiceAtIndex(editingRecordIndex.value);
    }

    // Reset fields for the next invoice
    invoiceAmountController.text = '0.00';
    clientNameController.clear();
    clientBusinessNameController.clear();
    clientEmailController.clear();
    clientPhoneController.clear();
    clientStreetAddressController.clear();
    clientCityController.clear();
    clientStateController.clear();
    clientZipController.clear();
    invoiceDescriptionController.clear();
    messageToClientController.text = 'Thank you for your business!';

    invoiceNumberController.text =
        'Invoice ${int.parse(invoiceNumberController.text.replaceAll(RegExp(r'\D'), '')) + 1}';
    currentStep.value = 1;
    editingRecordIndex.value = -1;

    Get.back(); // close preview screen
    Get.back(); // close create screen
    if (wasEditing) {
      Get.back(); // close details view screen
    }
    Helpers.showCustomSnackBar('Invoice has been deleted.', isError: false);
  }

  Future<void> fetchInvoicesFromApi() async {
    try {
      isLoading.value = true;
      final response = await _invoiceRepo.fetchInvoices();
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'];
          final records = list.map((item) {
            final model = InvoiceModel.fromJson(item as Map<String, dynamic>);
            return _mapInvoiceModelToRecord(model);
          }).toList();

          invoiceHistory.assignAll(records);
        }
      }
    } catch (e) {
      debugPrint('Error fetching invoices from API: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchInvoiceDetails(String invoiceId) async {
    if (invoiceId.isEmpty) return;
    try {
      final response = await _invoiceRepo.fetchInvoiceById(invoiceId);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data;
        if (body['success'] == true && body['data'] != null) {
          final model = InvoiceModel.fromJson(
            body['data'] as Map<String, dynamic>,
          );
          final updatedRecord = _mapInvoiceModelToRecord(model);
          final idx = invoiceHistory.indexWhere((r) => r.id == invoiceId);
          if (idx != -1) {
            invoiceHistory[idx] = updatedRecord;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching single invoice details: $e');
    }
  }

  InvoiceHistoryRecord _mapInvoiceModelToRecord(InvoiceModel model) {
    String dueDateStr = 'On Receipt';
    if (model.dueDateType == 'custom' && model.customDueDate != null) {
      dueDateStr = 'Custom Due Date';
    } else if (model.dueDateType == 'on_receipt') {
      dueDateStr = 'On Receipt';
    } else if (model.dueDateType != null && model.dueDateType!.isNotEmpty) {
      dueDateStr = model.dueDateType!;
    }

    return InvoiceHistoryRecord(
      id: model.id,
      invoiceNumber: model.invoiceNumber ?? 'INV-000',
      clientName: model.clientName ?? 'N/A',
      clientEmail: model.emailAddress ?? '',
      issuedDate: model.issueDate ?? DateTime.now(),
      currency: model.currency ?? 'USD',
      status: model.status != null
          ? (model.status!.toLowerCase() == 'draft'
                ? 'Unpaid'
                : model.status!.capitalizeFirst!)
          : 'Unpaid',
      totalAmount: model.invoiceAmount ?? 0.0,
      clientBusinessName: model.businessName ?? '',
      clientPhone: model.phoneNumber ?? '',
      invoiceDescription: model.description ?? '',
      clientStreetAddress: model.billingAddress?.streetAddress ?? '',
      clientCity: model.billingAddress?.city ?? '',
      clientState: model.billingAddress?.state ?? '',
      clientZip: model.billingAddress?.zipCode ?? '',
      clientCountry: model.billingAddress?.country ?? 'United States',
      messageToClient: model.messageToClient ?? '',
      dueDate: dueDateStr,
      businessName:
          model.senderDetails?.businessName ??
          (savedBusinessName.value.isNotEmpty
              ? savedBusinessName.value
              : businessNameController.text),
      businessEmail: model.senderDetails?.email ?? businessEmailController.text,
      businessPhone:
          model.senderDetails?.phoneNumber ?? businessPhoneController.text,
      businessWebsite:
          model.senderDetails?.website ?? businessWebsiteController.text,
      businessAddress:
          model.senderDetails?.address ?? businessAddressController.text,
      businessLogoPath:
          model.senderDetails?.logo ?? (businessLogoPath.value ?? ''),
    );
  }

  Future<void> submitInvoice() async {
    if (!validateAll()) return;

    final wasEditing = editingRecordIndex.value != -1;
    final double amount = double.tryParse(invoiceAmountController.text) ?? 0.0;

    final String dueDateTypeStr = selectedDueDateOption.value == 'On Receipt'
        ? 'on_receipt'
        : 'custom';

    final invoicePayload = InvoiceModel(
      invoiceAmount: amount,
      issueDate: issuedDate.value,
      dueDateType: dueDateTypeStr,
      customDueDate: selectedDueDateOption.value == 'Custom Due Date'
          ? customDueDate.value
          : null,
      clientName: clientNameController.text.trim(),
      businessName: clientBusinessNameController.text.trim(),
      emailAddress: clientEmailController.text.trim(),
      phoneNumber: clientPhoneController.text.trim(),
      billingAddress: BillingAddressModel(
        streetAddress: clientStreetAddressController.text.trim(),
        city: clientCityController.text.trim(),
        state: clientStateController.text.trim(),
        zipCode: clientZipController.text.trim(),
        country: clientCountry.value,
      ),
      description: invoiceDescriptionController.text.trim(),
      messageToClient: messageToClientController.text.trim(),
    );

    try {
      isLoading.value = true;
      final dio.Response response;
      if (wasEditing &&
          editingRecordIndex.value < invoiceHistory.length &&
          invoiceHistory[editingRecordIndex.value].id != null) {
        final existingId = invoiceHistory[editingRecordIndex.value].id!;
        response = await _invoiceRepo.updateInvoice(
          existingId,
          invoicePayload.toJson(),
        );
      } else {
        response = await _invoiceRepo.createInvoice(invoicePayload);
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        InvoiceHistoryRecord record;
        if (body != null && body['success'] == true && body['data'] != null) {
          final createdModel = InvoiceModel.fromJson(body['data']);
          record = _mapInvoiceModelToRecord(createdModel);
        } else {
          record = InvoiceHistoryRecord(
            invoiceNumber: invoiceNumberController.text.trim(),
            clientName: clientNameController.text.trim(),
            clientEmail: clientEmailController.text.trim(),
            issuedDate: issuedDate.value,
            currency: selectedCurrency.value.split(' ')[0],
            status: wasEditing
                ? invoiceHistory[editingRecordIndex.value].status
                : 'Unpaid',
            totalAmount: amount,
            clientBusinessName: clientBusinessNameController.text.trim(),
            clientPhone: clientPhoneController.text.trim(),
            clientStreetAddress: clientStreetAddressController.text.trim(),
            clientCity: clientCityController.text.trim(),
            clientState: clientStateController.text.trim(),
            clientZip: clientZipController.text.trim(),
            clientCountry: clientCountry.value,
            invoiceDescription: invoiceDescriptionController.text.trim(),
            messageToClient: messageToClientController.text.trim(),
            dueDate: selectedDueDateOption.value,
            businessName: businessNameController.text.trim(),
            businessEmail: businessEmailController.text.trim(),
            businessPhone: businessPhoneController.text.trim(),
            businessWebsite: businessWebsiteController.text.trim(),
            businessAddress: businessAddressController.text.trim(),
            businessLogoPath: businessLogoPath.value ?? '',
          );
        }

        if (wasEditing) {
          invoiceHistory[editingRecordIndex.value] = record;
        } else {
          invoiceHistory.insert(0, record);
        }

        // Reset fields & navigate back
        invoiceAmountController.clear();
        clientNameController.clear();
        clientBusinessNameController.clear();
        clientEmailController.clear();
        clientPhoneController.clear();
        clientStreetAddressController.clear();
        clientCityController.clear();
        clientStateController.clear();
        clientZipController.clear();
        invoiceDescriptionController.clear();
        messageToClientController.text = 'Thank you for your business!';
        invoiceNumberController.clear();
        currentStep.value = 1;
        editingRecordIndex.value = -1;

        // Refresh client directory from backend
        fetchClientsFromApi();

        Get.back(); // close preview screen
        Get.back(); // close create screen
        if (wasEditing) {
          Get.back(); // close detail screen
        }

        Helpers.showCustomSnackBar(
          wasEditing
              ? 'Invoice updated successfully.'
              : 'Invoice created successfully.',
          isError: false,
        );
      } else {
        final errorMsg = _extractErrorMessage(
          response.data,
          defaultMsg: 'Failed to create invoice. Code: ${response.statusCode}',
        );
        Helpers.showCustomSnackBar(errorMsg, isError: true);
      }
    } catch (e) {
      final errorMsg = _extractErrorMessage(e, defaultMsg: 'Invoice submission failed.');
      Helpers.showCustomSnackBar(errorMsg, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void showSaveConfirmDialog() {
    final wasEditing = editingRecordIndex.value != -1;

    Get.dialog(
      Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF364153)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFD08700), // Bright orange-yellow
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: Colors.black,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                wasEditing ? 'Update Invoice?' : 'Save Invoice?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                wasEditing
                    ? 'Do you want to save changes to this invoice?'
                    : 'Do you want to save this invoice to your records?',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Delete',
                      backgroundColor: const Color(0xFF2C2C2C),
                      textColor: Colors.white,
                      onPressed: () {
                        // Cancel/Delete without calling API
                        invoiceAmountController.clear();
                        clientNameController.clear();
                        clientBusinessNameController.clear();
                        clientEmailController.clear();
                        clientPhoneController.clear();
                        clientStreetAddressController.clear();
                        clientCityController.clear();
                        clientStateController.clear();
                        clientZipController.clear();
                        invoiceDescriptionController.clear();
                        messageToClientController.text =
                            'Thank you for your business!';
                        invoiceNumberController.clear();
                        currentStep.value = 1;
                        editingRecordIndex.value = -1;

                        Get.back(); // close dialog
                        Get.back(); // close preview screen
                        Get.back(); // close create screen
                        if (wasEditing) {
                          Get.back(); // close detail screen
                        }
                      },
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() {
                      return CustomButton(
                        text: 'Save',
                        loading: isLoading.value,
                        onPressed: () async {
                          Get.back(); // close dialog first
                          await submitInvoice(); // NOW call API!
                        },
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
