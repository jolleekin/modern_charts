/// Code based on charts.js by Nick Downie, http://chartjs.org/
///
/// (Partial) Dart implementation done by Symcon GmbH, Tim Rasim
///
/// Easing functions adapted from Robert Penner's easing equations
/// http://www.robertpenner.com/easing/
library chart.src.animation;

import 'dart:math';

/// The easing function type.
///
/// An easing function takes an input number [t] in range 0..1, inclusive, and
/// returns a non-negative value. In addition, the function must return 1 for
/// [t] = 1.
typedef double EasingFunction(double t);

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
  t *= 2;
  if (t < 1) return .5 * t * t;
  t--;
  return .5 * (1 - t * (t - 2));
}

double easeInCubic(double t) {
  return t * t * t;
}

double easeOutCubic(double t) {
  t--;
  return t * t * t + 1;
}

double easeInOutCubic(double t) {
  t *= 2;
  if (t < 1) return .5 * t * t * t;
  t -= 2;
  return .5 * (t * t * t + 2);
}

double easeInQuart(double t) {
  return t * t * t * t;
}

double easeOutQuart(double t) {
  t--;
  return 1 - t * t * t * t;
}

double easeInOutQuart(double t) {
  t *= 2;
  if (t < 1) return .5 * t * t * t * t;
  t -= 2;
  return .5 * (2 - t * t * t * t);
}

double easeInQuint(double t) {
  return t * t * t * t * t;
}

double easeOutQuint(double t) {
  t--;
  return t * t * t * t * t + 1;
}

double easeInOutQuint(double t) {
  t *= 2;
  if (t < 1) return .5 * t * t * t * t * t;
  t -= 2;
  return .5 * (t * t * t * t * t + 2);
}

double easeInSine(double t) {
  return 1 - cos(t * PI / 2);
}

double easeOutSine(double t) {
  return sin(t * PI / 2);
}

double easeInOutSine(double t) {
  return .5 * (1 - cos(PI * t));
}

double easeInExpo(double t) {
  return (t == 0.0) ? 1.0 : pow(2, 10 * (t - 1));
}

double easeOutExpo(double t) {
  return (t == 1.0) ? 1.0 : (1 - pow(2, -10 * t));
}

double easeInOutExpo(double t) {
  if (t == 0.0) return 0.0;
  if (t == 1.0) return 1.0;
  t *= 2;
  if (t < 1) return 1 / 2 * pow(2, 10 * (t - 1));
  return .5 * (-pow(2, -10 * --t) + 2);
}

double easeInCirc(double t) {
  if (t >= 1) return t;
  return 1 - sqrt(1 - t * t);
}

double easeOutCirc(double t) {
  t--;
  return sqrt(1 - t * t);
}

double easeInOutCirc(double t) {
  t *= 2;
  if (t < 1) return -.5 * (sqrt(1 - t * t) - 1);
  t -= 2;
  return .5 * (sqrt(1 - t * t) + 1);
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
    s = p / 4;
  } else {
    s = p / (2 * PI) * asin(1 / a);
  }
  t--;
  return -(a * pow(2, 10 * t) * sin((t - s) * (2 * PI) / p));
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
    s = p / 4;
  } else {
    s = p / (2 * PI) * asin(1 / a);
  }
  return a * pow(2, -10 * t) * sin((t - s) * (2 * PI) / p) + 1;
}

double easeInOutElastic(double t) {
  var s = 1.70158;
  var p = 0.0;
  var a = 1.0;
  if (t == 0.0) return 0.0;
  if (t == 1.0) return 1.0;
  if (p == 0.0) p = 1 * (.3 * 1.5);
  if (a < 1) {
    a = 1.0;
    s = p / 4;
  } else {
    s = p / (2 * PI) * asin(1 / a);
  }
  t = 2 * t - 1;
  if (t < 0) return -.5 * (a * pow(2, 10 * t) * sin((t - s) * (2 * PI) / p));
  return a * pow(2, -10 * t) * sin((t - s) * (2 * PI) / p) * .5 + 1;
}

double easeInBack(double t) {
  const s = 1.70158;
  return t * t * ((s + 1) * t - s);
}

double easeOutBack(double t) {
  const s = 1.70158;
  t--;
  return t * t * ((s + 1) * t + s) + 1;
}

double easeInOutBack(double t) {
  const s = 1.70158 * 1.525;
  t *= 2;
  if (t < 1) return .5 * (t * t * ((s + 1) * t - s));
  t -= 2;
  return .5 * (t * t * ((s + 1) * t + s) + 2);
}

double easeInBounce(double t) {
  return 1 - easeOutBounce(1 - t);
}

double easeOutBounce(double t) {
  if (t < 1 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2 / 2.75) {
    t -= 1.5 / 2.75;
    return 7.5625 * t * t + .75;
  } else if (t < 2.5 / 2.75) {
    t -= 2.25 / 2.75;
    return 7.5625 * t * t + .9375;
  } else {
    t -= 2.625 / 2.75;
    return 7.5625 * t * t + .984375;
  }
}

double easeInOutBounce(double t) {
  if (t < .5) return easeInBounce(t * 2) * .5;
  return easeOutBounce(t * 2 - 1) * .5 + 1 * .5;
}

/// Returns the easing function with the given [name].
///
/// [name] can be an [EasingFunction] or a [String] specifying the name of one
/// of the easing functions defined above.
EasingFunction getEasingFunction(name) {
  if (name is EasingFunction) return name;
  switch (name) {
    case 'linear':
      return linear;
    case 'easeInQuad':
      return easeInQuad;
    case 'easeOutQuad':
      return easeOutQuad;
    case 'easeInOutQuad':
      return easeInOutQuad;
    case 'easeInCubic':
      return easeInCubic;
    case 'easeOutCubic':
      return easeOutCubic;
    case 'easeInOutCubic':
      return easeInOutCubic;
    case 'easeInQuart':
      return easeInQuart;
    case 'easeOutQuart':
      return easeOutQuart;
    case 'easeInOutQuart':
      return easeInOutQuart;
    case 'easeInQuint':
      return easeInQuint;
    case 'easeOutQuint':
      return easeOutQuint;
    case 'easeInOutQuint':
      return easeInOutQuint;
    case 'easeInSine':
      return easeInSine;
    case 'easeOutSine':
      return easeOutSine;
    case 'easeInOutSine':
      return easeInOutSine;
    case 'easeInExpo':
      return easeInExpo;
    case 'easeOutExpo':
      return easeOutExpo;
    case 'easeInOutExpo':
      return easeInOutExpo;
    case 'easeInCirc':
      return easeInCirc;
    case 'easeOutCirc':
      return easeOutCirc;
    case 'easeInOutCirc':
      return easeInOutCirc;
    case 'easeInElastic':
      return easeInElastic;
    case 'easeOutElastic':
      return easeOutElastic;
    case 'easeInOutElastic':
      return easeInOutElastic;
    case 'easeInBack':
      return easeInBack;
    case 'easeOutBack':
      return easeOutBack;
    case 'easeInOutBack':
      return easeInOutBack;
    case 'easeInBounce':
      return easeInBack;
    case 'easeOutBounce':
      return easeOutBounce;
    case 'easeInOutBounce':
      return easeInOutBounce;
    default:
      throw new ArgumentError.value(name, 'name');
  }
}
