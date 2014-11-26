library chart.src.datatable;

import 'dart:async';
import 'dart:collection';

class DataCellChangeRecord {
  final int rowIndex;
  final int columnIndex;
  final dynamic oldValue;
  final dynamic newValue;
  DataCellChangeRecord(this.rowIndex, this.columnIndex, this.oldValue,
      this.newValue);
  String toString() =>
      'DataCellChangeRecord { rowIndex: $rowIndex, colIndex; $columnIndex, $oldValue, $newValue }';
}

class DataCollectionChangeRecord {
  final int index;
  final int addedCount;
  final int removedCount;
  DataCollectionChangeRecord(this.index, this.addedCount, this.removedCount);

  String toString() =>
      'DataCollectionChangeRecord { index: $index, added: $addedCount, removed: $removedCount}';
}

class _TableEntity {
  int _index;
  DataTable _table;

  int get index => _index;
  DataTable get table => _table;
}

class DataRow extends _TableEntity {
  /// The list that stores the actual data.
  List _cells;

  /// Converts a column index or name to an index.
  int _toIndex(columnIndexOrName) {
    if (columnIndexOrName is int) return columnIndexOrName;
    return _table._columnIndexByName[columnIndexOrName];
  }

  /// Creates a new [DataRow] from a list of values.
  ///
  ///  Each value in [values] coreesponds to a column. If [values] is too short,
  /// the remaining columns are filled with `null`.
  DataRow._internal(DataTable table, List values) {
    _table = table;
    var n = _table._columns.length;
    var m = values.length;
    var min = m;
    if (min > n) min = n;
    _cells = values.sublist(0, min);
    for (var i = min; i < n; i++) {
      _cells.add(null);
    }
  }

  /// Returns the value of the column specified by [columnIndexOrName].
  operator [](columnIndexOrName) => _cells[_toIndex(columnIndexOrName)];

  /// Sets the value of the column specified by [columnIndexOrName].
  operator []=(columnIndexOrName, value) {
    var columnIndex = _toIndex(columnIndexOrName);
    var oldValue = _cells[columnIndex];
    _cells[columnIndex] = value;
    _table._onCellChanged(_index, columnIndex, oldValue, value);
  }
}

class DataColumn extends _TableEntity {
  String _name;
  Type _dataType;

  DataColumn(this._name, this._dataType);

  /// The name of the column.
  String get name => _name;

  /// The type of data stored in the column.
  Type get dataType => _dataType;
}

class DataCollectionIterator<E extends _TableEntity> implements Iterator<E> {
  final DataCollectionBase<E> _iterable;
  final int _length;
  int _index;
  E _current;

  DataCollectionIterator(DataCollectionBase<E> iterable)
      : _iterable = iterable,
        _length = iterable.length,
        _index = 0;

  E get current => _current;

  bool moveNext() {
    int length = _iterable.length;
    if (_length != length) {
      throw new ConcurrentModificationError(_iterable);
    }
    if (_index >= length) {
      _current = null;
      return false;
    }
    _current = _iterable.elementAt(_index);
    _index++;
    return true;
  }
}

class DataCollectionBase<E extends _TableEntity> extends IterableBase<E> {
  List<E> _base;
  DataTable _table;

  void _releaseItems(int start, int end) {
    while (start < end) {
      _base[start]._table = null;
      start++;
    }
  }

  void _updateItems(int start) {
    var len = length;
    while (start < len) {
      _base[start]
          .._table = _table
          .._index = start++;
    }
  }

  DataCollectionBase(DataTable table)
      : _base = <E>[],
        _table = table;

  @override
  Iterator<E> get iterator => new DataCollectionIterator<E>(this);

  @override
  E get first => _base.first;

  @override
  E get last => _base.last;

  @override
  E get single => _base.single;

  @override
  int get length => _base.length;

  @override
  E elementAt(int index) => _base[index];

  // List interface.

  E operator [](int index) => _base[index];

  void add(E value) {
    var index = length;
    _base.add(value);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, 1);
  }

  void insert(int index, E value) {
    _base.insert(index, value);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, 1);
  }

  void insertAll(int index, Iterable<E> iterable) {
    _base.insertAll(index, iterable);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, iterable.length);
  }

  void addAll(Iterable<E> iterable) {
    var index = length;
    _base.addAll(iterable);
    _updateItems(index);
    _table._onRowsOrColumnsInserted(this, index, iterable.length);
  }

  bool remove(E element) {
    var index = _base.indexOf(element);
    if (index == -1) return false;
    removeAt(index);
    return true;
  }

  void clear() {
    var len = length;
    if (len == 0) return;
    _releaseItems(0, len);
    _base.clear();
    _table._onRowsOrColumnsRemoved(this, 0, len);
  }

  E removeAt(int index) {
    var e = _base.removeAt(index);
    e._table = null;
    _updateItems(index);
    _table._onRowsOrColumnsRemoved(this, index, 1);
    return e;
  }

  E removeLast() {
    var e = _base.removeLast();
    e._table = null;
    _table._onRowsOrColumnsRemoved(this, length, 1);
    return e;
  }

  void removeRange(int start, int end) {
    _releaseItems(start, end);
    _base.removeRange(start, end);
    _updateItems(start);
    _table._onRowsOrColumnsRemoved(this, start, end - start);
  }
}

