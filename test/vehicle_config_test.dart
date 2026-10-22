import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moeb_26/config/themes/app_theme.dart';
import 'package:moeb_26/core/services/api_client.dart';
import 'package:moeb_26/core/services/vehicle_config_service.dart';
import 'package:moeb_26/core/widgets/vehicle_type_options.dart';
import 'package:moeb_26/data/models/vehicle_config_model.dart';

class OptionsApi extends ApiClient {
  final queries = <Map<String, dynamic>?>[];
  @override
  // The fake deliberately skips ApiClient's real network/storage initialization.
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<dio.Response> getData(
    String uri, {
    Map<String, dynamic>? query,
    dio.CancelToken? cancelToken,
    Map<String, dynamic>? extraHeaders,
  }) async {
    queries.add(query);
    final first = query == null;
    return dio.Response(
      requestOptions: dio.RequestOptions(path: uri),
      statusCode: 200,
      data: {
        'data': [
          {
            'vehicleType': first ? 'Sedan' : 'new type',
            'makesAndModels': [first ? 'BMW 5 Series' : 'new car'],
          },
        ],
        'cursor': {'hasMore': first, 'nextCursor': first ? 'page-two' : null},
      },
    );
  }
}

VehicleConfigOption option(String type, String model) =>
    VehicleConfigOption.fromJson({
      'vehicleType': type,
      'makesAndModels': [model],
    });

void main() {
  tearDown(() => Get.reset());

  test('loads every cursor page and models for the new type', () async {
    final api = OptionsApi();
    Get.put<ApiClient>(api);
    final service = VehicleConfigService();
    await service.fetchVehicleOptions();
    expect(service.vehicleTypes, ['Sedan', 'new type']);
    expect(api.queries, [
      null,
      {'cursor': 'page-two'},
    ]);
    expect(service.getMakesAndModelsForType('new type'), ['new car']);
    expect(service.getMakesAndModelsForType('Sedan'), ['BMW 5 Series']);
    expect(service.isLoading.value, isFalse);
  });

  test('edit aliases work without matching unrelated new types', () {
    final service = VehicleConfigService();
    service.options.assignAll([
      option('Stretch Limousine', 'Lincoln MKT Stretch'),
      option('Sprinter', 'Mercedes Sprinter'),
      option('Luxury Van', 'Custom Van'),
    ]);
    expect(service.matchesType('LimoStretch', 'Stretch Limousine'), isTrue);
    expect(service.getMakesAndModelsForType('LimoStretch'), [
      'Lincoln MKT Stretch',
    ]);
    expect(service.getMakesAndModelsForType('Luxury Van'), ['Custom Van']);
    expect(service.getMakesAndModelsForType('Unknown Van'), isEmpty);
  });

  test('known vehicle colours stay the same and unknown types are gray', () {
    expect(VehicleTypeColors.getVehicleStyle('Sedan'), VehicleTypeColors.sedan);
    expect(VehicleTypeColors.getVehicleStyle('SUV'), VehicleTypeColors.suv);
    expect(
      VehicleTypeColors.getVehicleStyle('Sedan / SUV'),
      isA<LinearGradient>(),
    );
    expect(
      VehicleTypeColors.getVehicleStyle('Stretch Limousine'),
      VehicleTypeColors.bus,
    );
    expect(
      VehicleTypeColors.getVehicleStyle('new type'),
      VehicleTypeColors.gray,
    );
  });

  testWidgets('many types and long names wrap within a narrow form', (
    tester,
  ) async {
    final service = VehicleConfigService();
    service.options.assignAll(
      List.generate(30, (i) => option('Type $i', 'Car $i'))
        ..add(option('A very long vehicle type name ' * 8, 'Car')),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 280,
              child: VehicleTypeOptions(
                service: service,
                chipBuilder: (type) => Container(
                  padding: const EdgeInsets.all(12),
                  child: Text(type),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Type 29'), findsOneWidget);
    expect(tester.takeException(), isNull);
    service.options.add(option('Dashboard addition', 'New car'));
    await tester.pump();
    expect(find.text('Dashboard addition'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
