part of modern_charts;

final _gaugeChartDefaultOptions = {
  // String - The background color of the gauges.
  'gaugeBackgroundColor': '#dbdbdb',

  // Map - An object that controls the gauge labels.
  'gaugeLabels': {
    // bool - Whether to show the labels.
    'enabled': true,

    // Map - An object that controls the styling of the gauge labels.
    'style': {
      'color': '#212121',
      'fontFamily': _fontFamily,
      'fontSize': 13,
      'fontStyle': 'normal'
    }
  }
};

class _Gauge extends _Pie {
  String? backgroundColor;

  @override
  void draw(CanvasRenderingContext2D? ctx, double percent, bool highlight) {
    var tmpColor = color;
    var tmpEndAngle = endAngle;

    // Draw the background.

    endAngle = startAngle! + _2pi;
    color = backgroundColor;
    super.draw(ctx, 1.0, false);

    // Draw the foreground.

    color = tmpColor;
    endAngle = tmpEndAngle;
    super.draw(ctx, percent, highlight);

    // Draw the percent.

    var fs1 = .75 * innerRadius!;
    var font1 = '${fs1}px $_fontFamily';
    var text1 = lerp(oldValue, value, percent).round().toString();
    ctx!.font = font1;
    var w1 = ctx.measureText(text1).width!;

    var fs2 = .6 * fs1;
    var font2 = '${fs2}px $_fontFamily';
    var text2 = '%';
    ctx.font = font2;
    var w2 = ctx.measureText(text2).width!;

    num y = center!.y + .3 * fs1;
    ctx
      ..font = font1
      ..fillText(text1, center!.x - .5 * w2, y)
      ..font = font2
      ..fillText(text2, center!.x + .5 * w1, y);
  }
}

class GaugeChart extends Chart {
  late num _gaugeHop;
  num? _gaugeInnerRadius;
  num? _gaugeOuterRadius;
  late num _gaugeCenterY;
  final num _startAngle = -_pi_2;

  Point _getGaugeCenter(int index) =>
      Point((index + .5) * _gaugeHop, _gaugeCenterY);

  num _valueToAngle(num value) => value * _2pi / 100;

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();

    var gaugeCount = _dataTable!.rows!.length;
    var labelTotalHeight = 0;
    if (_options!['gaugeLabels']['enabled']) {
      labelTotalHeight = _axisLabelMargin +
          _options!['gaugeLabels']['style']['fontSize'] as int;
    }

    _gaugeCenterY = _seriesAndAxesBox.top + .5 * _seriesAndAxesBox.height;
    _gaugeHop = _seriesAndAxesBox.width / gaugeCount;

    var availW = .618 * _gaugeHop; // Golden ratio.
    var availH = _seriesAndAxesBox.height - 2 * labelTotalHeight;
    _gaugeOuterRadius = .5 * min(availW, availH) / _highlightOuterRadiusFactor;
    _gaugeInnerRadius = .5 * _gaugeOuterRadius!;
  }

  @override
  bool _drawSeries(double percent) {
    var style = _options!['gaugeLabels']['style'];
    var labelsEnabled = _options!['gaugeLabels']['enabled'];
    _seriesContext
      ..strokeStyle = 'white'
      ..textAlign = 'center';
    for (_Gauge gauge in _seriesList![0].entities as Iterable<_Gauge>) {
      var highlight = gauge.index == _focusedEntityIndex;
      gauge.draw(_seriesContext, percent, highlight);

      if (!labelsEnabled) continue;

      var x = gauge.center!.x;
      var y = gauge.center!.y +
          gauge.outerRadius! +
          style['fontSize'] +
          _axisLabelMargin;
      _seriesContext
        ..fillStyle = style['color']
        ..font = _getFont(style)
        ..textAlign = 'center'
        ..fillText(gauge.name, x, y);
    }
    return false;
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    // Override the colors.
    color = _getColor(entityIndex);
    highlightColor = _changeColorAlpha(color, .5);

    var name = _dataTable!.rows![entityIndex]![0];
    return _Gauge()
      ..index = entityIndex
      ..value = value
      ..name = name
      ..color = color
      ..backgroundColor = _options!['gaugeBackgroundColor']
      ..highlightColor = highlightColor
      ..oldValue = 0
      ..oldStartAngle = _startAngle
      ..oldEndAngle = _startAngle
      ..center = _getGaugeCenter(entityIndex)
      ..innerRadius = _gaugeInnerRadius
      ..outerRadius = _gaugeOuterRadius
      ..startAngle = _startAngle
      ..endAngle = _startAngle + _valueToAngle(value);
  }

  @override
  void _updateSeries() {
    var n = _dataTable!.rows!.length;
    for (var i = 0; i < n; i++) {
      var gauge = _seriesList![0].entities[i] as _Gauge;
      var color = _getColor(i);
      var highlightColor = _changeColorAlpha(color, .5);
      gauge
        ..index = i
        ..name = _dataTable!.rows![i]![0]
        ..color = color
        ..highlightColor = highlightColor
        ..center = _getGaugeCenter(i)
        ..innerRadius = _gaugeInnerRadius
        ..outerRadius = _gaugeOuterRadius
        ..endAngle = _startAngle + _valueToAngle(gauge.value!);
    }
  }

  @override
  void _updateTooltipContent() {
    var gauge = _seriesList![0].entities[_focusedEntityIndex!] as _Gauge;
    _tooltip!.style
      ..borderColor = gauge.color
      ..padding = '4px 12px';
    var label = _tooltipLabelFormatter(gauge.name);
    var value = _tooltipValueFormatter!(gauge.value);
    _tooltip!.innerHtml = '$label: <strong>$value%</strong>';
  }

  @override
  int? _getEntityGroupIndex(num x, num y) {
    var p = Point(x, y);
    for (_Gauge g in _seriesList![0].entities as Iterable<_Gauge>) {
      if (g.containsPoint(p)) return g.index as int?;
    }
    return -1;
  }

  @override
  Point _getTooltipPosition() {
    var gauge = _seriesList![0].entities[_focusedEntityIndex!] as _Gauge;
    var x = gauge.center!.x - _tooltip!.offsetWidth ~/ 2;
    num y = gauge.center!.y -
        _highlightOuterRadiusFactor * gauge.outerRadius! -
        _tooltip!.offsetHeight -
        5;
    return Point(x, y);
  }

  GaugeChart(Element container) : super(container) {
    _defaultOptions = mergeMaps(globalOptions, _gaugeChartDefaultOptions);
    _defaultOptions!['legend']['position'] = 'none';
  }
}
