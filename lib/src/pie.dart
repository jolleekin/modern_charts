part of modern_charts;

final _pieChartDefaultOptions = {
  // num - If between 0 and 1, displays a donut chart. The hole will have a
  // radius equal to this value times the radius of the chart.
  'pieHole': 0,

  // Map - An object that controls the series.
  'series': {
    /// bool - Whether to draw the slices counterclockwise.
    'counterclockwise': false,

    // Map - An object that controls the series labels.
    'labels': {
      // bool - Whether to show the labels.
      'enabled': false,

      // (num) -> String - A function used to format the labels.
      'formatter': null,

      'style': {
        'color': 'white',
        'fontFamily': _fontFamily,
        'fontSize': 13,
        'fontStyle': 'normal'
      },
    },

    // num - The start angle in degrees. Default is -90, which is 12 o'clock.
    'startAngle': -90,
  },
};

const _clockwise = 1;
const _counterclockwise = -1;
const _highlightOuterRadiusFactor = 1.05;

/// A pie in a pie chart.
class _Pie extends _Entity {
  num? oldStartAngle;
  num? oldEndAngle;
  num? startAngle;
  num? endAngle;

  Point? center;
  num? innerRadius;
  num? outerRadius;

  // [_Series] field.
  String name = '';

  bool get isEmpty => startAngle == endAngle;

  bool containsPoint(Point p) {
    p -= center!;
    var mag = p.magnitude;
    if (mag > outerRadius! || mag < innerRadius!) return false;

    var angle = atan2(p.y, p.x);
    var chartStartAngle = (chart as dynamic)._startAngle;

    // Make sure [angle] is in range [chartStartAngle]..[chartStartAngle] + 2pi.
    angle = (angle - chartStartAngle) % _2pi + chartStartAngle;

    // If counterclockwise, make sure [angle] is in range
    // [start] - 2*pi..[start].
    if (startAngle! > endAngle!) angle -= _2pi;

    if (startAngle! <= endAngle!) {
      // Clockwise.
      return isInRange(angle, startAngle!, endAngle);
    } else {
      // Counterclockwise.
      return isInRange(angle, endAngle!, startAngle);
    }
  }

  @override
  void draw(CanvasRenderingContext2D? ctx, double percent, bool highlight) {
    var a1 = lerp(oldStartAngle, startAngle, percent);
    var a2 = lerp(oldEndAngle, endAngle, percent);
    if (a1 > a2) {
      var tmp = a1;
      a1 = a2;
      a2 = tmp;
    }
    if (highlight) {
      var highlightOuterRadius = _highlightOuterRadiusFactor * outerRadius!;
      ctx!.fillStyle = highlightColor;
      ctx.beginPath();
      ctx.arc(center!.x, center!.y, highlightOuterRadius, a1, a2);
      ctx.arc(center!.x, center!.y, innerRadius!, a2, a1, true);
      ctx.fill();
    }
    ctx!.fillStyle = color;
    ctx.beginPath();
    ctx.arc(center!.x, center!.y, outerRadius!, a1, a2);
    ctx.arc(center!.x, center!.y, innerRadius!, a2, a1, true);
    ctx.fill();
    ctx.stroke();

    if (formattedValue != null && chart is PieChart && a2 - a1 > pi / 36) {
      var options = chart!._options!['series']['labels'];
      if (options['enabled']) {
        var r = .25 * innerRadius! + .75 * outerRadius!;
        var a = .5 * (a1 + a2);
        var p = polarToCartesian(center!, r, a);
        ctx.fillStyle = options['style']['color'];
        ctx.fillText(formattedValue!, p.x, p.y);
      }
    }
  }

  @override
  void save() {
    oldStartAngle = startAngle;
    oldEndAngle = endAngle;
    super.save();
  }
}

class PieChart extends Chart {
  Point? _center;
  num? _outerRadius;
  num? _innerRadius;

  /// The start angle in radians.
  num? _startAngle;

  /// 1 means clockwise and -1 means counterclockwise.
  late num _direction;

  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();
    var rect = _seriesAndAxesBox;
    var halfW = rect.width >> 1;
    var halfH = rect.height >> 1;
    _center = Point(rect.left + halfW, rect.top + halfH);
    _outerRadius = min(halfW, halfH) / _highlightOuterRadiusFactor;
    var pieHole = _options!['pieHole'];
    if (pieHole > 1) pieHole = 0;
    if (pieHole < 0) pieHole = 0;
    _innerRadius = pieHole * _outerRadius;

