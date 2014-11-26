/**
 * Code based on charts.js by Nick Downie, http://chartjs.org/
 *
 * (Partial) Dart implementation done by Symcon GmbH, Tim Rasim
 *
 */
library chart.src.animation;

import 'dart:math' as math;

//Easing functions adapted from Robert Penner's easing equations
//http://www.robertpenner.com/easing/
double linear(double t) {
  return t;
}

double easeInQuad(double t) {
  return t * t;
}

double easeOutQuad(double t) {
  return t * (2 - t);
}

double easeInOutQuad(double t) {
  if ((t *= 2) < 1) return .5 * t * t;
  return -.5 * ((--t) * (t - 2) - 1);
}

double easeInCubic(double t) {
  return t * t * t;
}

double easeOutCubic(double t) {
  t--;
  return t * t * t + 1;
}

double easeInOutCubic(double t) {
  if ((t *= 2) < 1) return .5 * t * t * t;
  return .5 * ((t = t - 2) * t * t + 2);
}

double easeInQuart(double t) {
  return t * t * t * t;
}

double easeOutQuart(double t) {
  t--;
  return 1 - t * t * t * t;
}

double easeInOutQuart(double t) {
  if ((t *= 2) < 1) return .5 * t * t * t * t;
  return -.5 * ((t = t - 2) * t * t * t - 2);
}

double easeInQuint(double t) {
  return t * t * t * t * t;
}

double easeOutQuint(double t) {
  t--;
  return t * t * t * t * t + 1;
}

double easeInOutQuint(double t) {
  if ((t *= 2) < 1) return .5 * t * t * t * t * t;
  return .5 * ((t = t - 2) * t * t * t * t + 2);
}

double easeInSine(double t) {
  return -math.cos(t * math.PI / 2) + 1;
}

double easeOutSine(double t) {
  return math.sin(t * math.PI / 2);
}

double easeInOutSine(double t) {
  return -.5 * (math.cos(math.PI * t) - 1);
}

double easeInExpo(double t) {
  return (t == 0) ? 1 : math.pow(2, 10 * (t - 1));
}

double easeOutExpo(double t) {
  return (t == 1) ? 1 : (1 - math.pow(2, -10 * t));
}

double easeInOutExpo(double t) {
  if (t == 0.0) return 0.0;
  if (t == 1.0) return 1.0;
  if ((t *= 2) < 1) return 1 / 2 * math.pow(2, 10 * (t - 1));
  return .5 * (-math.pow(2, -10 * --t) + 2);
}

double easeInCirc(double t) {
  if (t >= 1) return t;
  return 1 - math.sqrt(1 - t * t);
}

double easeOutCirc(double t) {
  return math.sqrt(1 - (t = t - 1) * t);
}

double easeInOutCirc(double t) {
  if ((t *= 2) < 1) return -.5 * (math.sqrt(1 - t * t) - 1);
  return .5 * (math.sqrt(1 - (t = t - 2) * t) + 1);
}

double easeInElastic(double t) {
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (t == 0) return 0.0;
  if (t == 1) return 1.0;
  if (p == 0) p = 0.3;
  if (a < 1) {
    a = 1.0;
    var s = p / 4;
  } else {
    s = p / (2 * math.PI) * math.asin(1 / a);
  }
  return -(a * math.pow(2, 10 * (t =
      t - 1)) * math.sin((t - s) * (2 * math.PI) / p));
}

double easeOutElastic(double t) {
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (t == 0) return 0.0;
  if (t == 1) return 1.0;
  if (p == 0) p = 0.3;
  if (a < 1) {
    a = 1.0;
    var s = p / 4;
  } else {
    s = p / (2 * math.PI) * math.asin(1 / a);
  }
  return a * math.pow(2, -10 * t) * math.sin((t - s) * (2 * math.PI) / p) + 1;
}

