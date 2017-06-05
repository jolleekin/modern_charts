part of modern_charts;

Set<Chart> _instances;

void _resizeCharts(_) {
  for (var chart in _instances) {
    chart.resize();
  }
}

/// The global drawing options.
final globalOptions = {
  // Map - An object that controls the animation.
  'animation': {
    // num - The animation duration in ms.
    'duration': 800,

    // String - Name of the easing function. See [animation.dart] for a full
    // list of supported values.
    'easing': 'easeOutCubic',

    // () -> void - The function that is called when the animation is complete.
    'onEnd': null
  },

  // The background color of the chart.
  'backgroundColor': 'white',

  // The color list used to render the series. If there are more series than
  // colors, the colors will be reused.
  'colors': [
    '#7cb5ec',
    '#434348',
    '#90ed7d',
    '#f7a35c',
    '#8085e9',
    '#f15c80',
    '#e4d354',
    '#8085e8',
    '#8d4653',
    '#91e8e1'
  ],

  // Map - An object that controls the legend.
  'legend': {
    // String - The position of the legend relative to the chart area.
    // Supported values: 'left', 'top', 'bottom', 'right', 'none'.
    'position': 'right',

    // Map - An object that controls the styling of the legend.
    'style': {
      'backgroundColor': 'white',
      'borderColor': '#212121',
      'borderWidth': 0,
      'color': '#212121',
      'fontFamily': _GLOBAL_FONT_FAMILY,
      'fontSize': 13,
      'fontStyle': 'normal'
    }
  },

  // Map - An object that controls the chart title.
  'title': {
    // String - The position of the title relative to the chart area.
    // Supported values: 'above', 'below', 'middle', 'none';
    'position': 'above',

    // Map - An object that controls the styling of the chart title.
    'style': {
      // String - The title's color.
      'color': '#212121',

      // String - The title's font family.
      'fontFamily': _GLOBAL_FONT_FAMILY,

      // num - The title's font size in pixels.
      'fontSize': 20,

      // String - The title's font style.
      'fontStyle': 'normal'
    },

    // The title text. A `null` value means the title is hidden.
    'text': null
  },

  // Map - An object that controls the tooltip.
  'tooltip': {
    // bool - Whether to show the tooltip.
    'enabled': true,

    // Map - An object that controls the styling of the tooltip.
    'style': {
      'backgroundColor': 'white',
      'borderColor': '#212121',
      'borderWidth': 2,
      'color': '#212121',
      'fontFamily': _GLOBAL_FONT_FAMILY,
      'fontSize': 13,
      'fontStyle': 'normal',
    },

    // (num value) -> String - A function that formats the values.
    'valueFormatter': null
  }
};

/// The 2*PI constant.
const double _2PI = 2 * PI;

/// The PI/2 constant.
const double _PI_2 = PI / 2;

const _GLOBAL_FONT_FAMILY = '"Segoe UI", "Open Sans", Verdana, Arial';

/// The padding of the chart itself.
const _GLOBAL_CHART_PADDING = 10;

/// The margin between the legend and the chart-axes box in pixels.
const _GLOBAL_LEGEND_MARGIN = 10;

const _GLOBAL_CHART_TITLE_MARGIN = 10;

/// The padding around the chart title and axis titles.
const _GLOBAL_TITLE_PADDING = 5;

/// The top-and/or-bottom margin of x-axis labels and the right-and/or-left
/// margin of y-axis labels.
///
/// x-axis labels always have top margin. If the x-axis title is N/A, x-axis
/// labels also have bottom margin.
///
/// y-axis labels always have right margin. If the y-axis title is N/A, y-axis
/// labels also have left margin.
const _AXIS_LABEL_MARGIN = 10;

typedef String ValueFormatter(num value);

/// A chart entity such as a point, a bar, a pie...
abstract class _Entity {
  num index;
  num value;
  String color;
  String highlightColor;
  num oldValue;
  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight);
  void save() {
    oldValue = value;
  }
}

class _Series {
  _Series(this.name, this.color, this.highlightColor, this.entities);
  String name;
  String color;
  String highlightColor;
  List<_Entity> entities;
}

/// Base class for all charts.
class Chart {
  /// The data table.
  /// Row 0 contains column names.
  /// Column 0 contains x-axis/pie labels.
  /// Column 1..n - 1 contain series data.
  DataTable _dataTable;

  StreamSubscription _dataCellChangeSub;
  StreamSubscription _dataColumnsChangeSub;
  StreamSubscription _dataRowsChangeSub;

  List<_Series> _seriesList;

  /// A list used to keep track of the visibility of the series.
  List<bool> _seriesVisible;

  /// The default drawing options initialized in the constructor.
  Map _defaultOptions;

  /// The drawing options.
  Map _options;

  /// The chart's width.
  int _height;

  /// The chart's height.
  int _width;

  /// Index of the highlighted point group/bar group/pie/...
  int _focusedEntityGroupIndex = -1;

  int _focusedSeriesIndex = -1;

  /// ID of the current animation frame.
  int _animationFrameId = 0;

  /// The starting time of an animation cyle.
  num _animationStartTime;

