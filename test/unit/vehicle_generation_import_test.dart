import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/vehicle_catalog/import_vehicle_generations.dart';

void main() {
  test('generation importer links model years and powertrains', () {
    final directory = Directory.systemTemp.createTempSync('fuel_arena_gen_');
    addTearDown(() => directory.deleteSync(recursive: true));

    final catalogPath = '${directory.path}/catalog.json';
    final generationCsvPath = '${directory.path}/generations.csv';
    final powertrainCsvPath = '${directory.path}/powertrains.csv';

    File(catalogPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'manufacturers': [
          {'id': 'm-hyundai', 'name_ko': 'Hyundai'},
        ],
        'models': [
          {
            'id': 'model-hyundai-avante',
            'manufacturer_id': 'm-hyundai',
            'name_ko': 'Avante',
          },
        ],
        'years': [
          {
            'id': 'year-hyundai-avante-2024',
            'model_id': 'model-hyundai-avante',
            'year': 2024,
          },
        ],
        'variants': [
          {
            'id': 'variant-hyundai-avante-2024-gasoline',
            'model_year_id': 'year-hyundai-avante-2024',
            'manufacturer_name': 'Hyundai',
            'model_name': 'Avante',
            'year': 2024,
            'trim_name': '1.6 gasoline',
            'fuel_type': 'gasoline',
            'displacement_cc': 1598,
            'transmission': 'IVT',
          },
        ],
      }),
      encoding: utf8,
    );
    File(generationCsvPath).writeAsStringSync(
      [
        'manufacturer_name,model_name,generation_order,generation_name_ko,generation_name_en,generation_code,platform_code,start_year,start_month,end_year,end_month,display_period,is_current,is_upcoming,market_region,source_name,source_url,source_status,confidence_score',
        'Hyundai,Avante,7,7th generation,Seventh generation,CN7,,2020,4,,,2020.4~present,true,false,KR,,,unverified,0.35',
      ].join('\n'),
      encoding: utf8,
    );
    File(powertrainCsvPath).writeAsStringSync(
      [
        'manufacturer,model,generation_code,generation_id,year,trim_name,fuel_type,displacement_cc,battery_kwh,drivetrain,transmission,official_efficiency,efficiency_unit,vehicle_class,valid_from_year,valid_to_year,source_note',
        'Hyundai,Avante,CN7,generation-hyundai-avante-cn7,2024,1.6 gasoline,gasoline,1598,,FWD,IVT,15.0,km/L,compact,2020,,test',
      ].join('\n'),
      encoding: utf8,
    );

    final result = runGenerationImport(
      GenerationImportOptions(
        catalogPath: catalogPath,
        generationCsvPath: generationCsvPath,
        powertrainCsvPath: powertrainCsvPath,
      ),
    );

    expect(result.insertedGenerations, 1);
    expect(result.linkedModelYears, 1);
    expect(result.linkedVariants, 1);
    expect(result.powertrainLinks, 1);

    final catalog = jsonDecode(File(catalogPath).readAsStringSync())
        as Map<String, dynamic>;
    final generation = (catalog['generations'] as List).single;
    expect(generation['id'], 'generation-hyundai-avante-cn7');
    expect(generation['model_year_ids'], ['year-hyundai-avante-2024']);
    expect(
        (catalog['years'] as List).single['generation_id'], generation['id']);
    final variant = (catalog['variants'] as List).single;
    expect(variant['generation_id'], generation['id']);
    expect(variant['valid_from_year'], 2020);
  });

  test('generation importer rejects verified rows without a source', () {
    final directory = Directory.systemTemp.createTempSync('fuel_arena_gen_');
    addTearDown(() => directory.deleteSync(recursive: true));

    final catalogPath = '${directory.path}/catalog.json';
    final generationCsvPath = '${directory.path}/generations.csv';

    File(catalogPath).writeAsStringSync(
      jsonEncode({
        'manufacturers': [
          {'id': 'm-hyundai', 'name_ko': 'Hyundai'},
        ],
        'models': [
          {
            'id': 'model-hyundai-avante',
            'manufacturer_id': 'm-hyundai',
            'name_ko': 'Avante',
          },
        ],
        'years': [],
        'variants': [],
      }),
      encoding: utf8,
    );
    File(generationCsvPath).writeAsStringSync(
      [
        'manufacturer_name,model_name,generation_order,generation_name_ko,generation_name_en,generation_code,platform_code,start_year,start_month,end_year,end_month,display_period,is_current,is_upcoming,market_region,source_name,source_url,source_status,confidence_score',
        'Hyundai,Avante,7,7th generation,Seventh generation,CN7,,2020,4,,,2020.4~present,true,false,KR,,,verified_official,0.95',
      ].join('\n'),
      encoding: utf8,
    );

    expect(
      () => runGenerationImport(
        GenerationImportOptions(
          catalogPath: catalogPath,
          generationCsvPath: generationCsvPath,
        ),
      ),
      throwsStateError,
    );
  });

  test('generation importer separates launch date from model year mapping', () {
    final directory = Directory.systemTemp.createTempSync('fuel_arena_gen_');
    addTearDown(() => directory.deleteSync(recursive: true));

    final catalogPath = '${directory.path}/catalog.json';
    final generationCsvPath = '${directory.path}/generations.csv';

    File(catalogPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'manufacturers': [
          {'id': 'm-bmw', 'name_ko': 'BMW'},
        ],
        'models': [
          {
            'id': 'model-bmw-5',
            'manufacturer_id': 'm-bmw',
            'name_ko': '5 Series',
          },
        ],
        'years': [
          {'id': 'year-bmw-5-2023', 'model_id': 'model-bmw-5', 'year': 2023},
          {'id': 'year-bmw-5-2024', 'model_id': 'model-bmw-5', 'year': 2024},
        ],
        'variants': [
          {
            'id': 'variant-bmw-5-2023-gasoline',
            'model_year_id': 'year-bmw-5-2023',
            'manufacturer_name': 'BMW',
            'model_name': '5 Series',
            'year': 2023,
            'trim_name': '530i',
            'fuel_type': 'gasoline',
            'transmission': 'AT',
          },
          {
            'id': 'variant-bmw-5-2024-gasoline',
            'model_year_id': 'year-bmw-5-2024',
            'manufacturer_name': 'BMW',
            'model_name': '5 Series',
            'year': 2024,
            'trim_name': '530i',
            'fuel_type': 'gasoline',
            'transmission': 'AT',
          },
        ],
      }),
      encoding: utf8,
    );
    File(generationCsvPath).writeAsStringSync(
      [
        'manufacturer_name,model_name,generation_order,generation_name_ko,generation_name_en,generation_code,platform_code,start_year,start_month,end_year,end_month,model_year_start_year,model_year_end_year,display_period,is_current,is_upcoming,market_region,source_name,source_url,source_status,confidence_score',
        'BMW,5 Series,7,7th generation,Seventh generation,G30,G30,2017,,2023,,2017,2023,2017~2023,false,false,KR,source,https://example.com/g30,verified_admin,0.72',
        'BMW,5 Series,8,8th generation,Eighth generation,G60,G60,2023,10,,,2024,2026,2023.10~present,true,false,KR,source,https://example.com/g60,verified_admin,0.78',
      ].join('\n'),
      encoding: utf8,
    );

    final result = runGenerationImport(
      GenerationImportOptions(
        catalogPath: catalogPath,
        generationCsvPath: generationCsvPath,
      ),
    );

    expect(result.insertedGenerations, 2);
    expect(result.linkedModelYears, 2);
    expect(result.linkedVariants, 2);

    final catalog = jsonDecode(File(catalogPath).readAsStringSync())
        as Map<String, dynamic>;
    final years = (catalog['years'] as List).cast<Map<String, dynamic>>();
    expect(
      years.firstWhere((item) => item['year'] == 2023)['generation_id'],
      'generation-bmw-5-g30',
    );
    expect(
      years.firstWhere((item) => item['year'] == 2024)['generation_id'],
      'generation-bmw-5-g60',
    );
  });
}
