import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_shop_admin/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_shop_admin/features/products/infrastructure/infrastructure.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/demo_store.dart';


class _MemoryAssetBundle extends CachingAssetBundle {
  final Map<String, Object> files;

  _MemoryAssetBundle(this.files);

  @override
  Future<ByteData> load(String key) async {
    final file = files[key];
    if (file == null) throw Exception('Unable to load asset: $key');
    return ByteData.sublistView(utf8.encode(json.encode(file)));
  }
}

const _admin = {'id': 'u1', 'email': 'test1@example.com', 'fullName': 'Juan Carlos', 'roles': ['admin']};

Map<String, dynamic> _product(int i) => {
  'id': 'p$i',
  'title': 'Producto $i',
  'price': 10 + i,
  'description': 'Descripción $i',
  'slug': 'producto_$i',
  'stock': i,
  'sizes': ['M'],
  'gender': 'men',
  'tags': ['camiseta'],
  'images': ['foto$i.jpg'],
  'user': _admin,
};

void main() {
  late DemoStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = DemoStore.withBundle(_MemoryAssetBundle({
      'assets/data/users.json': {
        'users': [{..._admin, 'password': 'Abc123'}],
      },
      'assets/data/products.json': {
        'products': List.generate(12, (i) => _product(i + 1)),
      },
    }));
  });

  group('AuthDataSourceDemo', () {
    test('login con credenciales correctas devuelve el usuario con token', () async {
      final user = await AuthDataSourceDemo(store: store).login('Test1@example.com ', 'Abc123');

      expect(user.fullName, 'Juan Carlos');
      expect(user.isAdmin, isTrue);
      expect(user.token, isNotEmpty);
    });

    test('login con contraseña incorrecta lanza CustomError', () {
      expect(AuthDataSourceDemo(store: store).login('test1@example.com', 'mala'), throwsA(isA<CustomError>()));
    });

    test('register crea el usuario, permite comprobar su token y evita duplicados', () async {
      final datasource = AuthDataSourceDemo(store: store);
      final user = await datasource.register('ana@demo.com', 'Demo123', 'Ana');

      expect((await datasource.checkAuthStatus(user.token)).email, 'ana@demo.com');
      expect(datasource.register('ANA@demo.com', 'Demo123', 'Ana'), throwsA(isA<CustomError>()));
    });

    test('checkAuthStatus rechaza tokens desconocidos', () {
      expect(AuthDataSourceDemo(store: store).checkAuthStatus('otro'), throwsA(isA<CustomError>()));
    });
  });

  group('ProductsDatasourceDemo', () {
    test('pagina los productos y convierte las fotos en rutas de assets', () async {
      final datasource = ProductsDatasourceDemo(store: store);

      final firstPage = await datasource.getProductsByPage(limit: 10, offset: 0);
      final secondPage = await datasource.getProductsByPage(limit: 10, offset: 10);

      expect(firstPage, hasLength(10));
      expect(secondPage, hasLength(2));
      expect(firstPage.first.images, ['assets/products/foto1.jpg']);
    });

    test('actualizar un producto lo guarda y conserva su usuario', () async {
      final datasource = ProductsDatasourceDemo(store: store);

      await datasource.createUpdateProduct({
        'id': 'p1',
        ..._product(1)..remove('user'),
        'stock': 42,
        'images': ['foto1.jpg', 'data:image/jpeg;base64,AAAA'],
      });

      final product = await datasource.getProductById('p1');
      expect(product.stock, 42);
      expect(product.user?.fullName, 'Juan Carlos');
      expect(product.images.last, 'data:image/jpeg;base64,AAAA');
    });

    test('crear un producto le asigna id y el usuario actual', () async {
      final datasource = ProductsDatasourceDemo(store: store, currentUser: _admin);

      final created = await datasource.createUpdateProduct({
        'id': null,
        ..._product(99)..remove('id')..remove('user'),
      });

      expect(created.id, isNotEmpty);
      expect(created.user?.email, 'test1@example.com');
      expect((await datasource.getProductsByPage(limit: 20)).length, 13);
    });

    test('reset vuelve a los datos iniciales', () async {
      final datasource = ProductsDatasourceDemo(store: store);
      await datasource.createUpdateProduct({..._product(1)..remove('user'), 'stock': 42});

      await store.reset();

      expect((await datasource.getProductById('p1')).stock, 1);
    });

    test('busca por título y etiquetas', () async {
      final datasource = ProductsDatasourceDemo(store: store);

      expect((await datasource.searchProductByTerm('producto 1')).map((p) => p.id), ['p1', 'p10', 'p11', 'p12']);
      expect(await datasource.searchProductByTerm('camiseta'), hasLength(12));
    });
  });

  test('ProductMapper distingue fotos nuevas de las ya guardadas', () {
    expect(ProductMapper.isNewPhoto('blob:http://localhost/abc'), isTrue);
    expect(ProductMapper.isNewPhoto('/data/user/0/cache/foto.jpg'), isTrue);
    expect(ProductMapper.isNewPhoto('assets/products/foto.jpg'), isFalse);
    expect(ProductMapper.isNewPhoto('data:image/jpeg;base64,AAAA'), isFalse);
    expect(ProductMapper.toStorage('assets/products/foto.jpg'), 'foto.jpg');
  });
}