  /// The legend element.
  Element _legend;

  /// The tooltip element. To position the tooltip, change its transform CSS.
  Element _tooltip;

  StreamSubscription _mouseMoveSub;

  /// The function used to format series data to display in the tooltip.
  ValueFormatter _tooltipValueFormatter;

  /// Bounding box of the chart title.
  Rectangle<int> _titleBox;

  /// Bounding box of the series and axes.
  MutableRectangle<int> _seriesAndAxesBox;

  /// The main rendering context.
  CanvasRenderingContext2D _context;

  /// The rendering context for the axes.
  CanvasRenderingContext2D _axesContext;

  /// The rendering context for the series.
  CanvasRenderingContext2D _seriesContext;

  /// The color cache used by [_changeColorAlpha].
  static final _colorCache = <int, String>{};

  /// Creates a new color by combining the R, G, B components of [color] with
  /// [alpha].
  String _changeColorAlpha(String color, num alpha) {
    var key = 23;
    key = key * 31 + color.hashCode;
    key = key * 31 + alpha.hashCode;

    var result = _colorCache[key];
    if (result == null) {
      // Convert [color] to HEX/RGBA format using [_context].
      _context.fillStyle = color;
      color = _context.fillStyle;

      if (color[0] == '#') {
        result = hexToRgba(color, alpha);
      } else {
        var list = color.split(',');
        list[list.length - 1] = '$alpha)';
        result = list.join(',');
      }
      _colorCache[key] = result;
    }
    return result;
  }

  /// Counts the number of visible series up to (but not including) the [end]th
  /// series.
  int _countVisibleSeries([int end]) {
    end ??= _seriesVisible.length;
    return _seriesVisible.take(end).where((e) => e).length;
  }

  String _getColor(int index) {
    var colors = _options['colors'] as List<String>;
    return colors[index % colors.length];
  }

  String _getHighlightColor(String color) => _changeColorAlpha(color, .5);

  /// Returns a CSS font string given a map that contains at least three keys:
  /// `fontStyle`, `fontSize`, and `fontFamily`.
  String _getFont(Map style) =>
      '${style['fontStyle']} ${style['fontSize']}px ${style['fontFamily']}';

  /// Called when the animation ends.
  void _animationEnd() {
    for (var series in _seriesList) {
      for (var entity in series.entities) {
        entity.save();
      }
    }
  }

  /// Calculates various drawing sizes.
  ///
  /// Overriding methods must call this method first to have [_seriesAndAxesBox]
  /// calculated.
  ///
  /// To be overridden.
  void _calculateDrawingSizes() {
    var title = _options['title'];
    var titleX = 0;
    var titleY = 0;
    var titleW = 0;
    var titleH = 0;
    if (title['position'] != 'none' && title['text'] != null) {
      titleH = title['style']['fontSize'] + 2 * _GLOBAL_TITLE_PADDING;
    }
    _seriesAndAxesBox = new MutableRectangle(
        _GLOBAL_CHART_PADDING,
        _GLOBAL_CHART_PADDING,
        _width - 2 * _GLOBAL_CHART_PADDING,
        _height - 2 * _GLOBAL_CHART_PADDING);

    // Consider the title.

    if (titleH > 0) {
      switch (title['position']) {
        case 'above':
          titleY = _GLOBAL_CHART_PADDING;
          _seriesAndAxesBox.top += titleH + _GLOBAL_CHART_TITLE_MARGIN;
          _seriesAndAxesBox.height -= titleH + _GLOBAL_CHART_TITLE_MARGIN;
          break;
        case 'middle':
          titleY = (_height - titleH) ~/ 2;
          break;
        case 'below':
          titleY = _height - titleH - _GLOBAL_CHART_PADDING;
          _seriesAndAxesBox.height -= titleH + _GLOBAL_CHART_TITLE_MARGIN;
          break;
      }
      _context.font = _getFont(title['style']);
      titleW = _context.measureText(title['text']).width.round() +
          2 * _GLOBAL_TITLE_PADDING;
      titleX = (_width - titleW - 2 * _GLOBAL_TITLE_PADDING) ~/ 2;
    }
    _titleBox = new Rectangle(titleX, titleY, titleW, titleH);

    // Consider the legend.

    if (_legend != null) {
      var lwm = _legend.offsetWidth + _GLOBAL_LEGEND_MARGIN;
      var lhm = _legend.offsetHeight + _GLOBAL_LEGEND_MARGIN;
      switch (_options['legend']['position']) {
        case 'right':
          _seriesAndAxesBox.width -= lwm;
          break;
        case 'bottom':
          _seriesAndAxesBox.height -= lhm;
          break;
        case 'left':
          _seriesAndAxesBox.left += lwm;
          _seriesAndAxesBox.width -= lwm;
          break;
        case 'top':
          _seriesAndAxesBox.top += lhm;
          _seriesAndAxesBox.height -= lhm;
          break;
      }
    }
  }

  /// Event handler for [DataTable.onCellChanged].
  ///
  /// NOTE: This method only handles the case when [record.columnIndex] >= 1;
  void _dataCellChanged(DataCellChangeRecord record) {
    if (record.columnIndex >= 1) {
      _seriesList[record.columnIndex - 1].entities[record.rowIndex].value =
          record.newValue;
    }
  }

