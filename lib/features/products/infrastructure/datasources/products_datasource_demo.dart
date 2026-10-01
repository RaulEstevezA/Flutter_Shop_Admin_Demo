import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_shop_admin/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_shop_admin/features/products/domain/domain.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/demo_store.dart';
import '../errors/product_errors.dart';
import '../mappers/product_mapper.dart';


/// Productos de la demo web: sin backend, contra `assets/data/products.json`
/// y los cambios guardados en el navegador del visitante.
class ProductsDatasourceDemo extends ProductsDatasource {

  final DemoStore store;
  final Map<String, dynamic>? currentUser;

  ProductsDatasourceDemo({ DemoStore? store, this.currentUser })
    : store = store ?? DemoStore.instance;


  /// Las fotos nuevas llegan como ruta de fichero (móvil) o URL `blob:` (web).
  /// Se guardan como data URI para que sobrevivan al recargar la página.
  Future<String> _storePhoto( String image ) async {
    if ( !ProductMapper.isNewPhoto(image) ) return image;

    final file = XFile(image);
    final bytes = await file.readAsBytes();
    final mimeType = file.mimeType ?? 'image/jpeg';
    return 'data:$mimeType;base64,${ base64Encode(bytes) }';
  }

  @override
  Future<Product> createUpdateProduct(Map<String, dynamic> productLike) async {
    try {
      final String? productId = productLike['id'];
      final products = await store.products();
      final existing = products.where((product) => product['id'] == productId).firstOrNull;

      final product = await store.saveProduct({
        ...?existing,
        ...productLike,
        'id': productId ?? DemoStore.newId(),
        'images': await Future.wait(
          List<String>.from(productLike['images']).map(_storePhoto)
        ),
        'user': existing?['user'] ?? currentUser,
      });

      return ProductMapper.jsonToEntity(product);

    } catch (e) {
      throw CustomError('No se pudo guardar el producto');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    final products = await store.products();
    final product = products.where((product) => product['id'] == id).firstOrNull;
    if ( product == null ) throw ProductNotFound();

    return ProductMapper.jsonToEntity(product);
  }

  @override
  Future<List<Product>> getProductsByPage({int limit = 10, int offset = 0}) async {
    final products = await store.products();
    return products
      .skip(offset)
      .take(limit)
      .map((product) => ProductMapper.jsonToEntity(product) as Product)
      .toList();
  }

  @override
  Future<List<Product>> searchProductByTerm(String term) async {
    final query = term.trim().toLowerCase();
    if ( query.isEmpty ) return [];

    final products = await store.products();
    return products
      .where((product) =>
        (product['title'] as String).toLowerCase().contains(query) ||
        List<String>.from(product['tags']).any((tag) => tag.toLowerCase().contains(query))
      )
      .map((product) => ProductMapper.jsonToEntity(product) as Product)
      .toList();
  }
}
