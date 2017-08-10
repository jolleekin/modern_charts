library example;

import 'dart:html';
import 'package:modern_charts/modern_charts.dart';
import 'dart:math';

final random = new Random();

int rand(int min, int max) => random.nextInt(max - min) + min;

void main() {
  createBarChart();
  createLineChart();
  createPieChart();
  createRadarChart();
  createGaugeChart();
}

Element createContainer() {
  var e = new DivElement()
    ..style.height = '400px'
//    ..style.width = '800px'
    ..style.maxWidth = '100%'
    ..style.marginBottom = '50px';
  document.body.append(e);
  return e;
}
// February
void createBarChart() {
  var table = new DataTable([
    ['Categories', 'Long series name', 'Series 2', 'Series 3'],
    ['January', 1, 3, 5],
    ['February', 3, 4, 6],
    ['March', 4, 3, 1],
    ['April', null, 5, 1],
    ['May', 3, 4, 2],
    ['June', 5, 10, 4],
    ['July', 4, 12, 8],
    ['August', 1, 3, 5],
    ['September', 3, 4, 6],
    ['October', 4, 3, 1],
    ['November', null, 5, 1],
    ['December', 3, 4, 2],
  ]);

  var changeDataButton = new ButtonElement()..text = 'Change data';
  document.body.append(changeDataButton);

  var insertRemoveColumnButton = new ButtonElement()
    ..text = 'Insert/remove data column';
  document.body.append(insertRemoveColumnButton);

  var insertRemoveRowButton = new ButtonElement()
    ..text = 'Insert/remove data row';
  document.body.append(insertRemoveRowButton);

  var container = createContainer();

  var options = {
    'animation': {
      'onEnd': () {
        changeDataButton.disabled = false;
        insertRemoveColumnButton.disabled = false;
        insertRemoveRowButton.disabled = false;
      }
    },
    'series': {
      'labels': {'enabled': true}
    },
    'xAxis': {
      'labels': {'maxRotation': 90, 'minRotation': 0}
    },
    'yAxis': {'maxValue': 30, 'minInterval': 5},
    'title': {'text': 'Bar Chart Demo'},
    'tooltip': {'valueFormatter': (value) => '$value units'}
  };

  var chart = new BarChart(container);
  chart.draw(table, options);

  void disableAllButtons() {
    changeDataButton.disabled = true;
    insertRemoveColumnButton.disabled = true;
    insertRemoveRowButton.disabled = true;
  }

  changeDataButton.onClick.listen((_) {
    disableAllButtons();
    for (var row in table.rows) {
      for (var i = 1; i < table.columns.length; i++) {
        row[i] = rand(2, 20);
      }
    }
    chart.update();
  });

  var insertColumn = true;
  insertRemoveColumnButton.onClick.listen((_) {
    disableAllButtons();
    if (insertColumn) {
      table.columns.insert(2, new DataColumn('New series', num));
      for (var row in table.rows) {
        row[2] = rand(2, 20);
      }
    } else {
      table.columns.removeAt(2);
    }
    insertColumn = !insertColumn;
    chart.update();
  });

  var insertRow = true;
  insertRemoveRowButton.onClick.listen((_) {
    disableAllButtons();
    if (insertRow) {
      var values = <dynamic>['New'];
      for (var i = 1; i < table.columns.length; i++) {
        values.add(rand(2, 20));
      }
      table.rows.insert(2, values);
    } else {
      table.rows.removeAt(2);
    }
    insertRow = !insertRow;
    chart.update();
  });
}