  /// Event handler for [DataTable.onRowsChanged].
  void _dataRowsChanged(DataCollectionChangeRecord record) {
    _calculateDrawingSizes();
    var entityCount = _dataTable.rows.length;
    var removedEnd = record.index + record.removedCount;
    var addedEnd = record.index + record.addedCount;
    for (var i = 0; i < _seriesList.length; i++) {
      var series = _seriesList[i];

      // Remove old entities.
      if (record.removedCount > 0) {
        series.entities.removeRange(record.index, removedEnd);
      }

      // Insert new entities.
      if (record.addedCount > 0) {
        var newEntities = _createEntities(
            i, record.index, addedEnd, series.color, series.highlightColor);
        series.entities.insertAll(record.index, newEntities);

        // Update entity indexes.
        for (var j = addedEnd; j < entityCount; j++) {
          series.entities[j].index = j;
        }
      }
    }
  }

  /// Event handler for [DataTable.onColumnsChanged].
  void _dataColumnsChanged(DataCollectionChangeRecord record) {
    _calculateDrawingSizes();
    var start = record.index - 1;
    _updateSeriesVisible(start, record.removedCount, record.addedCount);
    if (record.removedCount > 0) {
      _seriesList.removeRange(start, start + record.removedCount);
    }
    if (record.addedCount > 0) {
      _seriesList.insertAll(
          start, _createSeriesList(start, start + record.addedCount));
    }
    _updateLegendContent();
  }

  void _updateSeriesVisible(int index, int removedCount, int addedCount) {
    if (removedCount > 0) {
      _seriesVisible.removeRange(index, index + removedCount);
    }
    if (addedCount > 0) {
      _seriesVisible.insertAll(index, new List.filled(addedCount, true));
    }
  }

  /// Updates the series at index [index]. If [index] is `null`, updates all
  /// series.
  void _updateSeries([int index]) {}

  /// Called when [_dataTable] has been changed.
  void _dataTableChanged() {
    _calculateDrawingSizes();
    // Set this to `null` to indicate that the data table has been changed.
    _seriesList = null;
    _seriesList = _createSeriesList(0, _dataTable.columns.length - 1);
  }

  List<_Series> _createSeriesList(int start, int end) {
    var result = <_Series>[];
    var entityCount = _dataTable.rows.length;
    while (start < end) {
      var name = _dataTable.columns[start + 1].name;
      var color = _getColor(start);
      var highlightColor = _getHighlightColor(color);
//      var values = _dataTable.getColumnValues(start + 1);
      var entities =
          _createEntities(start, 0, entityCount, color, highlightColor);
      result.add(new _Series(name, color, highlightColor, entities));
      start++;
    }
    return result;
  }

