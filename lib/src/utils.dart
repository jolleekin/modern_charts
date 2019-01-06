library chart.src.utils;

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'datatable.dart';

/// Converts [angle] in radians to degrees.
double rad2deg(num angle) => angle * 180 / pi;

/// Converts [angle] in degrees to radians.
double deg2rad(num angle) => angle * pi / 180;

/// Returns the base-10 logarithm of [value].
double log10(num value) => log(value) / ln10;

/// Returns a linear interpolated value based on the start value [start], the
/// end value [end], and the interpolation factor [f].
///
/// [start] and [end] can be of any type which defines three operators +, - , *.
lerp(start, end, double f) => start + (end - start) * f;

/// Tests if [value] is in range [min]..[max], inclusively.
bool isInRange(num value, num min, num max) => value >= min && value <= max;

Point<double> polarToCartesian(Point center, num radius, num angle) {
  var x = center.x + radius * cos(angle);
  var y = center.y + radius * sin(angle);
  return Point<double>(x, y);
}

/// Rounds [value] to [places] decimal places.
double roundToPlaces(double value, int places) {
  var p = pow(10, places);
  value = value * p;
  return value.round() / p;
}

/// Converts [hexColor] and [alpha] to an RGBA color string.
String hexToRgba(String hexColor, num alpha) {
  var componentLength = hexColor.length ~/ 3;
  var i = 1 + componentLength;
  var j = i + componentLength;
  var r = int.parse(hexColor.substring(1, i), radix: 16);
  var g = int.parse(hexColor.substring(i, j), radix: 16);
  var b = int.parse(hexColor.substring(j), radix: 16);
  if (componentLength == 1) {
    r += r << 4;
    g += g << 4;
    b += b << 4;
  }
  return 'rgba($r, $g, $b, $alpha)';
}

/// Returns the hyphenated version of [s].
String hyphenate(String s) {
  return s.replaceAllMapped(RegExp('[A-Z]'), (Match m) {
    return '-' + m[0].toLowerCase();
  });
}

/// Returns the maximum value in a [DataTable].
num findMaxValue(DataTable table) {
  var maxValue = double.negativeInfinity;
  for (var row in table.rows) {
    for (var col in table.columns) {
      var value = row[col.index];
      if (value is num && value > maxValue) maxValue = value;
    }
  }
  return maxValue;
}

/// Returns the minimum value in a [DataTable].
num findMinValue(DataTable table) {
  var minValue = double.infinity;
  for (var row in table.rows) {
    for (var col in table.columns) {
      var value = row[col.index];
      if (value is num && value < minValue) minValue = value;
    }
  }
  return minValue;
}

/// Calculates a nice axis interval given
/// - the axis range [range]
/// - the desired number of steps [targetSteps]
/// - and the minimum interval [minInterval]
num calculateInterval(num range, int targetSteps, [num minInterval]) {
  var interval = range / targetSteps;
  var mag = log10(interval).floor();
  var magPow = pow(10, mag).toDouble();
  if (minInterval != null) {
    magPow = max(magPow, minInterval);
  }
  var msd = (interval / magPow).round();
  if (msd > 5) {
    msd = 10;
  } else if (msd > 2) {
    msd = 5;
  } else if (msd == 0) {
    msd = 1;
  }
  return msd * magPow;
}

double calculateMaxTextWidth(
    CanvasRenderingContext2D context, String font, List<String> texts) {
  var result = 0.0;
  context.font = font;
  for (var text in texts) {
    var width = context.measureText(text).width;
    if (result < width) result = width;
  }
  return result;
}

/// Calculates the controls for [p2] given the previous point [p1], the next
/// point [p3], and the curve tension [t];
///
/// Returns a list that contains two control points for [p2].
///
/// Credit: Rob Spencer (http://scaledinnovation.com/analytics/splines/aboutSplines.html)
List<Point> calculateControlPoints(Point p1, Point p2, Point p3, num t) {
  var d21 = p2.distanceTo(p1);
  var d23 = p2.distanceTo(p3);
  var fa = t * d21 / (d21 + d23);
  var fb = t * d23 / (d21 + d23);
  var v13 = p3 - p1;
  var cp1 = p2 - v13 * fa;
  var cp2 = p2 + v13 * fb;
  return <Point>[cp1, cp2];
}

/// Returns the number of decimal digits of [value].
int getDecimalPlaces(num value) {
  if (value % 1 == 0) return 0;
  // See https://code.google.com/p/dart/issues/detail?id=1533
  return '$value.0'.split('.')[1].length;
}

/// Deeply merges [map1] and [map2] into a new [Map].
///
/// [map1] must not be `null`.
///
/// If [map2] is `null`, returns [map1].
Map mergeMaps(Map map1, Map map2) {
  if (map2 == null) return map1;

  var result = {};
  cb(k, v) {
    result[k] = v is Map ? mergeMaps(result[k], v) : v;
  }

  map1?.forEach(cb);
  map2?.forEach(cb);
  return result;
}

class StreamSubscriptionTracker {
  final _subs = <StreamSubscription>[];

  void add(StreamSubscription sub) {
    _subs.add(sub);
  }

  void clear() {
    for (var sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
  }
}
