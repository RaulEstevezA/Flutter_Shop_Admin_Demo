import 'package:flutter_shop_admin/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_shop_admin/features/products/domain/domain.dart';


class ProductMapper {

  /// Carpeta de las fotos incluidas en la app (`tool/import_sql_dump.dart`).
  static const imagesPath = 'assets/products/';

  static jsonToEntity( Map<String, dynamic> json ) => Product(
    id: json['id'],
    title: json['title'],
    price: double.parse( json['price'].toString() ),
    description: json['description'],
    slug: json['slug'],
    stock: json['stock'],
    sizes: List<String>.from( json['sizes'].map( (size) => size )  ),
    gender: json['gender'],
    tags: List<String>.from( json['tags'].map( (tag) => tag )  ),
    images: List<String>.from( json['images'].map( toDisplay ) ),
    user: json['user'] == null ? null : UserMapper.userJsonToEntity( json['user'] )
  );

  /// Nombre de fichero guardado → ruta del asset. Las data URI (fotos subidas
  /// en la demo) y las URL se dejan tal cual.
  static String toDisplay( dynamic image ) {
    final value = image as String;
    if ( value.contains(':') || value.contains('/') ) return value;
    return '$imagesPath$value';
  }

  /// Inverso de [toDisplay], para guardar el producto.
  static String toStorage( String image ) => image.startsWith(imagesPath)
    ? image.substring(imagesPath.length)
    : image;

  /// Foto recién elegida con la cámara o la galería: ruta de fichero en móvil
  /// o URL `blob:` en web. Hay que leerla y guardarla antes de salvar.
  static bool isNewPhoto( String image ) =>
    image.startsWith('blob:') || image.startsWith('/') || image.startsWith('file:');
}
