part of modern_charts;

final _pieChartDefaultOptions = {
  // num - If between 0 and 1, displays a donut chart. The hole with have a
  // radius equal to this value times the radius of the chart.
  'pieHole': 0,

  // Map - An object that controls the series.
  'series': {
    // Map - An object that controls the series labels.
    'labels': {
      // bool - Whether to show the labels.
      'enabled': false,

      // (num) -> String - A function used to format the labels.
      'formatter': null,

      'style': {
        'color': 'white',
        'fontFamily': _GLOBAL_FONT_FAMILY,
        'fontSize': 13,
        'fontStyle': 'normal'
      }
    }
  }
};

/// 12 o'clock.
const _START_ANGLE = -_PI_2;

const _highlightOuterRadiusFactor = 1.05;

/// A pie in a pie chart.
class _Pie extends _Entity {
  num oldStartAngle;
  num oldEndAngle;
  num startAngle;
  num endAngle;

  Point center;
  num innerRadius;
  num outerRadius;

  // [_Series] field.
  String name;

  bool get isEmpty => startAngle == endAngle;

  bool containsPoint(Point p) {
    p = p - center;
    var mag = p.magnitude;
    if (mag >= outerRadius || mag <= innerRadius) return false;
    var angle = atan2(p.y, p.x);
    if (angle < _START_ANGLE) angle += _2PI;
    return angle > startAngle && angle < endAngle;
  }

  @override
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight) {
    var a1 = lerp(oldStartAngle, startAngle, percent);
    var a2 = lerp(oldEndAngle, endAngle, percent);
    if (highlight) {
      ctx.fillStyle = highlightColor;
      ctx.beginPath();
      ctx.arc(center.x, center.y, _highlightOuterRadiusFactor * outerRadius, a1,
          a2);
      ctx.arc(center.x, center.y, innerRadius, a2, a1, true);
      ctx.fill();
    }
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(center.x, center.y, outerRadius, a1, a2);
    ctx.arc(center.x, center.y, innerRadius, a2, a1, true);
    ctx.fill();
    ctx.stroke();
  }

  @override
  void save() {
    oldStartAngle = startAngle;
    oldEndAngle = endAngle;
    super.save();
  }
}

class PieChart extends Chart {
  Point _center;
  num _outerRadius;
  num _innerRadius;
  ValueFormatter _labelFormatter;

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();
    var rect = _seriesAndAxesBox;
    var halfW = rect.width >> 1;
    var halfH = rect.height >> 1;
    _center = new Point(rect.left + halfW, rect.top + halfH);
    _outerRadius = min(halfW, halfH) / _highlightOuterRadiusFactor;
    var pieHole = _options['pieHole'];
    if (pieHole > 1) pieHole = 0;
    if (pieHole < 0) pieHole = 0;
    _innerRadius = pieHole * _outerRadius;

