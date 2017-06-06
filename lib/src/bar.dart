part of modern_charts;

final _barChartDefaultOptions = {
  // Map - An object that controls the series.
  'series': {
    // Map - An object that controls the series labels.
    'labels': {
      // bool - Whether to show the labels.
      'enabled': false,
      'style': {
        'color': '#212121',
        'fontFamily': _GLOBAL_FONT_FAMILY,
        'fontSize': 13,
        'fontStyle': 'normal'
      }
    }
  },

  // Map - An object that controls the x-axis.
  'xAxis': const {
    // String - The color of the horizontal grid lines.
    'gridLineColor': '#c0c0c0',

    // num - The width of the horizontal grid lines.
    'gridLineWidth': 1,

    // String - The color of the axis itself.
    'lineColor': '#c0c0c0',

    // num - The width of the axis itself.
    'lineWidth': 1,

    // Map - An object that controls the axis labels.
    'labels': const {
      'style': const {
        // String - The labels' color.
        'color': '#212121',

        // String - The labels' font family.
        'fontFamily': _GLOBAL_FONT_FAMILY,

        // num - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      }
    },

    // String - The position of the axis relative to the chart area.
    // Supported values: 'bottom'.
    'position': 'bottom',

    // Map - An object that controls the axis title.
    'title': const {
      // Map - An object that controls the styling of the axis title.
      'style': const {
        // String - The title's color.
        'color': '#212121',

        // String - The title's font family.
        'fontFamily': _GLOBAL_FONT_FAMILY,

        // num - The title's font size.
        'fontSize': 15,

        // String - The title's font style.
        'fontStyle': 'normal'
      },

      // The title text. A `null` value means the title is hidden.
      'text': null
    }
  },

  // Map - An object that controls the y-axis.
  'yAxis': const {
    // String - The color of the vertical grid lines.
    'gridLineColor': '#c0c0c0',

    // num - The width of the vertical grid lines.
    'gridLineWidth': 0,

    // String - The color of the axis itself.
    'lineColor': '#c0c0c0',

    // num - The width of the axis itself.
    'lineWidth': 0,

    // num - The interval of the tick marks in axis unit. If `null`, this value
    // is automatically calculated.
    'interval': null,

    // Map - An object that controls the axis labels.
    'labels': const {
      // (num value) -> String - A function that formats the labels.
      'formatter': null,

      // Map - An object that controls the styling of the axis labels.
      'style': const {
        // String - The labels' color.
        'color': '#212121',

        // String - The labels' font family.
        'fontFamily': _GLOBAL_FONT_FAMILY,

        // num - The labels' font size.
        'fontSize': 13,

        // String - The labels' font style.
        'fontStyle': 'normal'
      },
    },

    // num - The desired maximum value on the axis. If set, the calculated value
    // is guaranteed to be >= this value.
    'maxValue': null,

    // num - The minimum interval. If `null`, this value is automatically
    // calculated.
    'minInterval': null,

    // num - The desired minimum value on the axis. If set, the calculated value
    // is guaranteed to be <= this value.
    'minValue': null,

    // String - The position of the axis relative to the chart area.
    // Supported values: 'left'.
    'position': 'left',

    // Map - An object that controls the axis title.
    'title': const {
      // Map - An object that controls the styling of the axis title.
      'style': const {
        // String - The title's color.
        'color': '#212121',

        // String - The title's font family.
        'fontFamily': _GLOBAL_FONT_FAMILY,

        // num - The title's font size.
        'fontSize': 15,

        // String - The title's font style.
        'fontStyle': 'normal'
      },

      // The title text. A `null` value means the title is hidden.
      'text': null
    }
  }
};

class _Bar extends _Entity {
  num oldLeft;
  num oldWidth;
  num oldHeight;
  num bottom;
  num left;
  num width;
  num height;

  num get right => left + width;

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    var x = lerp(oldLeft, left, percent);
    var h = lerp(oldHeight, height, percent);
    var w = lerp(oldWidth, width, percent);
    ctx.fillStyle = color;
    ctx.fillRect(x, bottom - h, w, h);
    if (highlight) {
      ctx.fillStyle = 'rgba(255, 255, 255, .5)';
      ctx.fillRect(x, bottom - h, w, h);
    }
  }

  @override
  void save() {
    oldLeft = left;
    oldWidth = width;
    oldHeight = height;
    super.save();
  }
}

class BarChart extends _TwoAxisChart {
  num _barWidth;
  num _barSpacing = 0;
  num _barGroupWidth;

