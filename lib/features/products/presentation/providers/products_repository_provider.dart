import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shop_admin/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_shop_admin/features/products/domain/domain.dart';
import 'package:flutter_shop_admin/features/products/infrastructure/datasources/products_datasource_demo.dart';
import 'package:flutter_shop_admin/features/products/infrastructure/repositories/products_repository_impl.dart';


final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  
  final user = ref.watch( authProvider ).user;

  final productsRepository = ProductsRepositoryImpl(
    ProductsDatasourceDemo(
      currentUser: user == null ? null : {
        'id': user.id,
        'email': user.email,
        'fullName': user.fullName,
        'roles': user.roles,
      },
    )
  );

  return productsRepository;
});