  List<_Entity> _createEntities(int seriesIndex, int start, int end,
      String color, String highlightColor) {
    var result = [];
    while (start < end) {
      var value = _dataTable.rows[start][seriesIndex + 1];
      result
          .add(_createEntity(seriesIndex, start, value, color, highlightColor));
      start++;
    }
    return result;
  }

  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
          String highlightColor) =>
      null;

  void _updateEntity(int seriesIndex, int entityIndex, value) {}

  /// Draws the axes and the grid.
  ///
  /// To be overridden.
  void _drawAxesAndGrid() {}

  /// Draws the series given the current animation percent [percent].
  ///
  /// If this method returns `false`, the animation is continued until [percent]
  /// reaches 1.0.
  ///
  /// If this method returns `true`, the animation is stopped immediately.
  /// This is useful as there are cases where no animation is expected.
  /// For example, for line charts, there's no animation for toggling the
  /// visibility of a series. In that case, the overriding method will return
  /// `true` to stop the animation.
  ///
  /// To be overridden.
  bool _drawSeries(double percent) => true;

  /// Draws the current animation frame.
  ///
  /// If [time] is `null`, draws the last frame.
  void _drawFrame(double time) {
    var percent = 1.0;
    var duration = _options['animation']['duration'];
    _animationStartTime ??= time;
    if (duration > 0 && time != null)
      percent = (time - _animationStartTime) / duration;
    if (percent > 1.0) percent = 1.0;
    percent = getEaseValue(_options['animation']['easing'], percent);

    _context.fillStyle = _options['backgroundColor'];
    _context.fillRect(0, 0, _width, _height);
    _seriesContext.clearRect(0, 0, _width, _height);
    var done = _drawSeries(percent);
    _context.drawImageScaled(_axesContext.canvas, 0, 0, _width, _height);
    _context.drawImageScaled(_seriesContext.canvas, 0, 0, _width, _height);
    _drawTitle();

    if (percent < 1.0 && !done) {
      _animationFrameId = window.requestAnimationFrame(_drawFrame);
    } else {
      _animationStartTime = null;
      _animationEnd();
      var callback = _options['animation']['onEnd'];
      if (callback != null) callback();
    }
  }

  /// Draws the chart title using the main rendering context.
  void _drawTitle() {
    var title = _options['title'];
    if (title['text'] == null) return;
    _context
      ..font = _getFont(title['style'])
      ..fillStyle = title['style']['color']
      ..textAlign = 'center'
      ..fillText(title['text'], (_titleBox.left + _titleBox.right) ~/ 2,
          _titleBox.bottom - _GLOBAL_TITLE_PADDING);
  }

  void _initializeLegend() {
    var n = _getLegendLabels().length;
    _seriesVisible = new List<bool>.filled(n, true, growable: true);

    if (_legend != null) {
      _legend.remove();
      _legend = null;
    }

    if (_options['legend']['position'] == 'none') return;

    _legend = _createTooltipOrLegend(_options['legend']['style']);
    _legend.style.lineHeight = '180%';
    _updateLegendContent();
    container.append(_legend);
  }

  /// This must be called after [_calculateDrawingSizes] as we need to know
  /// where the title is in order to position the legend correctly.
  void _positionLegend() {
    if (_legend == null) return;

    var s = _legend.style;
    switch (_options['legend']['position']) {
      case 'right':
        s.right = '${_GLOBAL_CHART_PADDING}px';
        s.top = '50%';
        s.transform = 'translateY(-50%)';
        break;
      case 'bottom':
        var bottom = _GLOBAL_CHART_PADDING;
        if (_options['title']['position'] == 'below' && _titleBox.height > 0) {
          bottom += _titleBox.height;
        }
        s.bottom = '${bottom}px';
        s.left = '50%';
        s.transform = 'translateX(-50%)';
        break;
      case 'left':
        s.left = '${_GLOBAL_CHART_PADDING}px';
        s.top = '50%';
        s.transform = 'translateY(-50%)';
        break;
      case 'top':
        var top = _GLOBAL_CHART_PADDING;
        if (_options['title']['position'] == 'above' && _titleBox.height > 0) {
          top += _titleBox.height;
        }
        s.top = '${top}px';
        s.left = '50%';
        s.transform = 'translateX(-50%)';
        break;
    }
  }

  void _updateLegendContent() {
    var labels = _getLegendLabels();
    _legend.innerHtml = '';
    for (var i = 0; i < labels.length; i++) {
      var e = _createTooltipOrLegendItem(_getColor(i), labels[i]);
      e.style.cursor = 'pointer';
      e.style.userSelect = 'none';
      e.onClick.listen(_legendItemClick);
      e.onMouseOver.listen(_legendItemMouseOver);
      e.onMouseOut.listen(_legendItemMouseOut);
      if (!_seriesVisible[i]) e.style.opacity = '.5';
      // Display the items in one row if the legend's position is 'top' or
      // 'bottom'.
      var pos = _options['legend']['position'];
      if (pos == 'top' || pos == 'bottom') e.style.display = 'inline-block';
      _legend.append(e);
    }
  }

  List<String> _getLegendLabels() {
    return _dataTable.columns.skip(1).map((e) => e.name).toList();
  }

  void _legendItemClick(MouseEvent e) {
    if (animating) return;
    var item = e.target as Element;
    if (item is SpanElement) item = item.parent;
    var index = item.parent.children.indexOf(item);
    _seriesVisible[index] = !_seriesVisible[index];
    item.style.opacity = _seriesVisible[index] ? '' : '.5';
    _seriesVisibilityChanged(index);
    _startAnimation();
  }

  void _legendItemMouseOver(MouseEvent e) {
    if (animating) return;
    var item = e.target as Element;
    if (item is SpanElement) item = item.parent;
    _focusedSeriesIndex = item.parent.children.indexOf(item);
    _drawFrame(null);
  }

  void _legendItemMouseOut(MouseEvent e) {
    _focusedSeriesIndex = -1;
    _drawFrame(null);
  }

  /// Called when the visibility of a series is changed.
  ///
  /// [index] is the index of the affected series.
  ///
  /// To be overridden.
  void _seriesVisibilityChanged(int index) {}

  /// Returns the index of the point group/bar group/pie/... near the position
  /// specified by [x] and [y].
  ///
  /// To be overridden.
  int _getEntityGroupIndex(num x, num y) => -1;

  /// Handles `mousemove` or `touchstart` events to highlight appropriate
  /// points/bars/pies/... as well as update the tooltip.
  void _mouseMove(MouseEvent e) {
    if (animating || e.buttons != 0) return;

    var rect = _context.canvas.getBoundingClientRect();
    var x = e.client.x - rect.left;
    var y = e.client.y - rect.top;
    var index = _getEntityGroupIndex(x, y);

    if (index != _focusedEntityGroupIndex) {
      _focusedEntityGroupIndex = index;
      _drawFrame(null);
      if (index >= 0) {
        _updateTooltipContent();
        _tooltip.hidden = false;
        var p = _getTooltipPosition();
        _tooltip.style.transform = 'translate(${p.x}px, ${p.y}px)';
      } else {
        _tooltip.hidden = true;
      }
    }
  }

  void _initializeTooltip() {
    if (_tooltip != null) {
      _tooltip.remove();
      _tooltip = null;
    }

    var opt = _options['tooltip'];
    if (!opt['enabled']) return;

    _tooltipValueFormatter = opt['valueFormatter'];
    _tooltip = _createTooltipOrLegend(opt['style'])
      ..hidden = true
      ..style.left = '0'
      ..style.top = '0'
      ..style.boxShadow = '5px 5px 5px rgba(0,0,0,.25)'
      ..style.transition = 'transform .4s cubic-bezier(.4,1,.4,1)';
    container.append(_tooltip);

    _mouseMoveSub?.cancel();
    _mouseMoveSub = window.onMouseMove.listen(_mouseMove);
  }

  /// Returns the position of the tooltip based on [_focusedEntityGroupIndex].
  /// To be overridden.
  Point _getTooltipPosition() => null;

  void _updateTooltipContent() {
    var columnCount = _dataTable.columns.length;
    var row = _dataTable.rows[_focusedEntityGroupIndex];
    _tooltip.innerHtml = '';

    // Tooltip title.
    _tooltip.append(new DivElement()
      ..text = row[0]
      ..style.padding = '3px 10px'
      ..style.fontWeight = 'bold');

    // Tooltip items.
    for (var i = 1; i < columnCount; i++) {
      if (!_seriesVisible[i - 1]) continue;
      var series = _seriesList[i - 1];
      var value = row[i];
      if (value == null) continue;
      if (_tooltipValueFormatter != null) {
        value = _tooltipValueFormatter(value);
      }
      var e = _createTooltipOrLegendItem(
          series.color, '${series.name}: <strong>$value</strong>');
      _tooltip.append(e);
    }
  }

  /// Creates an absolute positioned div with styles specified by [style].
  Element _createTooltipOrLegend(Map style) {
    return new DivElement()
      ..style.backgroundColor = style['backgroundColor']
      ..style.borderColor = style['borderColor']
      ..style.borderStyle = 'solid'
      ..style.borderWidth = '${style['borderWidth']}px'
      ..style.color = style['color']
      ..style.fontFamily = style['fontFamily']
      ..style.fontSize = '${style['fontSize']}px'
      ..style.fontStyle = style['fontStyle']
      ..style.position = 'absolute';
  }

  Element _createTooltipOrLegendItem(String color, String text) {
    var e = new DivElement()
      ..innerHtml = '<span></span> $text'
      ..style.padding = '4px 12px';
    e.firstChild.style
      ..backgroundColor = color
      ..display = 'inline-block'
      ..width = '12px'
      ..height = '12px';
    return e;
  }

  void _startAnimation() {
    _animationFrameId = window.requestAnimationFrame(_drawFrame);
  }

  void _stopAnimation() {
    _animationStartTime = null;
    if (_animationFrameId != 0) {
      window.cancelAnimationFrame(_animationFrameId);
      _animationFrameId = 0;
    }
  }

  /// Creates a chart given a container.
  ///
  /// If the CSS position of [container] is 'static', it will be changed to
  /// 'relative'.
  Chart(this.container) {
    if (container.getComputedStyle().position == 'static') {
      container.style.position = 'relative';
    }
    _context = new CanvasElement().getContext('2d');
    _axesContext = new CanvasElement().getContext('2d');
    _seriesContext = new CanvasElement().getContext('2d');

    container.append(_context.canvas);

    if (_instances == null) {
      _instances = new Set<Chart>();
      window.onResize.listen(_resizeCharts);
    }
    _instances.add(this);
  }

  /// Whether animation is happening or not.
  bool get animating => _animationStartTime != null;

  /// The element that contains this chart.
  final Element container;

  /// The data table that stores chart data.
  DataTable get dataTable => _dataTable;

  /// Draws the chart given a data table [dataTable] and an optional set of
  /// options [options].
  void draw(DataTable dataTable, [Map options]) {
    if (_dataCellChangeSub != null) {
      _dataCellChangeSub.cancel();
      _dataColumnsChangeSub.cancel();
      _dataRowsChangeSub.cancel();
    }
    _dataTable = dataTable;
    _dataCellChangeSub = dataTable.onCellChange.listen(_dataCellChanged);
    _dataColumnsChangeSub =
        dataTable.onColumnsChange.listen(_dataColumnsChanged);
    _dataRowsChangeSub = dataTable.onRowsChange.listen(_dataRowsChanged);
    _options = mergeMap(options, _defaultOptions);
    _initializeLegend();
    _initializeTooltip();
    resize(true);
  }

  /// Resizes the chart to fit the new size of the container.
  ///
  /// This method is automatically called when the browser window is resized.
  void resize([bool forceRedraw = false]) {
    var w = container.clientWidth;
    var h = container.clientHeight;

    if (w != _width || h != _height) {
      _width = w;
      _height = h;
      forceRedraw = true;

      var dpr = window.devicePixelRatio;
      var scaledW = (w * dpr).round();
      var scaledH = (h * dpr).round();

      void setCanvasSize(CanvasRenderingContext2D ctx) {
        // Scale the drawing canvas by [dpr] to ensure sharp rendering on
        // high pixel density displays.
        ctx.canvas
          ..style.width = '${w}px'
          ..style.height = '${h}px'
          ..width = scaledW
          ..height = scaledH;
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      }

      setCanvasSize(_context);
      setCanvasSize(_axesContext);
      setCanvasSize(_seriesContext);
    }

    if (forceRedraw) {
      _stopAnimation();
      _dataTableChanged();
      _positionLegend();
      update();
    }
  }

  /// Updates the chart.
  ///
  ///  This method should be called after [dataTable] has been modified.
  // TODO: handle updates while animation is happening.
  void update() {
    // This call is redundant for row and column changes but necessary for
    // cell changes.
    _calculateDrawingSizes();
    _updateSeries();
    _axesContext.clearRect(0, 0, _width, _height);
    _drawAxesAndGrid();
    _startAnimation();
  }
}

