import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/vehicle_config_service.dart';

/// Wraps API supplied types inside the available form width.
class VehicleTypeOptions extends StatelessWidget {
  final VehicleConfigService service;
  final Widget Function(String) chipBuilder;

  const VehicleTypeOptions({
    super.key,
    required this.service,
    required this.chipBuilder,
  });

  @override
  Widget build(BuildContext context) => Obx(() {
    final types = service.vehicleTypes;
    if (types.isEmpty) {
      if (service.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        );
      }
      return TextButton.icon(
        onPressed: service.fetchVehicleOptions,
        icon: const Icon(Icons.refresh),
        label: const Text('Reload vehicle types'),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: types
            .map(
              (type) => ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: chipBuilder(type),
              ),
            )
            .toList(),
      ),
    );
  });
}
