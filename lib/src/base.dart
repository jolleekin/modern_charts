part of modern_charts;

/// The global drawing options.
final globalOptions = {
  // Map - An object that controls the animation.
  'animation': {
    // num - The animation duration in ms.
    'duration': 800,

    // String|EasingFunction - Name of a predefined easing function or an
    // easing function itself.
    //
    // See [animation.dart] for the full list of predefined functions.
    'easing': easeOutQuint,

    // () -> void - The function that is called when the animation is complete.
    'onEnd': null
  },

  // String - The background color of the chart.
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
    // (String label) -> String - A function that format the labels.
    'labelFormatter': null,

    // String - The position of the legend relative to the chart area.
    // Supported values: 'left', 'top', 'bottom', 'right', 'none'.
    'position': 'right',

    // Map - An object that controls the styling of the legend.
    'style': {
      'backgroundColor': 'transparent',
      'borderColor': '#212121',
      'borderWidth': 0,
      'color': '#212121',
      'fontFamily': _fontFamily,
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
      'fontFamily': _fontFamily,

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

    // (String label) -> String - A function that format the labels.
    'labelFormatter': null,

    // Map - An object that controls the styling of the tooltip.
    'style': {
      'backgroundColor': 'white',
      'borderColor': '#212121',
      'borderWidth': 2,
      'color': '#212121',
      'fontFamily': _fontFamily,
      'fontSize': 13,
      'fontStyle': 'normal',
    },

    // (num value) -> String - A function that formats the values.
    'valueFormatter': null
  }
};

/// The 2*pi constant.
const _2pi = 2 * pi;

/// The pi/2 constant.
const _pi_2 = pi / 2;

const _fontFamily = '"Segoe UI", "Open Sans", Verdana, Arial';

/// The padding of the chart itself.
const _chartPadding = 12;

/// The margin between the legend and the chart-axes box in pixels.
const _legendMargin = 12;

const _chartTitleMargin = 12;

/// The padding around the chart title and axis titles.
const _titlePadding = 6;

/// The top-and/or-bottom margin of x-axis labels and the right-and/or-left
/// margin of y-axis labels.
///
/// x-axis labels always have top margin. If the x-axis title is N/A, x-axis
/// labels also have bottom margin.
///
/// y-axis labels always have right margin. If the y-axis title is N/A, y-axis
/// labels also have left margin.
const _axisLabelMargin = 12;

typedef String LabelFormatter(String label);

typedef String ValueFormatter(value);

String _defaultLabelFormatter(String label) => label;

String _defaultValueFormatter(value) => '$value';

enum _VisibilityState { hidden, hiding, showing, shown }

/// A chart entity such as a point, a bar, a pie...
abstract class _Entity {
  Chart chart;
  String color;
  String highlightColor;
  String formattedValue;
  num index;
  num oldValue;
  num value;

  void draw(CanvasRenderingContext2D ctx, double percent, bool highlight);

  void free() {
    chart = null;
  }

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

  void freeEntities(int start, [int end]) {
    end ??= entities.length;
    while (start < end) {
      entities[start].free();
      start++;
    }
  }
}

/// Base class for all charts.
class Chart {
  /// ID of the current animation frame.
  int _animationFrameId = 0;

  /// The starting time of an animation cycle.
  num _animationStartTime;

  final _dataTableSubscriptionTracker = StreamSubscriptionTracker();

  /// The data table.
  /// Row 0 contains column names.
  /// Column 0 contains x-axis/pie labels.
  /// Column 1..n - 1 contain series data.
  DataTable _dataTable;

  EasingFunction _easingFunction;

  /// The default drawing options initialized in the constructor.
  Map _defaultOptions;

  /// The drawing options.
  Map _options;

  /// The chart's width.
  int _height;

  /// The chart's height.
  int _width;

  /// Index of the highlighted point group/bar group/pie/...
  int _focusedEntityIndex = -1;

  int _focusedSeriesIndex = -1;

  ValueFormatter _entityValueFormatter;

  /// The legend element.
  Element _legend;

  /// The subscription tracker for legend items' events.
  final _legendItemSubscriptionTracker = StreamSubscriptionTracker();

  StreamSubscription _mouseMoveSub;

  /// The tooltip element. To position the tooltip, change its transform CSS.
  Element _tooltip;

  /// The function used to format series names to display in the tooltip.
  LabelFormatter _tooltipLabelFormatter;