/// Base class for charts having two axes.
class _TwoAxisChart extends Chart {
  int _xAxisTop;
  int _yAxisLeft;
  int _xAxisLength;
  int _yAxisLength;
  int _xLabelMaxWidth;
  int _yLabelMaxWidth;
  int _xLabelRotation; // 0..90
  double _xLabelHop; // Distance between two consecutive x-axis labels.
  double _yLabelHop; // Distance between two consecutive x-axis labels.
  Rectangle _xTitleBox;
  Rectangle _yTitleBox;
  Point _xTitleCenter;
  Point _yTitleCenter;
  List<String> _xLabels;
  List<String> _yLabels;
  num _yInterval;
  num _yMaxValue;
  num _yMinValue;
  num _yRange;

  /// The horizontal offset of the tooltip with respect to the vertical line
  /// passing through an x-axis label.
  num _tooltipOffset;

  ValueFormatter _yLabelFormatter;
  List<int> _averageYValues;

  /// Returns the x coordinate of the x-axis label at [index].
  num _xLabelX(int index) => _yAxisLeft + _xLabelHop * (index + .5);

  /// Returns the y-coordinate corresponding to the data point [value] and
  /// the animation percent [percent].
  num _valueToY(num value) => value != null
      ? _xAxisTop - (value - _yMinValue) / _yRange * _yAxisLength
      : _xAxisTop;

