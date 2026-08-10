// ImageBuiltIn is not exported by package:flutter_html/flutter_html.dart,
// only reachable via this implementation import. flutter_html's own
// ImageExtension helper subclasses it through the same import, but its
// builder API *replaces* the built-in rendering instead of wrapping it,
// so it can't be used to filter the widget the built-in builds.
// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/src/builtins/image_builtin.dart';

/// Renders `<img>` elements exactly like flutter_html's built-in image
/// renderer, optionally drawing the image through a hue-preserving color
/// inversion for dark mode: black becomes white, grays flip lightness,
/// transparency passes through unchanged and colored artwork keeps its
/// hue with lightness flipped.
///
/// With [invert] false the built-in rendering is returned unchanged —
/// no wrapper widget is added at all.
class InvertibleImageBuiltIn extends ImageBuiltIn {
  final bool invert;

  const InvertibleImageBuiltIn({required this.invert});

  @override
  InlineSpan build(ExtensionContext context) {
    final span = super.build(context);
    if (!invert || span is! WidgetSpan) {
      // Light mode stays untouched; so do images the built-in renderer
      // can't decode (super returns a plain TextSpan with the alt text).
      return span;
    }
    return WidgetSpan(
      alignment: span.alignment,
      baseline: span.baseline,
      style: span.style,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_invertKeepHueMatrix),
        child: span.child,
      ),
    );
  }
}

/// Color inversion that keeps hues, like CSS
/// `filter: invert(1) hue-rotate(180deg)` ("smart invert"):
/// black -> white, grays invert exactly (each row sums to -1, plus the
/// 255 offset), alpha is untouched (last row) and colors keep their hue
/// with flipped lightness.
const List<double> _invertKeepHueMatrix = [
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0,
];