  /// The function used to format series data to display in the tooltip.
  ValueFormatter _tooltipValueFormatter;

  /// Bounding box of the series and axes.
  MutableRectangle<int> _seriesAndAxesBox;

  /// Bounding box of the chart title.
  Rectangle<int> _titleBox;

  /// The main rendering context.
  CanvasRenderingContext2D _context;

  /// The rendering context for the axes.
  CanvasRenderingContext2D _axesContext;

  /// The rendering context for the series.
  CanvasRenderingContext2D _seriesContext;

  List<_Series> _seriesList;

  /// A list used to keep track of the visibility of the series.
  List<_VisibilityState> _seriesStates;

  /// The color cache used by [_changeColorAlpha].
  static final _colorCache = <String, String>{};

  /// Creates a new color by combining the R, G, B components of [color] with
  /// [alpha].
  String _changeColorAlpha(String color, num alpha) {
    var key = '$color$alpha';
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
    end ??= _seriesStates.length;
    return _seriesStates
        .take(end)
        .where((e) => e.index >= _VisibilityState.showing.index)
        .length;
  }

  String _getColor(int index) {
    var colors = _options['colors'] as List;
    return colors[index % colors.length];
  }

  String _getHighlightColor(String color) => _changeColorAlpha(color, .5);

  /// Returns a CSS font string given a map that contains at least three keys:
  /// `fontStyle`, `fontSize`, and `fontFamily`.
  String _getFont(Map style) =>
      '${style['fontStyle']} ${style['fontSize']}px ${style['fontFamily']}';

  /// Called when the animation ends.
  void _animationEnd() {
    _animationStartTime = null;

    for (var series in _seriesList) {
      for (var entity in series.entities) {
        entity.save();
      }
    }

    var callback = _options['animation']['onEnd'];
    if (callback != null) callback();
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
      titleH = title['style']['fontSize'] + 2 * _titlePadding;
    }
    _seriesAndAxesBox = MutableRectangle(_chartPadding, _chartPadding,
        _width - 2 * _chartPadding, _height - 2 * _chartPadding);

    // Consider the title.

    if (titleH > 0) {
      switch (title['position']) {
        case 'above':
          titleY = _chartPadding;
          _seriesAndAxesBox.top += titleH + _chartTitleMargin;
          _seriesAndAxesBox.height -= titleH + _chartTitleMargin;
          break;
        case 'middle':
          titleY = (_height - titleH) ~/ 2;
          break;
        case 'below':
          titleY = _height - titleH - _chartPadding;
          _seriesAndAxesBox.height -= titleH + _chartTitleMargin;
          break;
      }
      _context.font = _getFont(title['style']);
      titleW =
          _context.measureText(title['text']).width.round() + 2 * _titlePadding;
      titleX = (_width - titleW - 2 * _titlePadding) ~/ 2;
    }
    _titleBox = Rectangle(titleX, titleY, titleW, titleH);

    // Consider the legend.

