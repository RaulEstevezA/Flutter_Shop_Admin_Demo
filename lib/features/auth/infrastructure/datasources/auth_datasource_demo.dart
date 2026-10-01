import 'package:flutter_shop_admin/features/auth/domain/domain.dart';
import 'package:flutter_shop_admin/features/auth/infrastructure/infrastructure.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/demo_store.dart';


/// Autenticación de la demo web: sin backend, contra los usuarios de
/// `assets/data/users.json` y los registrados en el navegador del visitante.
class AuthDataSourceDemo extends AuthDataSource {

  static const _tokenPrefix = 'demo-token:';

  final DemoStore store;

  AuthDataSourceDemo({ DemoStore? store }) : store = store ?? DemoStore.instance;


  User _toUser( Map<String, dynamic> json ) => UserMapper.userJsonToEntity({
    ...json,
    'token': '$_tokenPrefix${ json['id'] }',
  });

  @override
  Future<User> checkAuthStatus(String token) async {
    if ( !token.startsWith(_tokenPrefix) ) throw CustomError('Token incorrecto');

    final id = token.substring(_tokenPrefix.length);
    final users = await store.users();
    final user = users.where((user) => user['id'] == id).firstOrNull;
    if ( user == null ) throw CustomError('Token incorrecto');

    return _toUser(user);
  }

  @override
  Future<User> login(String email, String password) async {
    final users = await store.users();
    final user = users.where(
      (user) => user['email'] == email.trim().toLowerCase() && user['password'] == password
    ).firstOrNull;

    if ( user == null ) throw CustomError('Credenciales incorrectas');
    return _toUser(user);
  }

  @override
  Future<User> register(String email, String password, String fullName) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await store.users();
    if ( users.any((user) => user['email'] == normalizedEmail) ) {
      throw CustomError('Ya existe una cuenta con ese correo');
    }

    final user = await store.addUser({
      'id': DemoStore.newId(),
      'email': normalizedEmail,
      'password': password,
      'fullName': fullName.trim(),
      'roles': ['user'],
    });

    return _toUser(user);
  }
}
