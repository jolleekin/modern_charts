import 'package:test/test.dart';

import 'package:modern_charts/src/datatable.dart';

DataTable createDataTable() => DataTable([
      ['Browser', 'Share'],
      ['Chrome', 35],
      ['IE', 30],
      ['Firefox', 20]
    ]);

void main() {
  test('columns', () {
    final table = createDataTable();
    expect(table.columns.length, equals(2));
    expect(table.columns[0].name, equals('Browser'));
  });

  test('getColumnIndexByName', () {
    final table = createDataTable();
    expect(table.getColumnIndexByName('Share'), equals(1));
    expect(table.getColumnIndexByName('X'), equals(-1));
  });

  test('getColumnValues', () {
    final table = createDataTable();
    expect(table.getColumnValues(1), orderedEquals([35, 30, 20]));
  });

  test('rows', () {
    final table = createDataTable();
    expect(table.rows.length, equals(3));
    expect(table.rows[1].toList(), orderedEquals(['IE', 30]));
  });

  test('columns.insert', () {
    final table = createDataTable();
    table.columns.insert(1, DataColumn('Latest Version', num));
    expect(table.columns.length, equals(3));
    expect(table.columns[1].name, equals('Latest Version'));
  });

  test('rows.add', () {
    final table = createDataTable();
    table.rows.add(['Opera', 10, 'discarded']);
    expect(table.rows.length, equals(4));
    expect(table.rows.last.toList(), orderedEquals(['Opera', 10]));
  });

  test('rows.removeRange', () {
    final table = createDataTable();
    table.rows.removeRange(0, 3);
    expect(table.rows, isEmpty);
  });

  test('cells', () {
    final table = createDataTable();
    expect(table.rows[0][0], equals('Chrome'));
    table.rows[0][0] = 'Unknown';
    expect(table.rows[0][0], equals('Unknown'));
  });
}