    if (_legend != null) {
      var lwm = _legend.offsetWidth + _legendMargin;
      var lhm = _legend.offsetHeight + _legendMargin;
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

  List<_Entity> _createEntities(int seriesIndex, int start, int end,
      String color, String highlightColor) {
    var result = <_Entity>[];
    while (start < end) {
      var value = _dataTable.rows[start][seriesIndex + 1];
      var e = _createEntity(seriesIndex, start, value, color, highlightColor);
      e.chart = this;
      result.add(e);
      start++;
    }
    return result;
  }

  _Entity _createEntity(int seriesIndex, int entityIndex, value, String color,
          String highlightColor) =>
      null;

  List<_Series> _createSeriesList(int start, int end) {
    var result = <_Series>[];
    var entityCount = _dataTable.rows.length;
    while (start < end) {
      var name = _dataTable.columns[start + 1].name;
      var color = _getColor(start);
      var highlightColor = _getHighlightColor(color);
      var entities =
          _createEntities(start, 0, entityCount, color, highlightColor);
      result.add(_Series(name, color, highlightColor, entities));
      start++;
    }
    return result;
  }

  /// Event handler for [DataTable.onCellChanged].
  ///
  /// NOTE: This method only handles the case when [record.columnIndex] >= 1;
  void _dataCellChanged(DataCellChangeRecord record) {
    if (record.columnIndex >= 1) {
      var f = _entityValueFormatter != null && record.newValue != null
          ? _entityValueFormatter(record.newValue)
          : null;
      _seriesList[record.columnIndex - 1].entities[record.rowIndex]
        ..value = record.newValue
        ..formattedValue = f;
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
        series.freeEntities(record.index, removedEnd);
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
      var end = start + record.removedCount;
      for (var i = start; i < end; i++) {
        _seriesList[i].freeEntities(0);
      }
      _seriesList.removeRange(start, end);
    }
    if (record.addedCount > 0) {
      var list = _createSeriesList(start, start + record.addedCount);
      _seriesList.insertAll(start, list);
    }
    _updateLegendContent();
  }

  /// Called when [_dataTable] has been changed.
  void _dataTableChanged() {
    _calculateDrawingSizes();
    _seriesList = _createSeriesList(0, _dataTable.columns.length - 1);
  }

  /// Updates the series at index [index]. If [index] is `null`, updates all
  /// series.
  ///
  /// To be overridden.
  void _updateSeries([int index]) {}

  void _updateSeriesVisible(int index, int removedCount, int addedCount) {
    if (removedCount > 0) {
      _seriesStates.removeRange(index, index + removedCount);
    }
    if (addedCount > 0) {
      var list = List.filled(addedCount, _VisibilityState.showing);
      _seriesStates.insertAll(index, list);
    }
  }

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
  /// In those cases, the overriding method will return `true` to stop the
  /// animation.
  ///
  /// To be overridden.
  bool _drawSeries(double percent) => true;

  /// Draws the current animation frame.
  ///
  /// If [time] is `null`, draws the last frame (i.e. no animation).
  void _drawFrame(num time) {
    var percent = 1.0;
    var duration = _options['animation']['duration'];
    _animationStartTime ??= time;
    if (duration > 0 && time != null) {
      percent = (time - _animationStartTime) / duration;
    }

    if (percent >= 1.0) {
      percent = 1.0;

      // Update the visibility states of all series before the last frame.
      for (var i = _seriesStates.length - 1; i >= 0; i--) {
        if (_seriesStates[i] == _VisibilityState.showing) {
          _seriesStates[i] = _VisibilityState.shown;
        } else if (_seriesStates[i] == _VisibilityState.hiding) {
          _seriesStates[i] = _VisibilityState.hidden;
        }
      }
    }

    _context.fillStyle = _options['backgroundColor'];
    _context.fillRect(0, 0, _width, _height);
    _seriesContext.clearRect(0, 0, _width, _height);
    _drawSeries(_easingFunction(percent));
    _context.drawImageScaled(_axesContext.canvas, 0, 0, _width, _height);
    _context.drawImageScaled(_seriesContext.canvas, 0, 0, _width, _height);
    _drawTitle();

    if (percent < 1.0) {
      _animationFrameId = window.requestAnimationFrame(_drawFrame);
    } else if (time != null) {
      _animationEnd();
    }
  }

  /// Draws the chart title using the main rendering context.
  void _drawTitle() {
    var title = _options['title'];
    if (title['text'] == null) return;

    var x = (_titleBox.left + _titleBox.right) ~/ 2;
    var y = _titleBox.bottom - _titlePadding;
    _context
      ..font = _getFont(title['style'])
      ..fillStyle = title['style']['color']
      ..textAlign = 'center'
      ..fillText(title['text'], x, y);
  }

  void _initializeLegend() {
    var n = _getLegendLabels().length;
    _seriesStates = List<_VisibilityState>.filled(n, _VisibilityState.showing,
        growable: true);

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
        s.right = '${_chartPadding}px';
        s.top = '50%';
        s.transform = 'translateY(-50%)';
        break;
      case 'bottom':
        var bottom = _chartPadding;
        if (_options['title']['position'] == 'below' && _titleBox.height > 0) {
          bottom += _titleBox.height;
        }
        s.bottom = '${bottom}px';
        s.left = '50%';
        s.transform = 'translateX(-50%)';
        break;
      case 'left':
        s.left = '${_chartPadding}px';
        s.top = '50%';
        s.transform = 'translateY(-50%)';
        break;
      case 'top':
        var top = _chartPadding;
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
    var formatter =
        _options['legend']['labelFormatter'] ?? _defaultLabelFormatter;
    _legendItemSubscriptionTracker.clear();
    _legend.innerHtml = '';
    for (var i = 0; i < labels.length; i++) {
      var label = labels[i];
      var formattedLabel = formatter(label);
      var e = _createTooltipOrLegendItem(_getColor(i), formattedLabel);
      if (label != formattedLabel) {
        e.title = label;
      }
      e.style.cursor = 'pointer';
      e.style.userSelect = 'none';
      _legendItemSubscriptionTracker
        ..add(e.onClick.listen(_legendItemClick))
        ..add(e.onMouseOver.listen(_legendItemMouseOver))
        ..add(e.onMouseOut.listen(_legendItemMouseOut));

      var state = _seriesStates[i];
      if (state == _VisibilityState.hidden ||
          state == _VisibilityState.hiding) {
        e.style.opacity = '.4';
      }

      // Display the items in one row if the legend's position is 'top' or
      // 'bottom'.
      var pos = _options['legend']['position'];
      if (pos == 'top' || pos == 'bottom') {
        e.style.display = 'inline-block';
      }
      _legend.append(e);
    }
  }

  List<String> _getLegendLabels() =>
      _dataTable.columns.skip(1).map((e) => e.name).toList();

  void _legendItemClick(MouseEvent e) {
    if (!isInteractive) return;

    var item = e.currentTarget as Element;
    var index = item.parent.children.indexOf(item);

    if (_seriesStates[index] == _VisibilityState.shown) {
      _seriesStates[index] = _VisibilityState.hiding;
      item.style.opacity = '.4';
    } else {
      _seriesStates[index] = _VisibilityState.showing;
      item.style.opacity = '';
    }

    _seriesVisibilityChanged(index);
    _startAnimation();
  }

  void _legendItemMouseOver(MouseEvent e) {
    if (!isInteractive) return;
    var item = e.currentTarget as Element;
    _focusedSeriesIndex = item.parent.children.indexOf(item);
    _drawFrame(null);
  }

  void _legendItemMouseOut(MouseEvent e) {
    if (!isInteractive) return;
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
    if (!isInteractive || e.buttons != 0) return;

    var rect = _context.canvas.getBoundingClientRect();
    var x = e.client.x - rect.left;
    var y = e.client.y - rect.top;
    var index = _getEntityGroupIndex(x, y);

    if (index != _focusedEntityIndex) {
      _focusedEntityIndex = index;
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

    _tooltipLabelFormatter = opt['labelFormatter'] ?? _defaultLabelFormatter;
    _tooltipValueFormatter = opt['valueFormatter'] ?? _defaultValueFormatter;
    _tooltip = _createTooltipOrLegend(opt['style'])
      ..hidden = true
      ..style.left = '0'
      ..style.top = '0'
      ..style.boxShadow = '4px 4px 4px rgba(0,0,0,.25)'
      ..style.transition = 'transform .4s cubic-bezier(.4,1,.4,1)';
    container.append(_tooltip);

    _mouseMoveSub?.cancel();
    _mouseMoveSub = container.onMouseMove.listen(_mouseMove);
  }

  /// Returns the position of the tooltip based on [_focusedEntityIndex].
  /// To be overridden.
  Point _getTooltipPosition() => null;

  void _updateTooltipContent() {
    var columnCount = _dataTable.columns.length;
    var row = _dataTable.rows[_focusedEntityIndex];
    _tooltip.innerHtml = '';

    // Tooltip title.
    _tooltip.append(DivElement()
      ..text = row[0]
      ..style.padding = '4px 12px'
      ..style.fontWeight = 'bold');

    // Tooltip items.
    for (var i = 1; i < columnCount; i++) {
      var state = _seriesStates[i - 1];
      if (state == _VisibilityState.hidden) continue;
      if (state == _VisibilityState.hiding) continue;

      var series = _seriesList[i - 1];
      var value = row[i];
      if (value == null) continue;

      value = _tooltipValueFormatter(value);
      var label = _tooltipLabelFormatter(series.name);

      var e = _createTooltipOrLegendItem(
          series.color, '$label: <strong>$value</strong>');
      _tooltip.append(e);
    }
  }

  /// Creates an absolute positioned div with styles specified by [style].
  Element _createTooltipOrLegend(Map style) {
    return DivElement()
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
    var e = DivElement()
      ..innerHtml = '<span></span> $text'
      ..style.padding = '4px 12px';
    e.children.first.style
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
    _context = CanvasElement().getContext('2d');
    _axesContext = CanvasElement().getContext('2d');
    _seriesContext = CanvasElement().getContext('2d');

    container.append(_context.canvas);
  }

  @Deprecated('Use [isAnimating] instead')
  bool get animating => isAnimating;

  /// Whether the chart is animating.
  bool get isAnimating => _animationStartTime != null;

  /// Whether the chart is interactive.
  ///
  /// This property returns `false` if the chart is animating or there are no
  /// series to draw.
  bool get isInteractive => !isAnimating && _seriesList != null;

  /// The element that contains this chart.
  final Element container;

  /// The data table that stores chart data.
  DataTable get dataTable => _dataTable;

  /// Disposes of resources used by this chart. The chart will become unusable
  /// until [draw] is called again.
  ///
  /// Be sure to call this method when the chart is no longer used to avoid any
  /// memory leaks.
  ///
  /// @mustCallSuper
  void dispose() {
    // This causes [canHandleInteraction] to be `false`.
    _seriesList = null;
    _mouseMoveSub?.cancel();
    _mouseMoveSub = null;
    _dataTableSubscriptionTracker.clear();
    _legendItemSubscriptionTracker.clear();
  }

  /// Draws the chart given a data table [dataTable] and an optional set of
  /// options [options].
  void draw(DataTable dataTable, [Map options]) {
    dispose();
    _dataTable = dataTable;
    _dataTableSubscriptionTracker
      ..add(dataTable.onCellChange.listen(_dataCellChanged))
      ..add(dataTable.onColumnsChange.listen(_dataColumnsChanged))
      ..add(dataTable.onRowsChange.listen(_dataRowsChanged));
    _options = mergeMaps(_defaultOptions, options);
    _easingFunction = getEasingFunction(_options['animation']['easing']);
    _initializeLegend();
    _initializeTooltip();
    resize(true);
  }

  /// Resizes the chart to fit the new size of the container.
  void resize([bool forceRedraw = false]) {
    var w = container.clientWidth;
    var h = container.clientHeight;

    if (w == 0 || h == 0) return;

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
  void update([Map options]) {
    if (_width == 0 || _height == 0) return;

    if (options != null) {
      _options = mergeMaps(_options, options);
    }

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
  num _xAxisTop;
  num _yAxisLeft;
  num _xAxisLength;
  num _yAxisLength;
  num _xLabelMaxWidth;
  num _yLabelMaxWidth;
  num _xLabelRotation; // 0..90
  int _xLabelStep;
  num _xLabelHop; // Distance between two consecutive x-axis labels.
  num _yLabelHop; // Distance between two consecutive x-axis labels.
//  Rectangle _xTitleBox;
//  Rectangle _yTitleBox;
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
  List<num> _averageYValues;

  final num _xLabelOffsetFactor = .5;

  /// Returns the x coordinate of the x-axis label at [index].
  num _xLabelX(int index) =>
      _yAxisLeft + _xLabelHop * (index + _xLabelOffsetFactor);

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

    _yMaxValue = _options['yAxis']['maxValue'] ?? double.negativeInfinity;
    _yMaxValue = max(_yMaxValue, findMaxValue(_dataTable));
    if (_yMaxValue == double.negativeInfinity) _yMaxValue = 0.0;

    _yMinValue = _options['yAxis']['minValue'] ?? double.infinity;
    _yMinValue = min(_yMinValue, findMinValue(_dataTable));
    if (_yMinValue == double.infinity) _yMinValue = 0.0;

    _yInterval = _options['yAxis']['interval'];
    var minInterval = _options['yAxis']['minInterval'];

    if (_yInterval == null) {
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
    }

    _yMinValue = (_yMinValue / _yInterval).floorToDouble() * _yInterval;
    _yMaxValue = (_yMaxValue / _yInterval).ceilToDouble() * _yInterval;
    _yRange = _yMaxValue - _yMinValue;

    // y-axis labels.

    _yLabels = <String>[];
    _yLabelFormatter = _options['yAxis']['labels']['formatter'];
    if (_yLabelFormatter == null) {
      var maxDecimalPlaces =
          max(getDecimalPlaces(_yInterval), getDecimalPlaces(_yMinValue));
      var numberFormat = NumberFormat.decimalPattern()
        ..maximumFractionDigits = maxDecimalPlaces
        ..minimumFractionDigits = maxDecimalPlaces;
      _yLabelFormatter = numberFormat.format;
    }
    var value = _yMinValue;
    while (value <= _yMaxValue) {
      _yLabels.add(_yLabelFormatter(value));
      value += _yInterval;
    }
    _yLabelMaxWidth = calculateMaxTextWidth(
            _context, _getFont(_options['yAxis']['labels']['style']), _yLabels)
        .round();

    _entityValueFormatter = _yLabelFormatter;

    // Tooltip.

    _tooltipValueFormatter =
        _options['tooltip']['valueFormatter'] ?? _yLabelFormatter;

    // x-axis title.

    var xTitleLeft = 0;
    var xTitleTop = 0;
    var xTitleWidth = 0;
    var xTitleHeight = 0;
    var xTitle = _options['xAxis']['title'];
    if (xTitle['text'] != null) {
      _context.font = _getFont(xTitle['style']);
      xTitleWidth = _context.measureText(xTitle['text']).width.round() +
          2 * _titlePadding;
      xTitleHeight = xTitle['style']['fontSize'] + 2 * _titlePadding;
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
          2 * _titlePadding;
      yTitleWidth = yTitle['style']['fontSize'] + 2 * _titlePadding;
      yTitleLeft = _seriesAndAxesBox.left;
    }

    // Axes' size and position.

    _yAxisLeft = _seriesAndAxesBox.left + _yLabelMaxWidth + _axisLabelMargin;
    if (yTitleWidth > 0) {
      _yAxisLeft += yTitleWidth + _chartTitleMargin;
    } else {
      _yAxisLeft += _axisLabelMargin;
    }

    _xAxisLength = _seriesAndAxesBox.right - _yAxisLeft;

    _xAxisTop = _seriesAndAxesBox.bottom;
    if (xTitleHeight > 0) {
      _xAxisTop -= xTitleHeight + _chartTitleMargin;
    } else {
      _xAxisTop -= _axisLabelMargin;
    }
    _xAxisTop -= _axisLabelMargin;

    // x-axis labels and x-axis's position.

    _xLabels = <String>[];
    for (var i = 0; i < _dataTable.rows.length; i++) {
      _xLabels.add(_dataTable.rows[i][0].toString());
    }
    _xLabelMaxWidth = calculateMaxTextWidth(
        _context, _getFont(_options['xAxis']['labels']['style']), _xLabels);
    if (_xLabelOffsetFactor > 0 && _xLabels.length > 1) {
      _xLabelHop = _xAxisLength / _xLabels.length;
    } else {
      _xLabelHop = _xAxisLength / (_xLabels.length - 1);
    }
    _xLabelRotation = 0;

    var fontSize = _options['xAxis']['labels']['style']['fontSize'];
    var maxRotation = _options['xAxis']['labels']['maxRotation'];
    var minRotation = _options['xAxis']['labels']['minRotation'];
    const angles = [0, -45, 45, -90, 90];

    outer:
    for (var step = 1; step <= _xLabels.length; step++) {
      var scaledLabelHop = step * _xLabelHop;
      var minSpacing = max(.1 * scaledLabelHop, 10);
      for (var angle in angles) {
        if (angle > maxRotation) continue;
        if (angle < minRotation) continue;

        var absAngleRad = deg2rad(angle).abs();
        var labelSpacing = angle == 0
            ? scaledLabelHop - _xLabelMaxWidth
            : scaledLabelHop * sin(absAngleRad) - fontSize;
        if (labelSpacing < minSpacing) continue;

        _xLabelRotation = angle;
        _xLabelStep = step;
        _xAxisTop -=
            _xLabelMaxWidth * sin(absAngleRad) + fontSize * cos(absAngleRad);
        break outer;
      }
    }

    // Wrap up.

    _yAxisLength = _xAxisTop -
        _seriesAndAxesBox.top -
        _options['yAxis']['labels']['style']['fontSize'] ~/ 2;
    _yLabelHop = _yAxisLength / (_yLabels.length - 1);

    xTitleLeft = _yAxisLeft + (_xAxisLength - xTitleWidth) ~/ 2;
    yTitleTop = _seriesAndAxesBox.top + (_yAxisLength - yTitleHeight) ~/ 2;

    if (xTitleHeight > 0) {
//      _xTitleBox =
//          Rectangle(xTitleLeft, xTitleTop, xTitleWidth, xTitleHeight);
      _xTitleCenter =
          Point(xTitleLeft + xTitleWidth ~/ 2, xTitleTop + xTitleHeight ~/ 2);
    } else {
//      _xTitleBox = null;
      _xTitleCenter = null;
    }

    if (yTitleHeight > 0) {
//      _yTitleBox =
//          Rectangle(yTitleLeft, yTitleTop, yTitleWidth, yTitleHeight);
      _yTitleCenter =
          Point(yTitleLeft + yTitleWidth ~/ 2, yTitleTop + yTitleHeight ~/ 2);
    } else {
//      _yTitleBox = null;
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
      var opt = _options['xAxis']['title'];
      _axesContext
        ..fillStyle = opt['style']['color']
        ..font = _getFont(opt['style'])
        ..textAlign = 'center'
        ..textBaseline = 'middle'
        ..fillText(opt['text'], _xTitleCenter.x, _xTitleCenter.y);
    }

    // y-axis title.

    if (_yTitleCenter != null) {
      var opt = _options['yAxis']['title'];
      _axesContext
        ..save()
        ..fillStyle = opt['style']['color']
        ..font = _getFont(opt['style'])
        ..translate(_yTitleCenter.x, _yTitleCenter.y)
        ..rotate(-_pi_2)
        ..textAlign = 'center'
        ..textBaseline = 'middle'
        ..fillText(opt['text'], 0, 0)
        ..restore();
    }

    // x-axis labels.

    var opt = _options['xAxis']['labels'];
    _axesContext.fillStyle = opt['style']['color'];
    _axesContext.font = _getFont(opt['style']);
    var x = _xLabelX(0);
    var y = _xAxisTop + _axisLabelMargin + opt['style']['fontSize'];
    var scaledLabelHop = _xLabelStep * _xLabelHop;

    if (_xLabelRotation == 0) {
      _axesContext.textAlign = 'center';
      _axesContext.textBaseline = 'alphabetic';
      for (var i = 0; i < _xLabels.length; i += _xLabelStep) {
        _axesContext.fillText(_xLabels[i], x, y);
        x += scaledLabelHop;
      }
    } else {
      _axesContext.textAlign = _xLabelRotation < 0 ? 'right' : 'left';
      _axesContext.textBaseline = 'middle';
      if (_xLabelRotation == 90) {
        x += _xLabelRotation.sign * (opt['style']['fontSize'] ~/ 8);
      }
      var angle = deg2rad(_xLabelRotation);
      for (var i = 0; i < _xLabels.length; i += _xLabelStep) {
        _axesContext
          ..save()
          ..translate(x, y)
          ..rotate(angle)
          ..fillText(_xLabels[i], 0, 0)
          ..restore();
        x += scaledLabelHop;
      }
    }

    // y-axis labels.

    _axesContext
      ..fillStyle = _options['yAxis']['labels']['style']['color']
      ..font = _getFont(_options['yAxis']['labels']['style'])
      ..textAlign = 'right'
      ..textBaseline = 'middle';
    x = _yAxisLeft - _axisLabelMargin;
    y = _xAxisTop - (_options['yAxis']['labels']['style']['fontSize'] ~/ 8);
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
    if (_xLabelStep > 1) {
      x = _xLabelX(0);
    }
    if (lineWidth > 0) {
      y = _xAxisTop - _yAxisLength;
    } else {
      lineWidth = 1;
      y = _xAxisTop + _axisLabelMargin;
    }
    _axesContext
      ..lineWidth = lineWidth
      ..strokeStyle = _options['yAxis']['gridLineColor']
      ..beginPath();
    for (var i = 0; i < _xLabels.length; i += _xLabelStep) {
      _axesContext.moveTo(x, y);
      _axesContext.lineTo(x, _xAxisTop);
      x += scaledLabelHop;
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
      var index = (dx / _xLabelHop - _xLabelOffsetFactor).round();
      // If there is at least one visible point in the current point group...
      if (_averageYValues[index] != null) return index;
    }
    return -1;
  }

  @override
  Point _getTooltipPosition() {
    var x = _xLabelX(_focusedEntityIndex) + _tooltipOffset;
    var y = _averageYValues[_focusedEntityIndex] - _tooltip.offsetHeight ~/ 2;
    if (x + _tooltip.offsetWidth > _width) {
      x -= _tooltip.offsetWidth + 2 * _tooltipOffset;
    }
    return Point(x, y);
  }

  _TwoAxisChart(Element container) : super(container);

  @override
  void update([Map options]) {
    super.update(options);
    _calculateAverageYValues();
  }
}
