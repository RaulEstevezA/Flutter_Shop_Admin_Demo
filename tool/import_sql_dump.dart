// Convierte un volcado de PostgreSQL del backend de Flutter Shop Admin
// (formato `pg_dump`, bloques `COPY ... FROM stdin`) en los datos estáticos de
// la demo web:
//
//   assets/data/products.json   productos con sus imágenes y su usuario
//   assets/data/users.json      usuarios activos (todos con la contraseña de demo)
//   assets/products/            fotos referenciadas por los productos
//
// Uso:
//   dart run tool/import_sql_dump.dart --sql=ruta/al/volcado.sql --images=ruta/a/static/products
//     [--password=Abc123] [--out=.]
//
// Las contraseñas del volcado están cifradas con bcrypt y no se pueden
// recuperar, así que todos los usuarios importados usan `--password`.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = {
    'password': 'Abc123',
    'out': '.',
    for (final arg in args.where((a) => a.startsWith('--') && a.contains('=')))
      arg.substring(2, arg.indexOf('=')): arg.substring(arg.indexOf('=') + 1),
  };

  final sqlPath = options['sql'];
  if (sqlPath == null) {
    stderr.writeln('Uso: dart run tool/import_sql_dump.dart --sql=volcado.sql [--images=carpeta] [--password=Abc123] [--out=.]');
    exit(64);
  }

  final tables = _parseCopyBlocks(File(sqlPath).readAsStringSync());
  for (final table in ['products', 'product_images', 'users']) {
    if (!tables.containsKey(table)) {
      stderr.writeln('El volcado no contiene la tabla "$table"');
      exit(65);
    }
  }

  // Usuarios (sin la contraseña cifrada).
  final users = {
    for (final row in tables['users']!)
      if (row['isActive'] != 'f')
        row['id']: {
          'id': row['id'],
          'email': row['email']!.toLowerCase(),
          'fullName': row['fullName'],
          'roles': _parseArray(row['roles']),
        },
  };

  // Imágenes por producto, en orden de inserción.
  final imagesByProduct = <String, List<String>>{};
  final imageRows = [...tables['product_images']!]
    ..sort((a, b) => int.parse(a['id']!).compareTo(int.parse(b['id']!)));
  for (final row in imageRows) {
    imagesByProduct.putIfAbsent(row['productId']!, () => []).add(row['url']!);
  }

  final products = [
    for (final row in tables['products']!)
      {
        'id': row['id'],
        'title': row['title'],
        'price': num.parse(row['price']!),
        'description': row['description'] ?? '',
        'slug': row['slug'],
        'stock': int.parse(row['stock']!),
        'sizes': _parseArray(row['sizes']),
        'gender': row['gender'],
        'tags': _parseArray(row['tags']),
        'images': imagesByProduct[row['id']] ?? <String>[],
        'user': users[row['userId']],
      },
  ];

  final outDir = options['out']!;
  final dataDir = Directory('$outDir/assets/data')..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  File('${dataDir.path}/products.json').writeAsStringSync(encoder.convert({'products': products}));
  File('${dataDir.path}/users.json').writeAsStringSync(encoder.convert({
    'users': [
      for (final user in users.values) {...user, 'password': options['password']},
    ],
  }));

  // Fotos: se copian solo las referenciadas, sustituyendo las anteriores.
  var copied = 0;
  final missing = <String>[];
  final imagesDir = options['images'];
  if (imagesDir != null) {
    final productsDir = Directory('$outDir/assets/products');
    if (productsDir.existsSync()) productsDir.deleteSync(recursive: true);
    productsDir.createSync(recursive: true);

    for (final image in {for (final list in imagesByProduct.values) ...list}) {
      final source = File('$imagesDir/$image');
      if (source.existsSync()) {
        source.copySync('${productsDir.path}/$image');
        copied++;
      } else {
        missing.add(image);
      }
    }
  }

  stdout.writeln('Listo: ${products.length} productos, ${users.length} usuarios, $copied imágenes copiadas.');
  if (missing.isNotEmpty) stdout.writeln('Imágenes no encontradas (${missing.length}): ${missing.take(10).join(', ')}');
  if (imagesDir == null) stdout.writeln('Sin --images: no se han copiado fotos.');
}

/// Bloques `COPY public.tabla (col1, col2) FROM stdin;` → filas como mapas.
Map<String, List<Map<String, String?>>> _parseCopyBlocks(String sql) {
  final tables = <String, List<Map<String, String?>>>{};
  final header = RegExp(r'^COPY (?:\w+\.)?"?(\w+)"? \((.+)\) FROM stdin;$');
  final lines = const LineSplitter().convert(sql);

  for (var i = 0; i < lines.length; i++) {
    final match = header.firstMatch(lines[i]);
    if (match == null) continue;

    final columns = match[2]!.split(',').map((c) => c.trim().replaceAll('"', '')).toList();
    final rows = <Map<String, String?>>[];
    for (i++; i < lines.length && lines[i] != r'\.'; i++) {
      final values = lines[i].split('\t').map(_unescape).toList();
      rows.add({for (var c = 0; c < columns.length; c++) columns[c]: c < values.length ? values[c] : null});
    }
    tables[match[1]!] = rows;
  }
  return tables;
}

/// Escapes del formato de texto de COPY; `\N` es NULL.
String? _unescape(String value) {
  if (value == r'\N') return null;
  return value.replaceAllMapped(RegExp(r'\\(.)'), (m) => switch (m[1]) {
        'n' => '\n',
        't' => '\t',
        'r' => '\r',
        _ => m[1]!,
      });
}

/// Array de PostgreSQL: `{a,b,"c d"}` → `[a, b, c d]`.
List<String> _parseArray(String? value) {
  if (value == null || value.length < 2) return [];
  final body = value.substring(1, value.length - 1);
  if (body.isEmpty) return [];

  final items = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (var i = 0; i < body.length; i++) {
    final char = body[i];
    if (char == '\\' && i + 1 < body.length) {
      buffer.write(body[++i]);
    } else if (char == '"') {
      quoted = !quoted;
    } else if (char == ',' && !quoted) {
      items.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  items.add(buffer.toString());
  return items;
}
