# Flutter Shop Admin · Demo web

> [!IMPORTANT]
> **Este no es el repositorio principal de Flutter Shop Admin.**
> Aquí solo está la **versión de demostración web** que se publica en mi web.
> El proyecto completo (código fuente, la versión original que trabaja contra la API REST e instrucciones para descargar y ejecutar la app) está en:
>
> **➡️ [RaulEstevezA/Flutter_Shop_Admin](https://github.com/RaulEstevezA/Flutter_Shop_Admin)** · Backend: [RaulEstevezA/Flutter_Shop_Admin_Backend](https://github.com/RaulEstevezA/Flutter_Shop_Admin_Backend)

**▶️ Demo en vivo:** [raulesteveza.github.io/demos/Flutter_Shop_Admin](https://raulesteveza.github.io/demos/Flutter_Shop_Admin/)

## Para qué sirve este repositorio

Flutter Shop Admin es una app móvil Flutter para gestionar el catálogo y el stock de una tienda contra una API REST (NestJS + PostgreSQL) con autenticación JWT. Para enseñarla en mi web sin tener que mantener un servidor, este repositorio contiene una copia adaptada que:

1. **No necesita backend.** La API se simula dentro de la app: los datos iniciales van incluidos y los cambios de cada visitante se guardan solo en su navegador.
2. **Funciona en el navegador**, publicada en GitHub Pages dentro de la sección de demos de mi web.
3. **Se despliega sola**: cada push a `main` ejecuta los tests, compila la app y la publica con GitHub Actions.

La arquitectura es la misma que en el repositorio principal (Clean Architecture, Riverpod, go_router, Formz). Gracias a la separación entre dominio e infraestructura, el cambio se limita a nuevos datasources: las pantallas y la lógica de la app no saben que no hay servidor.

## Cómo probarla

- **Usuario de prueba:** `test1@example.com` · `Abc123`, o el botón «Entrar con el usuario de demo» del login.
- **Registro:** se pueden crear cuentas nuevas; solo existen en tu navegador.
- **Productos:** edita stock, precios, tallas o fotos, o crea productos nuevos. Los cambios sobreviven a recargar la página.
- **Fotos:** en el navegador, la galería y la cámara abren el selector de archivos. Las fotos se reducen a 1000 px como máximo y se guardan en el navegador.
- **Restablecer:** el menú lateral tiene «Restablecer datos de la demo» para volver al estado inicial.

## Diferencias con la app original

| | App original ([Flutter_Shop_Admin](https://github.com/RaulEstevezA/Flutter_Shop_Admin)) | Esta demo |
|---|---|---|
| Backend | API REST NestJS + PostgreSQL ([backend](https://github.com/RaulEstevezA/Flutter_Shop_Admin_Backend)) | Simulado dentro de la app |
| Configuración | `.env` con `API_URL` | Ninguna |
| Autenticación | JWT del backend | Usuarios de `assets/data/users.json` + registrados en el navegador |
| Datos | Base de datos compartida | Datos iniciales incluidos; cambios solo en el navegador de cada visitante |
| Fotos | Se suben al backend | Se guardan en el navegador |
| Plataforma principal | Android / iOS | Web (también funciona en móvil) |

Además, en esta demo:
- **Menú lateral:** muestra el nombre del usuario y permite restablecer los datos.
- **Login y registro:** se pueden desplazar en pantallas bajas, en vez de quedar cortados.
- **Escritorio:** el catálogo y la galería se pueden arrastrar con el ratón.

## Datos de la demo

El catálogo es **propio**: 43 productos inventados (nombres, descripciones, precios, tallas y stock), sin marcas, con **ilustraciones dibujadas para esta demo**. No hay fotos ni textos de terceros, así que no hay que acreditar a nadie.

- La definición está en [`tool/catalog/catalog.json`](tool/catalog/catalog.json): cada producto incluye cómo se dibuja (tipo de prenda, color y estilo: rayas, franja, bolsillo, estampado, cremallera, acolchado o pompón).
- [`tool/generate_catalog.dart`](tool/generate_catalog.dart) dibuja las prendas en SVG, las convierte a WebP con Chrome headless y `cwebp`, y escribe `assets/data/products.json`, `assets/data/users.json` y `assets/products/`:

```bash
dart run tool/generate_catalog.dart
```

También se pueden importar los datos de un volcado SQL del backend con `tool/import_sql_dump.dart` (`--sql=volcado.sql --images=carpeta/de/fotos`). Ojo: el catálogo de ejemplo del curso usa fotos y textos de una marca real y no debe publicarse.

## Estructura relevante

Solo lo que cambia respecto al repositorio principal:

```
assets/data/                       Datos iniciales (productos y usuarios)
assets/products/                   Fotos de los productos
lib/features/shared/infrastructure/demo/
  demo_store.dart                  Backend simulado (datos iniciales + cambios en el navegador)
  product_image.dart               Imágenes de producto de cualquier origen (asset, navegador, URL)
lib/features/auth/infrastructure/datasources/auth_datasource_demo.dart
lib/features/products/infrastructure/datasources/products_datasource_demo.dart
test/demo_backend_test.dart        Tests del backend simulado
tool/catalog/catalog.json          Definición del catálogo (productos, usuarios e ilustraciones)
tool/generate_catalog.dart         Generador del catálogo y de las ilustraciones
tool/import_sql_dump.dart          Importador de un volcado SQL del backend (opcional)
showcase/index.html                Página de presentación con el marco de móvil
.github/workflows/                 Tests, compilación y despliegue automático
```

## Ejecutar en local

```bash
flutter pub get
flutter run -d chrome
```

Para verlo exactamente como queda publicado (página con el marco de móvil y la app en `app/`):

```bash
flutter build web --release --base-href /demos/Flutter_Shop_Admin/app/

mkdir -p /tmp/site/demos/Flutter_Shop_Admin
cp -R showcase/. /tmp/site/demos/Flutter_Shop_Admin/
cp -R build/web /tmp/site/demos/Flutter_Shop_Admin/app
cd /tmp/site && python3 -m http.server 8000
# Abrir http://localhost:8000/demos/Flutter_Shop_Admin/
```

## Despliegue

El workflow [`deploy-demo.yml`](.github/workflows/deploy-demo.yml) se ejecuta en cada push a `main` (y manualmente desde Actions):

1. Ejecuta `flutter analyze` y `flutter test`.
2. Compila la app para web con la ruta `/demos/Flutter_Shop_Admin/app/`.
3. Copia `showcase/` y la app compilada en `demos/Flutter_Shop_Admin/` del repositorio [RaulEstevezA.github.io](https://github.com/RaulEstevezA/RaulEstevezA.github.io), que GitHub Pages publica.

Necesita el secreto de Actions `PORTFOLIO_DEPLOY_TOKEN`: un token *fine-grained* con permiso **Contents: Read and write** solo sobre `RaulEstevezA.github.io`.

La carpeta `demos/Flutter_Shop_Admin/` de la web se sustituye entera en cada despliegue, así que no debe editarse a mano.

## Créditos

Proyecto basado en el curso **«Flutter de Cero a Experto»** de Fernando Herrera. Los detalles están en el [repositorio principal](https://github.com/RaulEstevezA/Flutter_Shop_Admin).

## Desarrollador

**Raul Estevez**

- [Web personal](https://raulesteveza.github.io/)
- [LinkedIn](https://www.linkedin.com/in/raulesteveza/)

[Volver al README principal](./README.md)
