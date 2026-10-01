// Genera el catálogo de la demo a partir de `tool/catalog/catalog.json`:
//
//   assets/data/products.json   productos
//   assets/data/users.json      usuarios de prueba
//   assets/products/*.webp      una ilustración propia por producto
//
// Las ilustraciones se dibujan aquí mismo en SVG (sin imágenes de terceros) y
// se convierten a imagen con Chrome en modo headless y `cwebp` (si no está
// instalado, se dejan en PNG).
//
// Uso:
//   dart run tool/generate_catalog.dart
//   CHROME=/ruta/a/chrome dart run tool/generate_catalog.dart

// Los SVG se componen concatenando fragmentos, que aquí se lee mejor que interpolar.
// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';

const _catalogPath = 'tool/catalog/catalog.json';
const _dataDir = 'assets/data';
const _imagesDir = 'assets/products';
const _size = 800;
const _background = '#f3f2ef';

Future<void> main() async {
  final catalog = json.decode(File(_catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final users = List<Map<String, dynamic>>.from(catalog['users']);
  final owner = Map<String, dynamic>.from(users.first)..remove('password');

  final chrome = Platform.environment['CHROME'] ??
      '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  if (!File(chrome).existsSync()) {
    stderr.writeln('No se encuentra Chrome en "$chrome". Indica la ruta con la variable CHROME.');
    exit(1);
  }
  final hasCwebp = (await Process.run('which', ['cwebp'])).exitCode == 0;

  final imagesDir = Directory(_imagesDir);
  if (imagesDir.existsSync()) imagesDir.deleteSync(recursive: true);
  imagesDir.createSync(recursive: true);
  final tempDir = Directory.systemTemp.createTempSync('catalog_');

  final products = <Map<String, dynamic>>[];
  final slugs = <String>{};
  final source = List<Map<String, dynamic>>.from(catalog['products']);

  for (var i = 0; i < source.length; i++) {
    final item = source[i];
    var slug = '${_slugify(item['title'])}_${item['gender']}';
    while (!slugs.add(slug)) {
      slug = '${slug}_${i + 1}';
    }

    final svgFile = File('${tempDir.path}/$slug.svg')..writeAsStringSync(_garmentSvg(item['art']));
    final pngPath = '${tempDir.path}/$slug.png';
    final shot = await Process.run(chrome, [
      '--headless=new', '--disable-gpu', '--hide-scrollbars',
      '--window-size=$_size,$_size', '--screenshot=$pngPath', svgFile.uri.toString(),
    ]);
    if (!File(pngPath).existsSync()) {
      stderr.writeln('Chrome no pudo generar $slug: ${shot.stderr}');
      exit(1);
    }

    final String image;
    if (hasCwebp) {
      image = '$slug.webp';
      await Process.run('cwebp', ['-quiet', '-q', '82', '-m', '6', pngPath, '-o', '$_imagesDir/$image']);
    } else {
      image = '$slug.png';
      File(pngPath).copySync('$_imagesDir/$image');
    }

    products.add({
      'id': 'prod-${(i + 1).toString().padLeft(2, '0')}',
      'title': item['title'],
      'price': item['price'],
      'description': item['description'],
      'slug': slug,
      'stock': item['stock'],
      'sizes': item['sizes'],
      'gender': item['gender'],
      'tags': item['tags'],
      'images': [image],
      'user': owner,
    });
    stdout.write('.');
  }
  tempDir.deleteSync(recursive: true);

  const encoder = JsonEncoder.withIndent('  ');
  Directory(_dataDir).createSync(recursive: true);
  File('$_dataDir/products.json').writeAsStringSync('${encoder.convert({'products': products})}\n');
  File('$_dataDir/users.json').writeAsStringSync('${encoder.convert({'users': users})}\n');

  stdout.writeln('\nListo: ${products.length} productos y ${users.length} usuarios'
      '${hasCwebp ? '' : ' (sin cwebp: imágenes en PNG)'}.');
}

String _slugify(String text) {
  const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};
  return text
      .toLowerCase()
      .split('')
      .map((c) => accents[c] ?? c)
      .join()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

// --- Color ---------------------------------------------------------------------

List<int> _rgb(String hex) => [
      for (var i = 1; i < 7; i += 2) int.parse(hex.substring(i, i + 2), radix: 16),
    ];

String _hex(List<num> rgb) =>
    '#${rgb.map((c) => c.round().clamp(0, 255).toInt().toRadixString(16).padLeft(2, '0')).join()}';

String _mix(String a, String b, double t) {
  final ca = _rgb(a), cb = _rgb(b);
  return _hex([for (var i = 0; i < 3; i++) ca[i] + (cb[i] - ca[i]) * t]);
}

/// Contorno: más oscuro que la prenda, y algo más marcado en colores muy claros.
String _stroke(String color) {
  final c = _rgb(color);
  final luminance = (0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]) / 255;
  return _mix(color, '#1d1d1d', luminance > 0.85 ? 0.45 : 0.3);
}

