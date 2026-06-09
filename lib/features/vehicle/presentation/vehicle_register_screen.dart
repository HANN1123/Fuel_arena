import 'package:flutter/material.dart';
import 'vehicle_setup_screen.dart';

/// VehicleRegisterScreen is a route wrapper for VehicleSetupScreen
/// that allows users to register their vehicle during the initial setup
/// or profile configuration flow.
///
/// It inherits all selection cards, powertrain taxonomy views,
/// confidence score badges, and source details sheets from VehicleSetupScreen.
class VehicleRegisterScreen extends StatelessWidget {
  const VehicleRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Delegates rendering directly to VehicleSetupScreen to share the full UI
    return const VehicleSetupScreen();
  }
}
