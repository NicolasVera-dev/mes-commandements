// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Prépare l’icône d’application à partir de `assets/images/icon.png` :
/// rogne transparence + marges blanches, puis **remplit tout un carré 1024×1024**
/// (mode *cover* : agrandissement + rognage centré, sans bandes blanches).
///
/// Usage : `dart run tool/normalize_brand_assets.dart`
void main() {
  _normalizeIconLauncher();
}

void _normalizeIconLauncher() {
  const input = 'assets/images/icon.png';
  const output = 'assets/images/icon_launcher.png';
  const size = 1024;

  final bytes = File(input).readAsBytesSync();
  final decoded = decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('Impossible de décoder: $input');
    exitCode = 1;
    return;
  }

  var art = trim(decoded, mode: TrimMode.transparent);

  for (var i = 0; i < 4; i++) {
    final next = trim(art, mode: TrimMode.topLeftColor);
    if (next.width == art.width && next.height == art.height) break;
    art = next;
  }

  art = _trimNearWhiteEdgeStrips(art, whiteThreshold: 250);

  if (art.width < 1 || art.height < 1) {
    stderr.writeln('Rogne vide après traitements: $input');
    exitCode = 1;
    return;
  }

  // Cover : échelle min pour que largeur ET hauteur ≥ 1024, puis fenêtre 1024² centrée.
  final scale = math.max(size / art.width, size / art.height);
  final scaledW = (art.width * scale).round();
  final scaledH = (art.height * scale).round();
  final scaled = copyResize(
    art,
    width: scaledW,
    height: scaledH,
    interpolation: Interpolation.cubic,
  );

  final cx = (scaledW - size + 1) ~/ 2;
  final cy = (scaledH - size + 1) ~/ 2;
  final cropped = copyCrop(
    scaled,
    x: cx,
    y: cy,
    width: size,
    height: size,
  );

  final canvas = Image(width: size, height: size, numChannels: 4);
  fill(canvas, color: ColorRgba8(255, 255, 255, 255));
  compositeImage(canvas, cropped, blend: BlendMode.alpha);

  File(output).writeAsBytesSync(encodePng(canvas));
  print(
    'Icône launcher → $output (${size}x$size, cover depuis ${art.width}x${art.height} '
    '→ ${scaledW}x$scaledH, rogne centre $cx,$cy).',
  );
}

/// Retire uniquement des **bandes** entièrement blanches / quasi blanches sur les bords
/// (ne supprime pas le blanc à l’intérieur du pictogramme).
Image _trimNearWhiteEdgeStrips(Image src, {required int whiteThreshold}) {
  var top = 0;
  var bottom = src.height - 1;
  var left = 0;
  var right = src.width - 1;

  while (top <= bottom && _rowIsAllNearWhite(src, top, whiteThreshold)) {
    top++;
  }
  while (bottom >= top && _rowIsAllNearWhite(src, bottom, whiteThreshold)) {
    bottom--;
  }
  while (left <= right && _colIsAllNearWhite(src, left, whiteThreshold)) {
    left++;
  }
  while (right >= left && _colIsAllNearWhite(src, right, whiteThreshold)) {
    right--;
  }

  final w = right - left + 1;
  final h = bottom - top + 1;
  if (w < 1 || h < 1) return src;
  return copyCrop(src, x: left, y: top, width: w, height: h);
}

bool _rowIsAllNearWhite(Image src, int y, int threshold) {
  for (var x = 0; x < src.width; x++) {
    if (!_isNearWhiteMargin(src.getPixel(x, y), threshold)) {
      return false;
    }
  }
  return true;
}

bool _colIsAllNearWhite(Image src, int x, int threshold) {
  for (var y = 0; y < src.height; y++) {
    if (!_isNearWhiteMargin(src.getPixel(x, y), threshold)) {
      return false;
    }
  }
  return true;
}

bool _isNearWhiteMargin(Pixel p, int threshold) {
  final a = p.a.toInt();
  if (a < 12) return true;
  final r = p.r.toInt();
  final g = p.g.toInt();
  final b = p.b.toInt();
  return r >= threshold && g >= threshold && b >= threshold;
}