// --- Ilustraciones ---------------------------------------------------------------

String _garmentSvg(Map<String, dynamic> art) {
  final color = art['color'] as String;
  final accent = (art['accent'] as String?) ?? _mix(color, '#1d1d1d', 0.35);
  final style = (art['style'] as String?) ?? 'plain';
  final stroke = _stroke(color);
  final shade = _mix(color, '#1d1d1d', 0.12);

  final garment = switch (art['type']) {
    'tee' => _tee(color, accent, stroke, style),
    'longsleeve' => _longSleeve(color, accent, stroke, shade, style),
    'sweatshirt' => _sweatshirt(color, accent, stroke, shade, style),
    'hoodie' => _hoodie(color, accent, stroke, shade, style, strings: art['kid'] != true),
    'jacket' => _jacket(color, accent, stroke, shade, style),
    'joggers' => _joggers(color, stroke, shade),
    'onesie' => _onesie(color, accent, stroke, style),
    'beanie' => _beanie(color, stroke, shade, style),
    'cap' => _cap(color, stroke, shade),
    _ => throw ArgumentError('Tipo de prenda desconocido: ${art['type']}'),
  };

  // Las prendas infantiles se dibujan algo más pequeñas.
  final scale = art['kid'] == true ? 0.84 : 1.0;
  final transform = scale == 1.0
      ? ''
      : 'transform="translate(200 215) scale($scale) translate(-200 -215)"';

  return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" width="$_size" height="$_size">
<rect width="400" height="400" fill="$_background"/>
<g $transform stroke-linejoin="round" stroke-linecap="round">
<ellipse cx="200" cy="352" rx="105" ry="9" fill="#000" opacity=".07"/>$garment</g>
</svg>''';
}

/// Cuerpo de la prenda con relleno y, según el estilo, detalles recortados a su forma.
String _body(String id, String path, String color, String stroke, String accent, String style,
    {double bandY = 186, double stripeGap = 34}) {
  final overlay = switch (style) {
    'stripes' => [
        for (var y = 40.0; y < 380; y += stripeGap)
          '<rect x="0" y="$y" width="400" height="${(stripeGap * 0.36).toStringAsFixed(1)}" fill="$accent"/>',
      ].join(),
    'band' => '<rect x="0" y="$bandY" width="400" height="30" fill="$accent"/>',
    _ => '',
  };
  return '''
<clipPath id="$id"><path d="$path"/></clipPath>
<path d="$path" fill="$color"/>
<g clip-path="url(#$id)">$overlay</g>
<path d="$path" fill="none" stroke="$stroke" stroke-width="3"/>''';
}

String _chestDetails(String color, String accent, String stroke, String style, {double cy = 196}) =>
    switch (style) {
      'pocket' => '<path d="M222 ${cy - 16} h38 v40 q0 6 -6 6 h-26 q-6 0 -6 -6 Z" fill="${_mix(color, '#1d1d1d', 0.08)}" stroke="$stroke" stroke-width="2.5"/>'
          '<line x1="222" y1="${cy - 8}" x2="260" y2="${cy - 8}" stroke="$stroke" stroke-width="1.5" stroke-dasharray="3 3"/>',
      'print' => '<circle cx="200" cy="${cy - 6}" r="24" fill="$accent"/>'
          '<path d="M162 ${cy + 26} q10 -10 20 0 t20 0 t20 0 t20 0" fill="none" stroke="$accent" stroke-width="5"/>'
          '<path d="M170 ${cy + 40} q10 -10 20 0 t20 0 t20 0" fill="none" stroke="$accent" stroke-width="5"/>',
      _ => '',
    };

String _tee(String color, String accent, String stroke, String style) {
  const path = 'M140 82 Q200 112 260 82 L332 112 L312 178 L281 168 L281 332 L119 332 L119 168 L88 178 L68 112 Z';
  return _body('tee', path, color, stroke, accent, style) +
      '<path d="M163 87 Q200 122 237 87" fill="none" stroke="$stroke" stroke-width="6"/>'
          '<path d="M119 168 L127 118 M281 168 L273 118" fill="none" stroke="$stroke" stroke-width="2" opacity=".5"/>' +
      _chestDetails(color, accent, stroke, style);
}

const _longPath =
    'M140 82 Q200 112 260 82 L322 108 L352 298 L318 306 L284 172 L284 332 L116 332 L116 172 L82 306 L48 298 L78 108 Z';

String _cuffs(String shade, String stroke) =>
    '<path d="M318 306 L352 298 L349 282 L315 290 Z M82 306 L48 298 L51 282 L85 290 Z" fill="$shade" stroke="$stroke" stroke-width="2.5"/>';

String _longSleeve(String color, String accent, String stroke, String shade, String style) =>
    _body('long', _longPath, color, stroke, accent, style) +
    '<path d="M163 87 Q200 122 237 87" fill="none" stroke="$stroke" stroke-width="6"/>' +
    _cuffs(shade, stroke) +
    _chestDetails(color, accent, stroke, style);

String _ribHem(String shade, String stroke, {double y = 308}) =>
    '<rect x="116" y="$y" width="168" height="${332 - y}" fill="$shade" stroke="$stroke" stroke-width="2.5"/>' +
    [
      for (var x = 124.0; x < 284; x += 9)
        '<line x1="$x" y1="${y + 3}" x2="$x" y2="329" stroke="$stroke" stroke-width="1" opacity=".35"/>',
    ].join();

String _sweatshirt(String color, String accent, String stroke, String shade, String style) =>
    _body('sweat', _longPath, color, stroke, accent, style, bandY: 200) +
    '<path d="M160 86 Q200 128 240 86" fill="none" stroke="$shade" stroke-width="12"/>'
        '<path d="M160 86 Q200 128 240 86" fill="none" stroke="$stroke" stroke-width="2.5"/>' +
    _cuffs(shade, stroke) +
    _ribHem(shade, stroke);

/// Las sudaderas infantiles se dibujan sin cordones (más seguras para niños).
String _hoodie(String color, String accent, String stroke, String shade, String style, {bool strings = true}) {
  const path =
      'M135 95 Q200 125 265 95 L322 112 L352 298 L318 306 L286 180 L286 332 L114 332 L114 180 L82 306 L48 298 L78 112 Z';
  final zip = style == 'zip';
  final front = zip
      ? '<line x1="200" y1="150" x2="200" y2="332" stroke="$stroke" stroke-width="4"/>'
          '<rect x="195" y="160" width="10" height="16" rx="2" fill="#c9c9c9" stroke="$stroke" stroke-width="1.5"/>'
          '<path d="M140 262 L162 238 M260 262 L238 238" stroke="$stroke" stroke-width="3"/>'
      : '<path d="M150 258 L250 258 L262 304 L138 304 Z" fill="$shade" stroke="$stroke" stroke-width="2.5"/>'
          '${strings ? '<line x1="188" y1="148" x2="185" y2="204" stroke="$_background" stroke-width="3"/>'
              '<line x1="212" y1="148" x2="215" y2="204" stroke="$_background" stroke-width="3"/>' : ''}';
  return _body('hood', path, color, stroke, accent, style) +
      '<path d="M145 102 Q150 40 200 38 Q250 40 255 102 Q230 152 200 152 Q170 152 145 102 Z" fill="$shade" stroke="$stroke" stroke-width="3"/>'
          '<path d="M166 106 Q200 136 234 106 Q228 80 200 78 Q172 80 166 106 Z" fill="${_mix(color, '#1d1d1d', 0.45)}"/>' +
      front +
      _cuffs(shade, stroke) +
      _ribHem(shade, stroke, y: 314);
}

String _jacket(String color, String accent, String stroke, String shade, String style) {
  final puffer = style == 'puffer';
  final quilting = puffer
      ? '<g clip-path="url(#jacket)">${[
          for (var y = 120.0; y < 332; y += 36)
            '<path d="M40 $y Q200 ${y + 8} 360 $y" fill="none" stroke="$stroke" stroke-width="2" opacity=".55"/>',
        ].join()}</g>'
      : '<path d="M132 250 L170 244 L170 262 L132 268 Z M268 250 L230 244 L230 262 L268 268 Z" fill="$shade" stroke="$stroke" stroke-width="2.5"/>';
  return _body('jacket', _longPath, color, stroke, accent, 'plain') +
      quilting +
      '<path d="M158 70 L242 70 L246 102 Q200 116 154 102 Z" fill="$shade" stroke="$stroke" stroke-width="3"/>'
          '<line x1="200" y1="108" x2="200" y2="332" stroke="$stroke" stroke-width="4"/>'
          '<rect x="195" y="114" width="10" height="16" rx="2" fill="#c9c9c9" stroke="$stroke" stroke-width="1.5"/>' +
      _cuffs(shade, stroke);
}

String _joggers(String color, String stroke, String shade) {
  const path = 'M132 92 L268 92 L280 318 L218 322 L200 168 L182 322 L120 318 Z';
  return '<path d="$path" fill="$color" stroke="$stroke" stroke-width="3"/>'
      '<rect x="128" y="66" width="144" height="30" rx="4" fill="$shade" stroke="$stroke" stroke-width="3"/>'
      '<path d="M192 96 Q186 128 180 140 M208 96 Q214 128 220 140" fill="none" stroke="${_mix(color, '#ffffff', 0.6)}" stroke-width="3"/>'
      '<path d="M150 104 Q160 140 142 150 M250 104 Q240 140 258 150" fill="none" stroke="$stroke" stroke-width="2.5"/>'
      '<path d="M120 318 L182 322 L183 340 L121 336 Z M218 322 L280 318 L279 336 L217 340 Z" fill="$shade" stroke="$stroke" stroke-width="2.5"/>';
}

String _onesie(String color, String accent, String stroke, String style) {
  const path =
      'M150 100 Q200 126 250 100 L304 124 L288 174 L262 166 L262 262 Q262 302 226 316 L222 338 L178 338 L174 316 Q138 302 138 262 L138 166 L112 174 L96 124 Z';
  return _body('onesie', path, color, stroke, accent, style, stripeGap: 30) +
      '<path d="M170 104 Q200 132 230 104" fill="none" stroke="$stroke" stroke-width="5"/>' +
      [for (final x in [186.0, 200.0, 214.0]) '<circle cx="$x" cy="328" r="3.5" fill="#d8d8d8" stroke="$stroke" stroke-width="1.5"/>'].join() +
      (style == 'print' ? _chestDetails(color, accent, stroke, 'print', cy: 206) : '');
}

String _beanie(String color, String stroke, String shade, String style) {
  final ribs = [
    for (var x = 124.0; x < 280; x += 12)
      '<line x1="$x" y1="236" x2="$x" y2="282" stroke="$stroke" stroke-width="1.5" opacity=".45"/>',
  ].join();
  final pompom = style == 'pompom'
      ? '<circle cx="200" cy="96" r="30" fill="${_mix(color, '#ffffff', 0.25)}" stroke="$stroke" stroke-width="3"/>'
      : '';
  return '$pompom<path d="M122 250 Q118 120 200 116 Q282 120 278 250 Z" fill="$color" stroke="$stroke" stroke-width="3"/>'
      '<path d="M160 130 Q150 190 152 240 M200 118 L200 240 M240 130 Q250 190 248 240" fill="none" stroke="$stroke" stroke-width="1.5" opacity=".35"/>'
      '<rect x="112" y="230" width="176" height="56" rx="14" fill="$shade" stroke="$stroke" stroke-width="3"/>$ribs';
}

String _cap(String color, String stroke, String shade) {
  final visor = _mix(color, '#1d1d1d', 0.08);
  return '<path d="M104 226 Q112 120 200 116 Q288 120 296 226 Z" fill="$color" stroke="$stroke" stroke-width="3"/>'
      '<path d="M200 117 L200 226 M150 130 Q140 180 146 226 M250 130 Q260 180 254 226" fill="none" stroke="$stroke" stroke-width="2"/>'
      '<circle cx="200" cy="117" r="7" fill="$shade" stroke="$stroke" stroke-width="2"/>'
      '<path d="M98 226 Q200 246 302 226 Q330 262 290 282 Q200 304 110 282 Q70 262 98 226 Z" fill="$visor" stroke="$stroke" stroke-width="3"/>'
      '<path d="M112 238 Q200 258 288 238" fill="none" stroke="$stroke" stroke-width="1.5" opacity=".4" stroke-dasharray="4 4"/>';
}