class DataRowCollection extends DataCollectionBase<DataRow> {
  DataRow _toDataRow(value) {
    if (value is DataRow) return value;
    return new DataRow._internal(_table, value);
  }

  DataRowCollection(DataTable table) : super(table);

  /// Adds a new row to this collection.
  ///
  /// [value] can be an instance of [DataRow] or a [List].
  @override
  void add(value) {
    super.add(_toDataRow(value));
  }

  @override
  void addAll(Iterable iterable) {
    super.addAll(iterable.map(_toDataRow));
  }

  @override
  void insert(int index, value) {
    super.insert(index, _toDataRow(value));
  }

  @override
  void insertAll(int index, Iterable iterable) {
    super.insertAll(index, iterable.map(_toDataRow));
  }
}

class DataColumnCollection extends DataCollectionBase<DataColumn> {
  DataColumnCollection(DataTable table) : super(table);

  void add2(String name, Type type) {
    add(new DataColumn(name, type));
  }
}

class DataTable {
  Map<String, int> _columnIndexByName;
  DataColumnCollection _columns;
  DataRowCollection _rows;

  StreamController<DataCellChangeRecord> _cellChangeController;
  StreamController<DataCollectionChangeRecord> _columnsChangeController;
  StreamController<DataCollectionChangeRecord> _rowsChangeController;

  void _onCellChanged(int rowIndex, int columnIndex, oldValue, newValue) {
    if (_cellChangeController != null) {
      var record =
          new DataCellChangeRecord(rowIndex, columnIndex, oldValue, newValue);
      _cellChangeController.add(record);
    }
  }

  void _onRowsOrColumnsInserted(DataCollectionBase source, int index,
      int count) {
    var record = new DataCollectionChangeRecord(index, count, 0);
    if (source == _columns) {
      _insertColumns(index, count);
      _updateColumnIndexes(index);
      if (_columnsChangeController !=
          null) _columnsChangeController.add(record);
    } else {
      if (_rowsChangeController != null) _rowsChangeController.add(record);
    }
  }

  void _onRowsOrColumnsRemoved(DataCollectionBase source, int index,
      int count) {
    var record = new DataCollectionChangeRecord(index, 0, count);
    if (source == _columns) {
      _removeColumns(index, count);
      _updateColumnIndexes(index);
      _columnsChangeController.add(record);
    } else {
      _rowsChangeController.add(record);
    }
  }

  void _insertColumns(int start, int count) {
    for (var row in _rows) {
      row._cells.insertAll(start, new List(count));
    }
  }

  void _removeColumns(int start, int count) {
    for (var row in _rows) {
      row._cells.removeRange(start, start + count);
    }
  }

  void _updateColumnIndexes(int start) {
    var end = _columns.length;
    while (start < end) {
      _columnIndexByName[_columns[start].name] = start++;
    }
  }

  /// Creates a [DataTable] with optional data [data].
  ///
  /// The first row in [data] contains the column names.
  /// The data type of each column is determined by the first non-null value
  /// in that column.
  ///
  /// All values in each column are expected to be of the same type,
  /// and all rows are expected to have the same length.
  DataTable([List<List> data]) {
    _columnIndexByName = <String, int>{};
    _rows = new DataRowCollection(this);
    _columns = new DataColumnCollection(this);

    if (data == null) return;

    var colCount = data.first.length;
    var rowCount = data.length;

    for (var colIndex = 0; colIndex < colCount; colIndex++) {
      var name = data[0][colIndex];
      var type = Object;
      for (var rowIndex = 1; rowIndex < rowCount; rowIndex++) {
        var value = data[rowIndex][colIndex];
        if (value == null) continue;
        if (value is String) type = String;
        if (value is num) type = num;
        if (value is List) type = List;
        break;
      }
      _columns.add2(name, type);
    }

    _rows.addAll(data.getRange(1, rowCount));
  }

  DataColumnCollection get columns => _columns;

  DataRowCollection get rows => _rows;

  Stream<DataCellChangeRecord> get onCellChange {
    if (_cellChangeController == null) {
      _cellChangeController =
          new StreamController.broadcast(sync: true, onCancel: () {
        _cellChangeController = null;
      });
    }
    return _cellChangeController.stream;
  }

  Stream<DataCollectionChangeRecord> get onColumnsChange {
    if (_columnsChangeController == null) {
      _columnsChangeController =
          new StreamController.broadcast(sync: true, onCancel: () {
        _columnsChangeController = null;
      });
    }
    return _columnsChangeController.stream;
  }

  Stream<DataCollectionChangeRecord> get onRowsChange {
    if (_rowsChangeController == null) {
      _rowsChangeController =
          new StreamController.broadcast(sync: true, onCancel: () {
        _rowsChangeController = null;
      });
    }
    return _rowsChangeController.stream;
  }

  int getColumnIndexByName(String name) {
    if (_columnIndexByName.containsKey(name)) return _columnIndexByName[name];
    return -1;
  }

  List getColumnValues(int columnIndex) {
    var list = [];
    for (var row in _rows) {
      list.add(row[columnIndex]);
    }
    return list;
  }
}