  /// Calculates average y values for the visible series to help position the
  /// tooltip.
  ///
  /// If [index] is given, calculates the average y value for the entity group
  /// at [index] only.
  ///
  /// To be overridden.
  void _calculateAverageYValues([int index]) {}

  // TODO: Separate y-axis stuff into a separate method.
  @override
  void _calculateDrawingSizes() {
    super._calculateDrawingSizes();

    // y-axis min-max.

    _yMaxValue = _options['yAxis']['maxValue'];
    _yMinValue = _options['yAxis']['minValue'];
    _yInterval = _options['yAxis']['interval'];
    var minInterval = _options['yAxis']['minInterval'];
    if (_yMaxValue == null || _yMinValue == null || _yInterval == null) {
      _yMaxValue = findMaxValue(_dataTable);
      _yMinValue = findMinValue(_dataTable);
      if (_yMinValue == double.INFINITY) {
        _yMaxValue = 0.0;
        _yMinValue = 0.0;
      }
      if (_yMinValue == _yMaxValue) {
        if (_yMinValue == 0.0) {
          _yMaxValue = 1.0;
          _yInterval = 1.0;
        } else if (_yMinValue == 1.0) {
          _yMinValue = 0.0;
          _yInterval = 1.0;
        } else {
          _yInterval = _yMinValue * .25;
          _yMinValue -= _yInterval;
          _yMaxValue += _yInterval;
        }
        if (minInterval != null) {
          _yInterval = max(_yInterval, minInterval);
        }
      } else {
        _yInterval = calculateInterval(_yMaxValue - _yMinValue, 5, minInterval);
      }
      _yMinValue = (_yMinValue / _yInterval).floorToDouble() * _yInterval;
      _yMaxValue = (_yMaxValue / _yInterval).ceilToDouble() * _yInterval;
    }
    _yRange = _yMaxValue - _yMinValue;

    // y-axis labels.

    _yLabels = <String>[];
    _yLabelFormatter = _options['yAxis']['labels']['formatter'];
    if (_yLabelFormatter == null) {
      var maxDecimalPlaces =
          max(getDecimalPlaces(_yInterval), getDecimalPlaces(_yMinValue));
      var numberFormat = new NumberFormat.decimalPattern()
        ..maximumFractionDigits = maxDecimalPlaces
        ..minimumFractionDigits = maxDecimalPlaces;
      _yLabelFormatter = (value) => numberFormat.format(value);
    }
    var value = _yMinValue;
    while (value <= _yMaxValue) {
      _yLabels.add(_yLabelFormatter(value));
      value += _yInterval;
    }
    _yLabelMaxWidth = calculateMaxTextWidth(
            _context, _getFont(_options['yAxis']['labels']['style']), _yLabels)
        .round();

    // Tooltip.

    _tooltipValueFormatter ??= _yLabelFormatter;

    // x-axis title.

    var xTitleLeft = 0;
    var xTitleTop = 0;
    var xTitleWidth = 0;
    var xTitleHeight = 0;
    var xTitle = _options['xAxis']['title'];
    if (xTitle['text'] != null) {
      _context.font = _getFont(xTitle['style']);
      xTitleWidth = _context.measureText(xTitle['text']).width.round() +
          2 * _GLOBAL_TITLE_PADDING;
      xTitleHeight = xTitle['style']['fontSize'] + 2 * _GLOBAL_TITLE_PADDING;
      xTitleTop = _seriesAndAxesBox.bottom - xTitleHeight;
    }

    // y-axis title.

    var yTitleLeft = 0;
    var yTitleTop = 0;
    var yTitleWidth = 0;
    var yTitleHeight = 0;
    var yTitle = _options['yAxis']['title'];
    if (yTitle['text'] != null) {
      _context.font = _getFont(yTitle['style']);
      yTitleHeight = _context.measureText(yTitle['text']).width.round() +
          2 * _GLOBAL_TITLE_PADDING;
      yTitleWidth = yTitle['style']['fontSize'] + 2 * _GLOBAL_TITLE_PADDING;
      yTitleLeft = _seriesAndAxesBox.left;
    }

    // Axes' size and position.

    _yAxisLeft = _seriesAndAxesBox.left + _yLabelMaxWidth + _AXIS_LABEL_MARGIN;
    if (yTitleWidth > 0) {
      _yAxisLeft += yTitleWidth + _GLOBAL_CHART_TITLE_MARGIN;
    } else {
      _yAxisLeft += _AXIS_LABEL_MARGIN;
    }

    _xAxisLength = _seriesAndAxesBox.right - _yAxisLeft;

    _xAxisTop = _seriesAndAxesBox.bottom;
    if (xTitleHeight > 0) {
      _xAxisTop -= xTitleHeight + _GLOBAL_CHART_TITLE_MARGIN;
    } else {
      _xAxisTop -= _AXIS_LABEL_MARGIN;
    }

    // x-axis labels and x-axis's position.

    _xLabels = <String>[];
    for (var i = 0; i < _dataTable.rows.length; i++) {
      _xLabels.add(_dataTable.rows[i][0].toString());
    }
    _xLabelMaxWidth = calculateMaxTextWidth(
            _context, _getFont(_options['xAxis']['labels']['style']), _xLabels)
        .round();
    _xLabelHop = _xAxisLength / _xLabels.length;
    _xLabelRotation = 0;
    var availableWidth = _xLabelHop - 5;
    if (_xLabelMaxWidth <= availableWidth) {
      _xAxisTop -= _options['xAxis']['labels']['style']['fontSize'];
    } else {
      _xLabelRotation = 45;
      if (_xLabelMaxWidth * cos(_xLabelRotation) <= availableWidth) {
        _xAxisTop -= (_xLabelMaxWidth * sin(_xLabelRotation)).round();
      } else {
        _xLabelRotation = 90;
        _xAxisTop -= _xLabelMaxWidth;
      }
    }
    _xAxisTop -= _AXIS_LABEL_MARGIN;

    // Wrap up.

    _yAxisLength = _xAxisTop -
        _seriesAndAxesBox.top -
        _options['yAxis']['labels']['style']['fontSize'] ~/ 2;
    _yLabelHop = _yAxisLength / (_yLabels.length - 1);

    xTitleLeft = _yAxisLeft + (_xAxisLength - xTitleWidth) ~/ 2;
    yTitleTop = _seriesAndAxesBox.top + (_yAxisLength - yTitleHeight) ~/ 2;

    if (xTitleHeight > 0) {
      _xTitleBox =
          new Rectangle(xTitleLeft, xTitleTop, xTitleWidth, xTitleHeight);
      _xTitleCenter = new Point(
          xTitleLeft + xTitleWidth ~/ 2, xTitleTop + xTitleHeight ~/ 2);
    } else {
      _xTitleBox = null;
      _xTitleCenter = null;
    }

    if (yTitleHeight > 0) {
      _yTitleBox =
          new Rectangle(yTitleLeft, yTitleTop, yTitleWidth, yTitleHeight);
      _yTitleCenter = new Point(
          yTitleLeft + yTitleWidth ~/ 2, yTitleTop + yTitleHeight ~/ 2);
    } else {
      _yTitleBox = null;
      _yTitleCenter = null;
    }
  }