  num _getBarLeft(int seriesIndex, int barIndex) {
    return _xLabelX(barIndex) -
        .5 * _barGroupWidth +
        _countVisibleSeries(seriesIndex) * (_barWidth + _barSpacing);
  }

  void _updateBarWidth() {
    var count = _countVisibleSeries();
    if (count > 0) {
      _barWidth = (_barGroupWidth + _barSpacing) / count - _barSpacing;
    } else {
      _barWidth = 0.0;
    }
  }

  num _valueToBarHeight(num value) {
    if (value != null) return _xAxisTop - _valueToY(value);
    return 0;
  }

  @override
  void _calculateAverageYValues([int index]) {
    if (!_options['tooltip']['enabled']) return;

    var entityCount = _seriesList.first.entities.length;
    var start = index ?? 0;
    var end = index == null ? entityCount : index + 1;

    _averageYValues ??= <int>[];
    _averageYValues.length = entityCount;

    for (var i = start; i < end; i++) {
      var sum = 0.0;
      var count = 0;
      for (var j = _seriesList.length - 1; j >= 0; j--) {
        if (!_seriesVisible[j]) continue;
        var bar = _seriesList[j].entities[i] as _Bar;
        if (bar.value != null) {
          sum += bar.height;
          count++;
        }
      }
      _averageYValues[i] = (count > 0) ? _xAxisTop - sum ~/ count : null;
    }
  }

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();
    _barGroupWidth = .618 * _xLabelHop; // Golden ratio.
    _tooltipOffset = .5 * _barGroupWidth + 5;
    _updateBarWidth();
  }

  @override
  bool _drawSeries(double percent) {
    for (var i = 0, n = _seriesList.length; i < n; i++) {
      if (percent == 1.0 && !_seriesVisible[i]) continue;

      var series = _seriesList[i];

      // Draw the bars.
      for (_Bar bar in series.entities) {
        if (bar.value == null) continue;
        var highlight = bar.index == _focusedEntityGroupIndex;
        bar.draw(_seriesContext, percent, highlight);
      }

      // Draw the labels.
      if (percent == 1.0) {
        var opt = _options['series']['labels'];
        if (!opt['enabled']) continue;
        _seriesContext
          ..fillStyle = opt['style']['color']
          ..font = _getFont(opt['style'])
          ..textAlign = 'center'
          ..textBaseline = 'alphabetic';
        for (_Bar bar in series.entities) {
          if (bar.value == null) continue;
          var x = bar.left + .5 * bar.width;
          var y = _xAxisTop - bar.height - 5;
          _seriesContext.fillText(_yLabelFormatter(bar.value), x, y);
        }
      }
    }

    return false;
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    var left = _getBarLeft(seriesIndex, entityIndex);
    var oldLeft = left;
//    if (seriesIndex > 0 && _seriesList != null) {
//      var leftAdjacentBar =
//          _seriesList[seriesIndex - 1].entities[entityIndex] as _Bar;
//      oldLeft = leftAdjacentBar.right;
//    }
    var height = _valueToBarHeight(value);

    // Animate width.
    var oldHeight = height;
    var oldWidth = 0;

    if (_seriesList == null) {
      // Data table changed. Animate height.
      oldHeight = 0;
      oldWidth = _barWidth;
    }

    return new _Bar()
      ..index = entityIndex
      ..value = value
      ..color = color
      ..highlightColor = highlightColor
      ..bottom = _xAxisTop
      ..oldLeft = oldLeft
      ..left = left
      ..oldHeight = oldHeight
      ..height = height
      ..oldWidth = oldWidth
      ..width = _barWidth;
  }

  @override
  void _updateSeries([int index]) {
    var entityCount = _dataTable.rows.length;
    for (var i = 0; i < _seriesList.length; i++) {
      var series = _seriesList[i];
      var left = _getBarLeft(i, 0);
      var barWidth = _seriesVisible[i] ? _barWidth : 0.0;
      var color = _getColor(i);
      var highlightColor = _getHighlightColor(color);
      series.color = color;
      series.highlightColor = highlightColor;
      for (var j = 0; j < entityCount; j++) {
        var bar = series.entities[j] as _Bar;
        bar.index = j;
        bar.color = color;
        bar.highlightColor = highlightColor;
        bar.left = left;
        bar.bottom = _xAxisTop;
        bar.height = _valueToBarHeight(bar.value);
        bar.width = barWidth;
        left += _xLabelHop;
      }
    }
  }

  @override
  void _seriesVisibilityChanged(int index) {
    _updateBarWidth();
    _updateSeries();
    _calculateAverageYValues();
  }

  BarChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _barChartDefaultOptions);
  }
}
