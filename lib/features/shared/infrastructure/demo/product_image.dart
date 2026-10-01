import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';


final Map<String, ImageProvider> _memoryImages = {};

/// ImageProvider para una imagen de producto de la demo:
/// - `assets/...`: foto incluida en la app.
/// - `data:...`: foto subida por el visitante y guardada en el navegador.
/// - `http(s):` / `blob:`: URL (en web, también las fotos recién elegidas).
/// - Cualquier otra cosa: ruta de fichero en móvil.
ImageProvider productImageProvider( String image ) {
  if ( image.startsWith('assets/') ) return AssetImage(image);

  if ( image.startsWith('data:') ) {
    // Se reutiliza la instancia para que Flutter no vuelva a decodificarla en cada build.
    return _memoryImages.putIfAbsent(
      image,
      () => MemoryImage( UriData.parse(image).contentAsBytes() ),
    );
  }

  if ( kIsWeb || image.startsWith('http') ) return NetworkImage(image);

  return FileImage( File(image) );
}
