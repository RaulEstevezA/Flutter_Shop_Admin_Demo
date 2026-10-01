import 'package:flutter/material.dart';
import 'package:flutter_shop_admin/features/products/domain/domain.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/product_image.dart';


typedef SearchProductsCallback = Future<List<Product>> Function( String term );

class SearchProductDelegate extends SearchDelegate<Product?> {

  final SearchProductsCallback searchProducts;

  SearchProductDelegate({ required this.searchProducts });

  @override
  String get searchFieldLabel => 'Buscar producto';

  // Sin esto el campo hereda titleLarge del tema (40px en negrita) y no cabe.
  @override
  TextStyle? get searchFieldStyle => const TextStyle( fontSize: 18 );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if ( query.isNotEmpty )
        IconButton(
          onPressed: () => query = '',
          icon: const Icon( Icons.clear )
        )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon( Icons.arrow_back_ios_new_rounded )
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    if ( query.trim().isEmpty ) return const SizedBox();

    return FutureBuilder<List<Product>>(
      future: searchProducts( query ),
      builder: (context, snapshot) {
        if ( snapshot.connectionState != ConnectionState.done ) {
          return const Center( child: CircularProgressIndicator( strokeWidth: 2 ) );
        }

        final products = snapshot.data ?? [];
        if ( products.isEmpty ) {
          return const Center( child: Text('No se encontraron productos') );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: product.images.isEmpty
                    ? Image.asset('assets/images/no-image.jpg', fit: BoxFit.cover)
                    : Image( image: productImageProvider( product.images.first ), fit: BoxFit.cover ),
                ),
              ),
              title: Text( product.title ),
              subtitle: Text('\$${ product.price }'),
              onTap: () => close(context, product),
            );
          },
        );
      },
    );
  }
}
