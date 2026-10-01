import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Backend simulado de la demo web.
///
/// Sustituye a la API REST: los datos iniciales se leen de `assets/data/`
/// (generados con `tool/import_sql_dump.dart`) y los cambios de cada visitante
/// (productos editados o creados, usuarios registrados) se guardan en su
/// navegador con shared_preferences. `reset()` vuelve a los datos iniciales.
class DemoStore {

  static final DemoStore instance = DemoStore._();

  DemoStore._({ AssetBundle? bundle }) : _bundle = bundle ?? rootBundle;

  /// Constructor para tests, con un bundle de assets propio.
  DemoStore.withBundle( AssetBundle bundle ) : _bundle = bundle;

  /// Usuario de prueba que se ofrece en la pantalla de login (`assets/data/users.json`).
  static const demoEmail = 'test1@google.com';
  static const demoPassword = 'Abc123';

  static const _productsKey = 'demo_products';
  static const _usersKey = 'demo_users';

  final AssetBundle _bundle;

  List<Map<String, dynamic>>? _products;
  List<Map<String, dynamic>>? _users;


  Future<List<Map<String, dynamic>>> _loadSeed( String file, String key ) async {
    final raw = await _bundle.loadString('assets/data/$file', cache: false);
    return List<Map<String, dynamic>>.from( json.decode(raw)[key] );
  }

  Future<List<Map<String, dynamic>>?> _loadSaved( String key ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if ( raw == null ) return null;
    return List<Map<String, dynamic>>.from( json.decode(raw) );
  }

  Future<void> _save( String key, List<Map<String, dynamic>> value ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(key, json.encode(value));
    if ( !saved ) throw StateError('No se pudieron guardar los cambios en el navegador');
  }


  // --- Usuarios ---

  Future<List<Map<String, dynamic>>> users() async {
    if ( _users != null ) return _users!;
    final seed = await _loadSeed('users.json', 'users');
    final registered = await _loadSaved(_usersKey) ?? [];
    return _users = [ ...seed, ...registered ];
  }

  Future<Map<String, dynamic>> addUser( Map<String, dynamic> user ) async {
    final all = await users();
    all.add(user);

    final seedCount = (await _loadSeed('users.json', 'users')).length;
    await _save(_usersKey, all.sublist(seedCount));
    return user;
  }


  // --- Productos ---

  Future<List<Map<String, dynamic>>> products() async {
    return _products ??= await _loadSaved(_productsKey)
      ?? await _loadSeed('products.json', 'products');
  }

  /// Crea (sin `id`) o actualiza un producto y lo guarda en el navegador.
  Future<Map<String, dynamic>> saveProduct( Map<String, dynamic> product ) async {
    final all = await products();
    final index = all.indexWhere((element) => element['id'] == product['id']);

    final updated = [ ...all ];
    if ( index == -1 ) {
      updated.add(product);
    } else {
      updated[index] = product;
    }

    // Solo se actualiza la memoria si el navegador acepta el guardado
    // (puede fallar si las fotos subidas superan el espacio disponible).
    await _save(_productsKey, updated);
    _products = updated;
    return product;
  }


  /// Borra los cambios del visitante y vuelve a los datos iniciales.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_productsKey);
    await prefs.remove(_usersKey);
    _products = null;
    _users = null;
  }


  static String newId() =>
    '${ DateTime.now().microsecondsSinceEpoch.toRadixString(16) }-demo';
}
