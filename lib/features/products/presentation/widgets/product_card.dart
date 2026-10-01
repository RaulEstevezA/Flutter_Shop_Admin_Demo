import 'package:flutter/material.dart';
import 'package:flutter_shop_admin/features/products/domain/domain.dart';
import 'package:flutter_shop_admin/features/shared/infrastructure/demo/product_image.dart';


class ProductCard extends StatelessWidget {

  final Product product;

  const ProductCard({
    super.key, 
    required this.product
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ImageViewer( images: product.images ),
        Text( product.title, textAlign: TextAlign.center, ),
        const SizedBox(height: 20)
      ],
    );
  }
}


class _ImageViewer extends StatelessWidget {

  final List<String> images;

  const _ImageViewer({ required this.images });

  @override
  Widget build(BuildContext context) {
    
    // Imagen cuadrada: las ilustraciones del catálogo de la demo son cuadradas
    // y con una altura fija se recortaban por los lados en columnas estrechas.
    if ( images.isEmpty ) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.asset('assets/images/no-image.jpg', fit: BoxFit.cover),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1,
        child: FadeInImage(
          fit: BoxFit.cover,
          fadeOutDuration: const Duration(milliseconds: 100),
          fadeInDuration: const Duration(milliseconds: 200),
          image: productImageProvider( images.first ),
          placeholder: const AssetImage('assets/loaders/bottle-loader.gif'),
        ),
      ),
    );
  }
}