import 'package:flutter_test/flutter_test.dart';
import '../../tool/vehicle_catalog/validate_vehicle_catalog.dart' as validator;

void main() {
  test('Vehicle Catalog Seed Data Integrity and Quality Validation', () {
    // This executes the exact same validation logic as the CLI tool
    // and throws an exception on failure, which fails the test.
    validator.runValidation('assets/data/vehicle_catalog_kr_seed.json');
  });
}
