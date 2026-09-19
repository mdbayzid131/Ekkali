import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:moeb_26/core/services/expense_service.dart';
import 'package:moeb_26/core/utils/helpers.dart';
import '../models/expense_model.dart';

class ExpenseController extends GetxController {
  late ExpenseService _expenseService;

  var expenses = <ExpenseModel>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var totalAmount = 0.0.obs;

  /// Download receipt image helper method
  Future<void> downloadReceiptImage(String imagePath) async {
    try {
      if (imagePath.isEmpty) return;

      Uint8List? imageBytes;

      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        final dio = Dio();
        final response = await dio.get<List<int>>(
          imagePath,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          imageBytes = Uint8List.fromList(response.data!);
        }
      } else {
        final file = File(imagePath);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        }
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        final isPng = imagePath.toLowerCase().endsWith('.png');
        final fileName =
            'receipt_${DateTime.now().millisecondsSinceEpoch}.${isPng ? 'png' : 'jpg'}';

        await Printing.sharePdf(
          bytes: imageBytes,
          filename: fileName,
        );
      } else {
        Get.snackbar(
          'Download Failed',
          'Receipt image could not be loaded.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFF1E1E20),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error sharing/downloading receipt image: $e');
      Get.snackbar(
        'Download Failed',
        'Could not save receipt image. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E1E20),
        colorText: Colors.white,
      );
    }
  }

  // Cursor Pagination state
  var nextCursor = RxnString();
  var hasMore = false.obs;
  final ScrollController scrollController = ScrollController();

  // Input fields controllers
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  // Selected state for form
  var selectedCategory = 'Fuel'.obs;
  var selectedDate = DateTime.now().obs;
  var selectedImage = Rxn<File>();
  var existingImageUrl = Rxn<String>();

  // Filter states
  var filterPeriod = 'Monthly'.obs; // 'Monthly' or 'Yearly'
  var filterDate = DateTime.now().obs; // Tracks the selected month/year

  final ImagePicker _picker = ImagePicker();

  // Updated categories according to client requirements
  final List<String> categories = [
    'Fuel',
    'Oil Changes',
    'Tires',
    'Maintenance & Repairs',
    'Car Washes & Detailing',
    'Insurance',
    'Toll Expenses',
    'Parking',
    'Vehicle Payments',
    'Phone & Internet',
    'Water & Snacks for Clients',
    'Client Amenities',
    'Cleaning Supplies',
    'Licenses & Permits',
    'Business Insurance',
    'Marketing',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    _expenseService = Get.find<ExpenseService>();
    scrollController.addListener(_onScroll);
    fetchExpenses();
  }

  void _onScroll() {
    if (scrollController.hasClients &&
        scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200) {
      if (hasMore.value && !isLoadingMore.value && !isLoading.value) {
        loadMoreExpenses();
      }
    }
  }

  /// Calculates start and end dates based on selected filterPeriod & filterDate
  ({DateTime start, DateTime end}) _getDateRange() {
    if (filterPeriod.value == 'Monthly') {
      final start = DateTime.utc(filterDate.value.year, filterDate.value.month, 1, 0, 0, 0);
      final end = DateTime.utc(filterDate.value.year, filterDate.value.month + 1, 0, 23, 59, 59, 999);
      return (start: start, end: end);
    } else {
      final start = DateTime.utc(filterDate.value.year, 1, 1, 0, 0, 0);
      final end = DateTime.utc(filterDate.value.year, 12, 31, 23, 59, 59, 999);
      return (start: start, end: end);
    }
  }

  /// Fetch expenses from backend API using date range filter & cursor pagination
  Future<void> fetchExpenses({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        isLoading.value = true;
      }
      nextCursor.value = null;
      hasMore.value = false;

      final range = _getDateRange();
      final response = await _expenseService.fetchExpenses(
        startDate: range.start,
        endDate: range.end,
        limit: 1000,
      );

      if (response.statusCode == 200 && response.data != null) {
        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString();
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        final List<dynamic> dataList =
            response.data['data'] is List ? response.data['data'] : [];
        final loadedExpenses = dataList
            .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
            .toList();
        expenses.assignAll(loadedExpenses);
      }
      fetchTotalExpenses();
    } catch (e) {
      Helpers.debug('Error fetching expenses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more expenses when scrolling down
  Future<void> loadMoreExpenses() async {
    if (isLoadingMore.value || !hasMore.value || nextCursor.value == null) {
      return;
    }
    try {
      isLoadingMore.value = true;
      final range = _getDateRange();
      final response = await _expenseService.fetchExpenses(
        startDate: range.start,
        endDate: range.end,
        cursor: nextCursor.value,
        limit: 1000,
      );

      if (response.statusCode == 200 && response.data != null) {
        final cursorData = response.data['cursor'];
        if (cursorData is Map) {
          nextCursor.value = cursorData['nextCursor']?.toString();
          hasMore.value = cursorData['hasMore'] == true;
        } else {
          hasMore.value = false;
        }

        final List<dynamic> dataList =
            response.data['data'] is List ? response.data['data'] : [];
        final moreExpenses = dataList
            .map((item) => ExpenseModel.fromJson(item as Map<String, dynamic>))
            .toList();
        expenses.addAll(moreExpenses);
      }
    } catch (e) {
      Helpers.debug('Error loading more expenses: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Fetch total expense amount from backend API
  Future<void> fetchTotalExpenses() async {
    try {
      final range = _getDateRange();
      final response = await _expenseService.fetchTotalExpenses(
        startDate: range.start,
        endDate: range.end,
      );

      if (response.statusCode == 200 && response.data != null) {
        final totalVal = response.data['data']?['total'];
        if (totalVal != null) {
          totalAmount.value = (totalVal as num).toDouble();
          return;
        }
      }
      totalAmount.value = expenses.fold(0.0, (sum, item) => sum + item.amount);
    } catch (e) {
      Helpers.debug('Error fetching total expenses: $e');
      totalAmount.value = expenses.fold(0.0, (sum, item) => sum + item.amount);
    }
  }

  IconData getCategoryIcon(String category) {
    switch (category.trim()) {
      case 'Fuel':
        return Icons.local_gas_station_outlined;
      case 'Oil Changes':
        return Icons.opacity_outlined;
      case 'Tires':
        return Icons.album_outlined;
      case 'Maintenance & Repairs':
        return Icons.build_circle_outlined;
      case 'Car Washes & Detailing':
        return Icons.local_car_wash_outlined;
      case 'Insurance':
      case 'Business Insurance':
        return Icons.shield_outlined;
      case 'Toll Expenses':
        return Icons.toll_outlined;
      case 'Parking':
        return Icons.local_parking_outlined;
      case 'Vehicle Payments':
        return Icons.credit_card_outlined;
      case 'Phone & Internet':
        return Icons.phone_android_outlined;
      case 'Water & Snacks for Clients':
        return Icons.local_drink_outlined;
      case 'Client Amenities':
        return Icons.card_giftcard_outlined;
      case 'Cleaning Supplies':
        return Icons.cleaning_services_outlined;
      case 'Licenses & Permits':
        return Icons.assignment_outlined;
      case 'Marketing':
        return Icons.campaign_outlined;
      case 'Other':
      default:
        return Icons.receipt_outlined;
    }
  }

  // Filtered expenses based on selection
  List<ExpenseModel> get filteredExpenses => expenses;

  // Filtered total amount
  double get filteredTotalAmount {
    if (totalAmount.value > 0) return totalAmount.value;
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void setDate(DateTime date) {
    selectedDate.value = date;
  }

  void toggleFilterPeriod() {
    if (filterPeriod.value == 'Monthly') {
      filterPeriod.value = 'Yearly';
    } else {
      filterPeriod.value = 'Monthly';
    }
    fetchExpenses();
  }

  void previousPeriod() {
    if (filterPeriod.value == 'Monthly') {
      filterDate.value = DateTime(
        filterDate.value.year,
        filterDate.value.month - 1,
      );
    } else {
      filterDate.value = DateTime(filterDate.value.year - 1);
    }
    fetchExpenses();
  }

  void nextPeriod() {
    if (filterPeriod.value == 'Monthly') {
      filterDate.value = DateTime(
        filterDate.value.year,
        filterDate.value.month + 1,
      );
    } else {
      filterDate.value = DateTime(filterDate.value.year + 1);
    }
    fetchExpenses();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        imageQuality: 80,
        source: source,
      );
      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
        existingImageUrl.value = null;
      }
    } catch (e) {
      Helpers.showCustomSnackBar("Failed to pick image: $e", isError: true);
    }
  }

  void clearForm() {
    amountController.clear();
    descriptionController.clear();
    selectedCategory.value = categories.first;
    selectedDate.value = DateTime.now();
    selectedImage.value = null;
    existingImageUrl.value = null;
  }

  void loadExpenseForEdit(ExpenseModel expense) {
    amountController.text = expense.amount.toString();
    descriptionController.text = expense.description;
    selectedCategory.value = expense.category;
    selectedDate.value = expense.date;
    if (expense.receiptImageUrl != null &&
        expense.receiptImageUrl!.isNotEmpty) {
      if (expense.receiptImageUrl!.startsWith('http://') ||
          expense.receiptImageUrl!.startsWith('https://')) {
        existingImageUrl.value = expense.receiptImageUrl;
        selectedImage.value = null;
      } else {
        selectedImage.value = File(expense.receiptImageUrl!);
        existingImageUrl.value = null;
      }
    } else {
      selectedImage.value = null;
      existingImageUrl.value = null;
    }
  }

  Future<void> addExpense() async {
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      Helpers.showCustomSnackBar("Please enter a valid amount", isError: true);
      return;
    }

    try {
      isLoading.value = true;
      final response = await _expenseService.createExpense(
        category: selectedCategory.value,
        amount: amount,
        date: selectedDate.value,
        description: descriptionController.text.trim(),
        receiptFile: selectedImage.value,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final addedDate = selectedDate.value;
        clearForm();
        Get.back(); // close modal
        filterDate.value = addedDate;
        fetchExpenses();

        Helpers.showCustomSnackBar("Expense added successfully", isError: false);
      } else {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Failed to add expense",
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showCustomSnackBar("Failed to add expense: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateExpense(ExpenseModel oldExpense) async {
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      Helpers.showCustomSnackBar("Please enter a valid amount", isError: true);
      return;
    }

    try {
      isLoading.value = true;
      final response = await _expenseService.updateExpense(
        oldExpense.id,
        category: selectedCategory.value,
        amount: amount,
        date: selectedDate.value,
        description: descriptionController.text.trim(),
        receiptFile: selectedImage.value,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        clearForm();
        Get.back(); // close modal
        fetchExpenses();

        Helpers.showCustomSnackBar("Expense updated successfully", isError: false);
      } else {
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Failed to update expense",
          isError: true,
        );
      }
    } catch (e) {
      Helpers.showCustomSnackBar("Failed to update expense: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteExpense(String id) async {
    final index = expenses.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final removedExpense = expenses[index];
    // Smoothly remove item locally without full-screen loading state
    expenses.removeAt(index);
    fetchTotalExpenses();

    try {
      final response = await _expenseService.deleteExpense(id);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Helpers.showCustomSnackBar("Expense deleted successfully", isError: false);
      } else {
        // Rollback if server call fails
        expenses.insert(index, removedExpense);
        fetchTotalExpenses();
        Helpers.showCustomSnackBar(
          response.data?['message'] ?? "Failed to delete expense",
          isError: true,
        );
      }
    } catch (e) {
      // Rollback on network failure
      expenses.insert(index, removedExpense);
      fetchTotalExpenses();
      Helpers.showCustomSnackBar("Failed to delete expense: $e", isError: true);
    }
  }

  Future<void> exportToCSV() async {
    try {
      if (filteredExpenses.isEmpty) {
        Helpers.showCustomSnackBar("No expenses to export", isError: true);
        return;
      }

      final csvContent = StringBuffer();
      csvContent.writeln('ID,Date,Category,Description,Amount');
      for (var e in filteredExpenses) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(e.date);
        final cleanCategory = e.category.replaceAll('"', '""');
        final cleanDesc = e.description.replaceAll('"', '""');
        csvContent.writeln(
          '${e.id},"$formattedDate","$cleanCategory","$cleanDesc",${e.amount.toStringAsFixed(2)}',
        );
      }

      // Append Total row
      csvContent.writeln(',,,Total,${filteredTotalAmount.toStringAsFixed(2)}');

      final tempDir = Directory.systemTemp;
      final file = File(
        '${tempDir.path}/expense_report_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csvContent.toString());

      await Printing.sharePdf(
        bytes: await file.readAsBytes(),
        filename:
            'expense_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      );
    } catch (e) {
      Helpers.showCustomSnackBar("Export Failed: $e", isError: true);
    }
  }

  String _sanitizeForPdf(String text) {
    if (text.isEmpty) return '';
    final buffer = StringBuffer();
    for (var char in text.runes) {
      if ((char >= 32 && char <= 126) ||
          (char >= 160 && char <= 255) ||
          char == 10 ||
          char == 13 ||
          char == 9) {
        buffer.writeCharCode(char);
      }
    }
    return buffer.toString().trim();
  }

  Future<void> exportToPDF() async {
    try {
      if (filteredExpenses.isEmpty) {
        Helpers.showCustomSnackBar("No expenses to export", isError: true);
        return;
      }

      pw.ThemeData theme;
      try {
        final font = await PdfGoogleFonts.robotoRegular();
        final boldFont = await PdfGoogleFonts.robotoBold();
        theme = pw.ThemeData.withFont(base: font, bold: boldFont);
      } catch (_) {
        theme = pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        );
      }

      final pdf = pw.Document(theme: theme);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Expense Tracker Report",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Category', 'Description', 'Amount (\$)'],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E1E20),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerLeft,
                  3: pw.Alignment.centerRight,
                },
                data: filteredExpenses
                    .map(
                      (e) => [
                        DateFormat('dd MMM yyyy').format(e.date),
                        _sanitizeForPdf(e.category),
                        _sanitizeForPdf(e.description),
                        '\$${e.amount.toStringAsFixed(2)}',
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(6),
                    ),
                  ),
                  child: pw.Text(
                    "Total Amount: \$${filteredTotalAmount.toStringAsFixed(2)}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'expense_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      Helpers.showCustomSnackBar("Export Failed: $e", isError: true);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    amountController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