void createLineChart() {
  var table = new DataTable([
    ['Categories', 'Series 1', 'Series 2', 'Series 3'],
    ['Monday', 1, 3, 5],
    ['Tuesday', 3, 4, 6],
    ['Wednesday', 4, 3, 1],
    ['Thursday', null, 5, 1],
    ['Friday', 3, 4, 2],
    ['Saturday', 5, 10, 4],
    ['Sunday', 4, 12, 8]
  ]);

  var changeDataButton = new ButtonElement()..text = 'Change data';
  document.body.append(changeDataButton);

  var insertRemoveColumnButton = new ButtonElement()
    ..text = 'Insert/remove data column';
  document.body.append(insertRemoveColumnButton);

  var insertRemoveRowButton = new ButtonElement()
    ..text = 'Insert/remove data row';
  document.body.append(insertRemoveRowButton);

  var container = createContainer();

  var options = {
    'animation': {
      'onEnd': () {
        changeDataButton.disabled = false;
        insertRemoveColumnButton.disabled = false;
        insertRemoveRowButton.disabled = false;
      }
    },
    'series': {
      'fillOpacity': 0.25,
    },
    'yAxis': {'minInterval': 5},
    'title': {'text': 'Line Chart Demo'}
  };

  var chart = new LineChart(container);
  chart.draw(table, options);

  void disableAllButtons() {
    changeDataButton.disabled = true;
    insertRemoveColumnButton.disabled = true;
    insertRemoveRowButton.disabled = true;
  }

  changeDataButton.onClick.listen((_) {
    disableAllButtons();
    for (var row in table.rows) {
      for (var i = 1; i < table.columns.length; i++) {
        row[i] = rand(2, 20);
      }
    }
    chart.update();
  });

  var insertColumn = true;
  insertRemoveColumnButton.onClick.listen((_) {
    disableAllButtons();
    if (insertColumn) {
      table.columns.insert(2, new DataColumn('New series', num));
      for (var row in table.rows) {
        row[2] = rand(2, 20);
      }
    } else {
      table.columns.removeAt(2);
    }
    insertColumn = !insertColumn;
    chart.update();
  });

  var insertRow = true;
  insertRemoveRowButton.onClick.listen((_) {
    disableAllButtons();
    if (insertRow) {
      var values = <Object>['New'];
      for (var i = 1; i < table.columns.length; i++) {
        values.add(rand(2, 20));
      }
      table.rows.insert(2, values);
    } else {
      table.rows.removeAt(2);
    }
    insertRow = !insertRow;
    chart.update();
  });
}

void createPieChart() {
  var changeDataButton = new ButtonElement()..text = 'Change data';
  document.body.append(changeDataButton);

  var insertRemoveRowButton = new ButtonElement()
    ..text = 'Insert/remove data row';
  document.body.append(insertRemoveRowButton);

  var container = createContainer();
  var table = new DataTable([
    ['Browser', 'Share'],
    ['Chrome', 35],
    ['Firefox', 20],
    ['IE', 30],
    ['Opera', 5],
    ['Safari', 8],
    ['Other', 2]
  ]);
  var chart = new PieChart(container);
  chart.draw(table, {
    'animation': {
      'onEnd': () {
        changeDataButton.disabled = false;
        insertRemoveRowButton.disabled = false;
      }
    },
    'pieHole': .5,
    'series': {
      'counterclockwise': true,
      'labels': {'enabled': true},
      'startAngle': 90 + 10 * 360,
    },
    'title': {'text': 'Pie Chart Demo'},
  });

  void disableAllButtons() {
    changeDataButton.disabled = true;
    insertRemoveRowButton.disabled = true;
  }

  changeDataButton.onClick.listen((_) {
    disableAllButtons();
    for (var row in table.rows) {
      for (var i = 1; i < table.columns.length; i++) {
        row[i] = rand(2, 25);
      }
    }
    chart.update();
  });

  var insertRow = true;
  insertRemoveRowButton.onClick.listen((_) {
    insertRemoveRowButton.disabled = true;
    if (insertRow) {
      var values = ['New', 6];
      table.rows.insert(2, values);
    } else {
      table.rows.removeAt(2);
    }
    insertRow = !insertRow;
    chart.update();
  });
}