    var opt = _options!['series'];
    _entityValueFormatter =
        opt['labels']['formatter'] ?? _defaultValueFormatter;
    _direction = opt['counterclockwise'] ? _counterclockwise : _clockwise;
    _startAngle = deg2rad(opt['startAngle']);
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
    var pies = _seriesList!.first.entities;
    var labelOptions = _options!['series']['labels'];
    _seriesContext.font = _getFont(labelOptions['style']);
    for (_Pie pie in pies as Iterable<_Pie>) {
      if (pie.isEmpty && percent == 1.0) continue;
      var highlight =
          pie.index == _focusedSeriesIndex || pie.index == _focusedEntityIndex;
      pie.draw(_seriesContext, percent, highlight);
    }

    return false;
  }

  @override
  int _getEntityGroupIndex(num x, num y) {
    var p = Point(x, y);
    var entities = _seriesList!.first.entities;
    for (var i = entities.length - 1; i >= 0; i--) {
      var pie = entities[i] as _Pie;
      if (pie.containsPoint(p)) return i;
    }
    return -1;
  }

  @override
  List<String?> _getLegendLabels() => _dataTable!.getColumnValues<String>(0);

  @override
  Point _getTooltipPosition() {
    var pie = _seriesList!.first.entities[_focusedEntityIndex!] as _Pie;
    var angle = .5 * (pie.startAngle! + pie.endAngle!);
    var radius = .5 * (_innerRadius! + _outerRadius!);
    var point = polarToCartesian(_center!, radius, angle);
    var x = point.x - .5 * _tooltip!.offsetWidth;
    var y = point.y - _tooltip!.offsetHeight;
    return Point(x, y);
  }

  @override
  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
      String highlightColor) {
    // Override the colors.
    color = _getColor(entityIndex);
    highlightColor = _changeColorAlpha(color, .5);
    var name = _dataTable!.rows![entityIndex]![0] as String;
    var startAngle = _startAngle;
    if (entityIndex > 0 && _seriesList != null) {
      var prevPie = _seriesList![0].entities[entityIndex - 1] as _Pie;
      startAngle = prevPie.endAngle;
    }
    return _Pie()
      ..index = entityIndex
      ..value = value
      ..formattedValue = value != null ? _entityValueFormatter!(value) : null
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

  @override
  void _updateSeries() {
    // Example data table:
    //   Browser  Share
    //   Chrome   .35
    //   IE       .30
    //   Firefox  .20
    //   Other    .15

    var sum = 0.0;
    var startAngle = _startAngle;
    var pieCount = _dataTable!.rows!.length;
    var entities = _seriesList![0].entities;

    // Sum the values of all visible pies.
    for (var i = 0; i < pieCount; i++) {
      if (_seriesStates[i].index >= _VisibilityState.showing.index) {
        sum += entities[i].value!;
      }
    }

    for (var i = 0; i < pieCount; i++) {
      _Pie pie = entities[i] as _Pie;
      var color = _getColor(i);
      pie.index = i;
      pie.name = _dataTable!.rows![i]![0];
      pie.color = color;
      pie.highlightColor = _getHighlightColor(color);
      pie.center = _center;
      pie.innerRadius = _innerRadius;
      pie.outerRadius = _outerRadius;

      if (_seriesStates[i].index >= _VisibilityState.showing.index) {
        pie.startAngle = startAngle;
        pie.endAngle = startAngle! + _direction * pie.value! * _2pi / sum;
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
    var pie = _seriesList![0].entities[_focusedEntityIndex!] as _Pie;
    _tooltip!.style
      ..borderColor = pie.color
      ..padding = '4px 12px';
    var label = _tooltipLabelFormatter(pie.name);
    var value = _tooltipValueFormatter!(pie.value);
    _tooltip!.innerHtml = '$label: <strong>$value</strong>';
  }

  PieChart(Element container) : super(container) {
    _defaultOptions = mergeMaps(globalOptions, _pieChartDefaultOptions);
  }
}