double easeInOutElastic(double t) {
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (t == 0) return 0.0;
  if ((t *= 2) == 2) return 1.0;
  if (p == 0.0) p = 1 * (.3 * 1.5);
  if (a < 1) {
    a = 1.0;
    var s = p / 4;
  } else {
    s = p / (2 * math.PI) * math.asin(1 / a);
  }
  if (t < 1) return -.5 * (a * math.pow(2, 10 * (t =
      t - 1)) * math.sin((t - s) * (2 * math.PI) / p));
  return a * math.pow(2, -10 * (t =
      t - 1)) * math.sin((t - s) * (2 * math.PI) / p) * .5 + 1;
}

double easeInBack(double t) {
  var s = 1.70158;
  return t * t * ((s + 1) * t - s);
}

double easeOutBack(double t) {
  var s = 1.70158;
  return (t = t - 1) * t * ((s + 1) * t + s) + 1;
}

double easeInOutBack(double t) {
  var s = 1.70158;
  if ((t *= 2) < 1) return .5 * (t * t * (((s *= (1.525)) + 1) * t - s));
  return .5 * ((t = t - 2) * t * (((s *= (1.525)) + 1) * t + s) + 2);
}

double easeInBounce(double t) {
  return 1 - easeOutBounce(1 - t);
}

double easeOutBounce(double t) {
  if (t < (1 / 2.75)) {
    return 7.5625 * t * t;
  } else if (t < (2 / 2.75)) {
    return 7.5625 * (t = t - (1.5 / 2.75)) * t + .75;
  } else if (t < (2.5 / 2.75)) {
    return 7.5625 * (t = t - (2.25 / 2.75)) * t + .9375;
  } else {
    return 7.5625 * (t = t - (2.625 / 2.75)) * t + .984375;
  }
}

double easeInOutBounce(double t) {
  if (t < .5) return easeInBounce(t * 2) * .5;
  return easeOutBounce(t * 2 - 1) * .5 + 1 * .5;
}

double getEaseValue(String key, double t) {
  switch (key) {
    case 'linear':
      return linear(t);
    case 'easeInQuad':
      return easeInQuad(t);
    case 'easeOutQuad':
      return easeOutQuad(t);
    case 'easeInOutQuad':
      return easeInOutQuad(t);
    case 'easeInCubic':
      return easeInCubic(t);
    case 'easeOutCubic':
      return easeOutCubic(t);
    case 'easeInOutCubic':
      return easeInOutCubic(t);
    case 'easeInQuart':
      return easeInQuart(t);
    case 'easeOutQuart':
      return easeOutQuart(t);
    case 'easeInOutQuart':
      return easeInOutQuart(t);
    case 'easeInQuint':
      return easeInQuint(t);
    case 'easeOutQuint':
      return easeOutQuint(t);
    case 'easeInOutQuint':
      return easeInOutQuint(t);
    case 'easeInSine':
      return easeInSine(t);
    case 'easeOutSine':
      return easeOutSine(t);
    case 'easeInOutSine':
      return easeInOutSine(t);
    case 'easeInExpo':
      return easeInExpo(t);
    case 'easeOutExpo':
      return easeOutExpo(t);
    case 'easeInOutExpo':
      return easeInOutExpo(t);
    case 'easeInCirc':
      return easeInCirc(t);
    case 'easeOutCirc':
      return easeOutCirc(t);
    case 'easeInOutCirc':
      return easeInOutCirc(t);
    case 'easeInElastic':
      return easeInElastic(t);
    case 'easeOutElastic':
      return easeOutElastic(t);
    case 'easeInOutElastic':
      return easeInOutElastic(t);
    case 'easeInBack':
      return easeInBack(t);
    case 'easeOutBack':
      return easeOutBack(t);
    case 'easeInOutBack':
      return easeInOutBack(t);
    case 'easeInBounce':
      return easeInBack(t);
    case 'easeOutBounce':
      return easeOutBounce(t);
    case 'easeInOutBounce':
      return easeInOutBounce(t);
    default:
      throw new Exception('Unknown animation $key used!');
  }
}