    _labelFormatter =
        _options['series']['labels']['formatter'] ?? (num value) => '$value';
  }

  @override
  void _dataRowsChanged(DataCollectionChangeRecord record) {
    _updateSeriesVisible(record.index, record.removedCount, record.addedCount);
    super._dataRowsChanged(record);
    _updateLegendContent();
  }

  @override
  bool _drawSeries(double percent) {
    _seriesContext
      ..lineWidth = 2
      ..strokeStyle = '#fff'
      ..textAlign = 'center'
      ..textBaseline = 'middle';
    var pies = _seriesList.first.entities as List<_Pie>;
    for (var pie in pies) {
      if (pie.isEmpty && percent == 1.0) continue;
      var highlight = pie.index == _focusedSeriesIndex ||
          pie.index == _focusedEntityGroupIndex;
      pie.draw(_seriesContext, percent, highlight);
    }

    if (percent == 1.0) {
      var opt = _options['series']['labels'];
      if (opt['enabled']) {
        _seriesContext
          ..fillStyle = opt['style']['color']
          ..font = _getFont(opt['style']);
        for (var pie in pies) {
          if (pie.isEmpty) continue;
          var angle = .5 * (pie.startAngle + pie.endAngle);
          var p = polarToCartesian(
              _center, .25 * _innerRadius + .75 * _outerRadius, angle);
          _seriesContext.fillText(_labelFormatter(pie.value), p.x, p.y);
        }
      }
    }

    return false;
  }

  @override
  int _getEntityGroupIndex(num x, num y) {
    var p = new Point(x - _center.x, y - _center.y);
    var mag = p.magnitude;
    if (mag >= _outerRadius || mag <= _innerRadius) return -1;
    var angle = atan2(p.y, p.x);
    if (angle < _START_ANGLE) angle += _2PI;
    var pies = _seriesList.first.entities;
    for (var i = pies.length - 1; i >= 0; i--) {
      var pie = pies[i];
      if (angle > pie.startAngle && angle < pie.endAngle) return i;
    }
    return -1;
  }

  @override
  List<String> _getLegendLabels() => _dataTable.getColumnValues(0);

  @override
  Point _getTooltipPosition() {
    var pie = _seriesList.first.entities[_focusedEntityGroupIndex] as _Pie;
    var angle = .5 * (pie.startAngle + pie.endAngle);
    var point = polarToCartesian(_center, .5 * _outerRadius, angle);
    var x = point.x - .5 * _tooltip.offsetWidth;
    var y = point.y - _tooltip.offsetHeight;
    return new Point(x, y);
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    // Override the colors.
    color = _getColor(entityIndex);
    highlightColor = _changeColorAlpha(color, .5);
    var name = _dataTable.rows[entityIndex][0];
    var startAngle = _START_ANGLE;
    if (entityIndex > 0 && _seriesList != null) {
      var prevPie = _seriesList[0].entities[entityIndex - 1] as _Pie;
      startAngle = prevPie.endAngle;
    }
    return new _Pie()
      ..index = entityIndex
      ..value = value
      ..name = name
      ..color = color
      ..highlightColor = highlightColor
      ..oldStartAngle = startAngle
      ..oldEndAngle = startAngle
      ..center = _center
      ..innerRadius = _innerRadius
      ..outerRadius = _outerRadius
      ..startAngle = startAngle
      ..endAngle = startAngle; // To be updated in [_updateSeries].
  }

  void _updateSeries([int index]) {
    // Example data table:
    //   Browser  Share
    //   Chrome   .35
    //   IE       .30
    //   Firefox  .20
    //   Other    .15

    var sum = 0.0;
    var startAngle = _START_ANGLE;
    var pieCount = _dataTable.rows.length;
    var pies = _seriesList[0].entities as List<_Pie>;

    // Sum the values of all visible pies.
    for (var i = 0; i < pieCount; i++) {
      if (_seriesVisible[i]) {
        sum += pies[i].value;
      }
    }

    for (var i = 0; i < pieCount; i++) {
      var pie = pies[i];
      var color = _getColor(i);
      pie.index = i;
      pie.name = _dataTable.rows[i][0];
      pie.color = color;
      pie.highlightColor = _getHighlightColor(color);
      pie.center = _center;

      if (_seriesVisible[i]) {
        pie.startAngle = startAngle;
        pie.endAngle = startAngle + pie.value * _2PI / sum;
        startAngle = pie.endAngle;
      } else {
        pie.startAngle = startAngle;
        pie.endAngle = startAngle;
      }
    }
  }

  @override
  void _seriesVisibilityChanged(int index) => _updateSeries();

  @override
  void _updateTooltipContent() {
    var pie = _seriesList[0].entities[_focusedEntityGroupIndex] as _Pie;
    _tooltip.style
      ..borderColor = pie.color
      ..padding = '3px 10px';
    var value = pie.value.toString();
    if (_tooltipValueFormatter != null) {
      value = _tooltipValueFormatter(pie.value);
    }
    _tooltip.innerHtml = '${pie.name}: <strong>$value</strong>';
  }

  PieChart(Element container) : super(container) {
    _defaultOptions = extendMap(globalOptions, _pieChartDefaultOptions);
  }
}