  @override
  void _dataCellChanged(DataCellChangeRecord record) {
    if (record.columnIndex == 0) {
      _xLabels[record.rowIndex] = record.newValue;
    } else {
      super._dataCellChanged(record);
    }
  }

  @override
  void _drawAxesAndGrid() {
    // x-axis title.

    if (_xTitleCenter != null) {
      _axesContext
        ..fillStyle = _options['xAxis']['title']['style']['color']
        ..font = _getFont(_options['xAxis']['title']['style'])
        ..textAlign = 'center'
        ..textBaseline = 'middle'
        ..fillText(_options['xAxis']['title']['text'], _xTitleCenter.x,
            _xTitleCenter.y);
    }

    // y-axis title.

    if (_yTitleCenter != null) {
      _axesContext
        ..save()
        ..fillStyle = _options['yAxis']['title']['style']['color']
        ..font = _getFont(_options['yAxis']['title']['style'])
        ..translate(_yTitleCenter.x, _yTitleCenter.y)
        ..rotate(-_PI_2)
        ..textAlign = 'center'
        ..textBaseline = 'middle'
        ..fillText(_options['yAxis']['title']['text'], 0, 0)
        ..restore();
    }

    // x-axis labels.

    _axesContext
      ..fillStyle = _options['xAxis']['labels']['style']['color']
      ..font = _getFont(_options['xAxis']['labels']['style'])
      ..textBaseline = 'alphabetic';
    var x = _xLabelX(0);
    var y = _xAxisTop +
        _AXIS_LABEL_MARGIN +
        _options['xAxis']['labels']['style']['fontSize'];
    if (_xLabelRotation == 0) {
      _axesContext.textAlign = 'center';
      for (var label in _xLabels) {
        _axesContext.fillText(label, x, y);
        x += _xLabelHop;
      }
    } else {
      _axesContext.textAlign = 'right';
      var angle = radian(-_xLabelRotation);
      for (var label in _xLabels) {
        _axesContext
          ..save()
          ..translate(x, y)
          ..rotate(angle)
          ..fillText(label, 0, 0)
          ..restore();
        x += _xLabelHop;
      }
    }

    // y-axis labels.

    _axesContext
      ..fillStyle = _options['yAxis']['labels']['style']['color']
      ..font = _getFont(_options['yAxis']['labels']['style'])
      ..textAlign = 'right'
      ..textBaseline = 'middle';
    x = _yAxisLeft - _AXIS_LABEL_MARGIN;
    y = _xAxisTop - 1; // Shift the baseline up by 1 pixel.
    for (var label in _yLabels) {
      _axesContext.fillText(label, x, y);
      y -= _yLabelHop;
    }

    // x grid lines - draw bottom up.

    if (_options['xAxis']['gridLineWidth'] > 0) {
      _axesContext
        ..lineWidth = _options['xAxis']['gridLineWidth']
        ..strokeStyle = _options['xAxis']['gridLineColor']
        ..beginPath();
      y = _xAxisTop - _yLabelHop;
      for (var i = _yLabels.length - 1; i >= 1; i--) {
        _axesContext.moveTo(_yAxisLeft, y);
        _axesContext.lineTo(_yAxisLeft + _xAxisLength, y);
        y -= _yLabelHop;
      }
      _axesContext.stroke();
    }

    // y grid lines or x-axis ticks - draw from left to right.

    var lineWidth = _options['yAxis']['gridLineWidth'];
    x = _yAxisLeft;
    if (lineWidth > 0) {
      y = _xAxisTop - _yAxisLength;
    } else {
      lineWidth = 1;
      y = _xAxisTop + _AXIS_LABEL_MARGIN;
    }
    _axesContext
      ..lineWidth = lineWidth
      ..strokeStyle = _options['yAxis']['gridLineColor']
      ..beginPath();
    for (var i = _xLabels.length; i >= 0; i--) {
      _axesContext.moveTo(x, y);
      _axesContext.lineTo(x, _xAxisTop);
      x += _xLabelHop;
    }
    _axesContext.stroke();

    // x-axis itself.

    if (_options['xAxis']['lineWidth'] > 0) {
      _axesContext
        ..lineWidth = _options['xAxis']['lineWidth']
        ..strokeStyle = _options['xAxis']['lineColor']
        ..beginPath()
        ..moveTo(_yAxisLeft, _xAxisTop)
        ..lineTo(_yAxisLeft + _xAxisLength, _xAxisTop)
        ..stroke();
    }

    // y-axis itself.

    if (_options['yAxis']['lineWidth'] > 0) {
      _axesContext
        ..lineWidth = _options['yAxis']['lineWidth']
        ..strokeStyle = _options['yAxis']['lineColor']
        ..beginPath()
        ..moveTo(_yAxisLeft, _xAxisTop - _yAxisLength)
        ..lineTo(_yAxisLeft, _xAxisTop)
        ..stroke();
    }
  }

  @override
  int _getEntityGroupIndex(num x, num y) {
    var dx = x - _yAxisLeft;
    // If (x, y) is inside the rectangle defined by the two axes.
    if (y > _xAxisTop - _yAxisLength &&
        y < _xAxisTop &&
        dx > 0 &&
        dx < _xAxisLength) {
      var index = dx ~/ _xLabelHop;
      // If there is at least one visible point in the current point group...
      if (_averageYValues[index] != null) return index;
    }
    return -1;
  }

  @override
  Point _getTooltipPosition() {
    var x = _xLabelX(_focusedEntityGroupIndex) + _tooltipOffset;
    var y =
        _averageYValues[_focusedEntityGroupIndex] - _tooltip.offsetHeight ~/ 2;
    if (x + _tooltip.offsetWidth > _width) {
      x -= _tooltip.offsetWidth + 2 * _tooltipOffset;
    }
    return new Point(x, y);
  }

  _TwoAxisChart(Element container) : super(container);

  @override
  void update() {
    super.update();
    _calculateAverageYValues();
  }
}