void createRadarChart() {
  var table = new DataTable([
    ['Categories', 'Series 1'],
    ['Monday', 8],
    ['Tuesday', 17],
    ['Wednesday', 7],
    ['Thursday', 16],
    ['Friday', 12],
    ['Saturday', 5],
    ['Sunday', 14]
  ]);

  var changeDataButton = new ButtonElement()..text = 'Change data';
  document.body.append(changeDataButton);

  var insertRemoveColumnButton = new ButtonElement()
    ..text = 'Insert/remove data column';
  document.body.append(insertRemoveColumnButton);

  var insertRemoveRowButton = new ButtonElement()
    ..text = 'Insert/remove data row';
  document.body.append(insertRemoveRowButton);

  var container = createContainer();

  var options = {
    'animation': {
      'onEnd': () {
        changeDataButton.disabled = false;
        insertRemoveColumnButton.disabled = false;
        insertRemoveRowButton.disabled = false;
      }
    },
    'series': {
      'labels': {'enabled': true}
    },
    'title': {'text': 'Radar Chart Demo'},
    'tooltip': {'valueFormatter': (value) => '$value units'}
  };

  var chart = new RadarChart(container);
  chart.draw(table, options);

  void disableAllButtons() {
    changeDataButton.disabled = true;
    insertRemoveColumnButton.disabled = true;
    insertRemoveRowButton.disabled = true;
  }

  changeDataButton.onClick.listen((_) {
    disableAllButtons();
    for (var row in table.rows) {
      for (var i = 1; i < table.columns.length; i++) {
        row[i] = rand(5, 20);
      }
    }
    chart.update();
  });

  var insertColumn = true;
  insertRemoveColumnButton.onClick.listen((_) {
    disableAllButtons();
    if (insertColumn) {
      table.columns.insert(2, new DataColumn('New series', num));
      for (var row in table.rows) {
        row[2] = rand(5, 20);
      }
    } else {
      table.columns.removeAt(2);
    }
    insertColumn = !insertColumn;
    chart.update();
  });

  var insertRow = true;
  insertRemoveRowButton.onClick.listen((_) {
    disableAllButtons();
    if (insertRow) {
      var values = <Object>['New'];
      for (var i = 1; i < table.columns.length; i++) {
        values.add(rand(5, 20));
      }
      table.rows.insert(2, values);
    } else {
      table.rows.removeAt(2);
    }
    insertRow = !insertRow;
    chart.update();
  });
}

void createGaugeChart() {
  var changeDataButton = new ButtonElement()..text = 'Change data';
  document.body.append(changeDataButton);

  var insertRemoveRowButton = new ButtonElement()
    ..text = 'Insert/remove data row';
  document.body.append(insertRemoveRowButton);

  var container = createContainer();
  var table = new DataTable([
    ['Browser', 'Share'],
    ['Memory', 25],
//    ['CPU', 75],
//    ['Disk', 40]
  ]);
  var chart = new GaugeChart(container);
  chart.draw(table, {
    'animation': {
      'easing': (double t) {
        t = 4 * t - 2;
        return (t * t * t - t) / 12 + .5;
      },
      'onEnd': () {
        changeDataButton.disabled = false;
        insertRemoveRowButton.disabled = false;
      }
    },
    'gaugeLabels': {'enabled': false},
    'title': {'text': 'Gauge Chart Demo'},
  });

  void disableAllButtons() {
    changeDataButton.disabled = true;
    insertRemoveRowButton.disabled = true;
  }

  changeDataButton.onClick.listen((_) {
    disableAllButtons();
    for (var row in table.rows) {
      for (var i = 1; i < table.columns.length; i++) {
        row[i] = rand(0, 101);
      }
    }
    chart.update();
  });

  var insertRow = true;
  insertRemoveRowButton.onClick.listen((_) {
    insertRemoveRowButton.disabled = true;
    if (insertRow) {
      var values = ['New', rand(0, 101)];
      table.rows.insert(1, values);
    } else {
      table.rows.removeAt(1);
    }
    insertRow = !insertRow;
    chart.update();
  });
}
