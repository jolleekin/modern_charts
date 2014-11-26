library chart.src.utils;

import 'dart:html';
import 'dart:math' as math;

import 'datatable.dart';

double degree(num angle) => angle * 180 / math.PI;

/// Converts [angle] to radian.
double radian(num angle) => angle * math.PI / 180;

/// Returns the base-10 logarithm of [value].
double log10(double value) => math.log(value) / math.LN10;

/// Returns a linear interpolated value based on the start value [start], the
/// end value [end], and the interpolation factor [s].
///
/// [start] and [end] can be of any type which defines three operators +, - , *.
lerp(start, end, double s) =>
    start + (end - start) * s;

bool isInRange(num value, num min, num max) => value >= min && value <= max;

Point<double> polarToCartesian(Point center, num radius, num angle) {
  var x = center.x + radius * math.cos(angle);
  var y = center.y + radius * math.sin(angle);
  return new Point<double>(x, y);
}

/// Rounds [value] to [places] decimal places.
double roundToPlaces(double value, int places) {
  var p = math.pow(10, places);
  value = value * p;
  return value.round() / p;
}

/// Returns the order of magnitude of [value].
int calculateOrderOfMagnitude(num value) {
  if (value != 0) {
    return math.max((math.log(value) / math.LN10).floor(), 0);
  }
  return 1;
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
  return s.replaceAllMapped(new RegExp('[A-Z]'), (Match m) {
    return '-' + m[0].toLowerCase();
  });
}

/// Returns the maximum value in a [DataTable].
double findMaxValue(DataTable table) {
  var maxValue = -double.MAX_FINITE;
  for (var row in table.rows) {
    for (var col in table.columns) {
      var value = row[col.index];
      if (value is num && maxValue < value) maxValue = value.toDouble();
    }
  }
  return maxValue;
}

/// Returns the minimum value of a 2D list of numbers.
double findMinValue(DataTable table) {
  var minValue = double.MAX_FINITE;
  for (var row in table.rows) {
    for (var col in table.columns) {
      var value = row[col.index];
      if (value is num && minValue > value) minValue = value.toDouble();
    }
  }
  return minValue;
}

/// Calculates a nice axis interval given the axis range [range] and the desired
/// number of steps [targetSteps].
double calculateInterval(double range, int targetSteps) {
  var interval = range / targetSteps;
  var mag = log10(interval).floor();
  var magPow = math.pow(10, mag).toDouble();
  var msd = (interval / magPow).round();
  if (msd > 5) {
    msd = 10;
  } else if (msd > 2) {
    msd = 5;
  }
  return msd * magPow;
}

double calculateMaxTextWidth(CanvasRenderingContext2D context, String font,
    List<String> texts) {
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
/// Credit: Rob Spencer (http://scaledinnovation.com/analytics/splines/aboutSplines.html)
List<Point> calculateControlPoints(Point p1, Point p2, Point p3, num t) {
  var d21 = p2.distanceTo(p1);
  var d23 = p2.distanceTo(p3);
  var fa = t * d21 / (d21 + d23);
  var fb = t * d23 / (d21 + d23);
  var v13 = p3 - p1;
  var cp1 = p2 - v13 * fa;
  var cp2 = p2 + v13 * fb;
  return [cp1, cp2];
}

/// Returns the number of decimal digits of [value].
int getDecimalPlaces(num value) {
  if (value % 1 == 0) return 0;
  // See https://code.google.com/p/dart/issues/detail?id=1533
  return '$value.0'.split('.')[1].length;
}

/// Recursively merges [src] into [dst].
///
/// Values in [dst] override values in [src].
/// [dst] can be `null`.
///
/// Keys that exist in [dst] but not in [src] will be removed.
///
/// Returns [dst].
Map mergeMap(Map dst, Map src) {
  if (dst == null) dst = {};
  for (var k in dst.keys.toList()) {
    if (!src.containsKey(k)) dst.remove(k);
  }
  src.forEach((k, v) {
    if (v is Map) {
      if (!dst.containsKey(k)) dst[k] = {};
      mergeMap(dst[k], v);
    } else {
      if (dst.containsKey(k)) return;
      if (v is List) {
        dst[k] = new List.from(v);
      } else {
        dst[k] = v;
      }
    }
  });
  return dst;
}

Map cloneMap(Map src) {
  var result = {};
  src.forEach((k, v) {
    if (v is Map) {
      result[k] = cloneMap(v);
    } else if (v is List) {
      result[k] = new List.from(v);
    } else {
      result[k] = v;
    }
  });
  return result;
}

Map extendMap(Map src, Map ext) {
 var result = cloneMap(src);
 ext.forEach((k, v) {
   result[k] = v;
 });
 return result;
}
