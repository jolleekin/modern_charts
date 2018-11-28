import 'package:modern_charts/src/datatable.dart';

String toFixedLengthString(obj, int length) => '$obj'.padRight(length);

void printTable(DataTable dt) {
  var sb = StringBuffer();
  for (var row in dt.rows) {
    var first = true;
    for (var col in dt.columns) {
      if (!first) sb.write(',');
      sb.write(toFixedLengthString(row[col.index], 20));
      first = false;
    }
    sb.writeln();
  }
  print(sb.toString());
}

void onChange(record) {
  print(record);
}

void main() {
  var dt = DataTable([
    ['Browser', 'Share'],
    ['Chrome', 35],
    ['IE', 30],
    ['Firefox', 20]
  ]);
  dt.onCellChange.listen(onChange);
  dt.onColumnsChange.listen(onChange);
  dt.onRowsChange.listen(onChange);
  printTable(dt);

  dt.columns.insert(1, DataColumn('Latest Version', num));
  printTable(dt);

  dt.rows.add(['Opera', 10, 5]);
  printTable(dt);

  dt.rows.removeRange(1, 3);
  printTable(dt);

  dt.rows[0]['Latest Version'] = 38;
  printTable(dt);

  dt.rows.insertAll(1, [
    ['Safari', null, 4],
    ['Other', null, 3]
  ]);
  printTable(dt);
}
