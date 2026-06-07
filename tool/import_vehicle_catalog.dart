import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  var input = 'assets/data/vehicle_catalog_kr_seed.json';
  String? output;
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == '--in' && i + 1 < args.length) {
      input = args[++i];
    } else if (args[i] == '--out' && i + 1 < args.length) {
      output = args[++i];
    }
  }

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('입력 파일을 찾을 수 없습니다: $input');
    exit(1);
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final sql = StringBuffer()
    ..writeln('-- Generated from $input')
    ..writeln(
        '-- official_efficiency is intentionally null when official data has not been verified.')
    ..writeln('begin;')
    ..writeln();

  _insert(
    sql,
    'public.vehicle_manufacturers',
    [
      'id',
      'name_ko',
      'name_en',
      'country',
      'logo_url',
      'is_popular',
      'sort_order'
    ],
    _list(data, 'manufacturers'),
    conflict: 'id',
  );
  _insert(
    sql,
    'public.vehicle_models',
    [
      'id',
      'manufacturer_id',
      'name_ko',
      'name_en',
      'body_type',
      'available_fuel_types',
      'is_popular',
      'sort_order'
    ],
    _list(data, 'models'),
    conflict: 'id',
    arrayColumns: {'available_fuel_types'},
  );
  _insert(
    sql,
    'public.vehicle_model_years',
    ['id', 'model_id', 'year'],
    _list(data, 'years'),
    conflict: 'id',
  );
  _insert(
    sql,
    'public.vehicle_variants',
    [
      'id',
      'model_year_id',
      'trim_name',
      'engine_name',
      'fuel_type',
      'displacement_cc',
      'battery_kwh',
      'drivetrain',
      'transmission',
      'official_efficiency',
      'efficiency_unit',
      'vehicle_class',
      'fuel_league',
      'is_verified',
      'sort_order',
    ],
    _list(data, 'variants'),
    conflict: 'id',
  );

  sql
    ..writeln('commit;')
    ..writeln();

  if (output == null) {
    stdout.write(sql.toString());
  } else {
    final outFile = File(output);
    outFile.createSync(recursive: true);
    outFile.writeAsStringSync(sql.toString());
    stdout.writeln('wrote $output');
  }
}

List<Map<String, dynamic>> _list(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) {
    stderr.writeln('$key 목록이 없습니다.');
    exit(1);
  }
  return value.cast<Map<String, dynamic>>();
}

void _insert(
  StringBuffer sql,
  String table,
  List<String> columns,
  List<Map<String, dynamic>> rows, {
  required String conflict,
  Set<String> arrayColumns = const {},
}) {
  if (rows.isEmpty) return;
  sql
    ..writeln('insert into $table (${columns.join(', ')})')
    ..writeln('values');
  for (var i = 0; i < rows.length; i += 1) {
    final row = rows[i];
    final values = columns.map((column) {
      if (arrayColumns.contains(column)) {
        return _array(row[column]);
      }
      return _value(row[column]);
    }).join(', ');
    sql.write('  ($values)');
    sql.writeln(i == rows.length - 1 ? '' : ',');
  }
  sql
    ..writeln('on conflict ($conflict) do update set')
    ..writeln(columns
        .where((column) => column != conflict)
        .map((column) => '  $column = excluded.$column')
        .join(',\n'))
    ..writeln(';')
    ..writeln();
}

String _value(Object? value) {
  if (value == null) return 'null';
  if (value is num) return '$value';
  if (value is bool) return value ? 'true' : 'false';
  return "'${'$value'.replaceAll("'", "''")}'";
}

String _array(Object? value) {
  if (value is! List) return "'{}'";
  final values =
      value.map((item) => '"${'$item'.replaceAll('"', '\\"')}"').join(',');
  return "'{$values}'";
}
