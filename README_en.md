# Flutter Shop Admin · Web Demo

> [!IMPORTANT]
> **This is not the main Flutter Shop Admin repository.**
> It only contains the **web demo** published on my website.
> The full project (source code, the original version working against the REST API, and instructions to download and run the app) lives here:
>
> **[RaulEstevezA/Flutter_Shop_Admin](https://github.com/RaulEstevezA/Flutter_Shop_Admin)** · Backend: [RaulEstevezA/Flutter_Shop_Admin_Backend](https://github.com/RaulEstevezA/Flutter_Shop_Admin_Backend)

**Live demo:** [raulesteveza.github.io/demos/Flutter_Shop_Admin](https://raulesteveza.github.io/demos/Flutter_Shop_Admin/)

## Why this repository exists

Flutter Shop Admin is a Flutter mobile app to manage a shop's catalogue and stock against a REST API (NestJS + PostgreSQL) with JWT authentication. To showcase it on my website without running a server, this repository holds an adapted copy that:

1. **Needs no backend.** The API is simulated inside the app: initial data is bundled and every visitor's changes are stored only in their own browser.
2. **Runs in the browser**, published on GitHub Pages in the demos section of my website.
3. **Deploys itself**: every push to `main` runs the tests, builds the app and publishes it with GitHub Actions.

The architecture is the same as in the main repository (Clean Architecture, Riverpod, go_router, Formz). Thanks to the separation between domain and infrastructure, the change is limited to new datasources: the screens and app logic don't know there is no server.

## Trying it out

- **Test user:** `test1@example.com` · `Abc123`, or the "Entrar con el usuario de demo" button on the login screen.
- **Sign-up:** you can create new accounts; they only exist in your browser.
- **Products:** edit stock, prices, sizes or photos, or create new products. Changes survive a page reload.
- **Photos:** in the browser, gallery and camera open the file picker. Photos are resized to at most 1000 px and stored in the browser.
- **Reset:** the side menu has "Restablecer datos de la demo" to go back to the initial state.

## Differences from the original app

| | Original app ([Flutter_Shop_Admin](https://github.com/RaulEstevezA/Flutter_Shop_Admin)) | This demo |
|---|---|---|
| Backend | NestJS + PostgreSQL REST API ([backend](https://github.com/RaulEstevezA/Flutter_Shop_Admin_Backend)) | Simulated inside the app |
| Configuration | `.env` with `API_URL` | None |
| Authentication | Backend JWT | Users from `assets/data/users.json` + those registered in the browser |
| Data | Shared database | Bundled initial data; changes only in each visitor's browser |
| Photos | Uploaded to the backend | Stored in the browser |
| Main platform | Android / iOS | Web (also works on phones) |

This demo also:
- **Side menu:** shows the user's name and can reset the data.
- **Login and sign-up:** scroll on short screens instead of being cut off.
- **Desktop:** the catalogue and photo gallery can be dragged with the mouse.

## Demo data

The catalogue is **original**: 43 made-up products (names, descriptions, prices, sizes and stock), with no brands, and **illustrations drawn for this demo**. There are no third-party photos or texts, so nobody needs to be credited.

- It is defined in [`tool/catalog/catalog.json`](tool/catalog/catalog.json): each product includes how it is drawn (garment type, colour and style: stripes, band, pocket, print, zip, puffer or pompom).
- [`tool/generate_catalog.dart`](tool/generate_catalog.dart) draws the garments as SVG, converts them to WebP with headless Chrome and `cwebp`, and writes `assets/data/products.json`, `assets/data/users.json` and `assets/products/`:

```bash
dart run tool/generate_catalog.dart
```

Data can also be imported from an SQL dump of the backend with `tool/import_sql_dump.dart` (`--sql=dump.sql --images=photos/folder`). Note: the course's sample catalogue uses photos and texts from a real brand and must not be published.

## Relevant structure

Only what differs from the main repository:

```
assets/data/                       Initial data (products and users)
assets/products/                   Product photos
lib/features/shared/infrastructure/demo/
  demo_store.dart                  Simulated backend (initial data + browser changes)
  product_image.dart               Product images from any source (asset, browser, URL)
lib/features/auth/infrastructure/datasources/auth_datasource_demo.dart
lib/features/products/infrastructure/datasources/products_datasource_demo.dart
test/demo_backend_test.dart        Simulated backend tests
tool/catalog/catalog.json          Catalogue definition (products, users and illustrations)
tool/generate_catalog.dart         Catalogue and illustration generator
tool/import_sql_dump.dart          Optional importer for an SQL dump of the backend
showcase/index.html                Presentation page with the phone frame
.github/workflows/                 Tests, build and automatic deployment
```

## Running locally

```bash
flutter pub get
flutter run -d chrome
```

To see it exactly as published (phone-frame page with the app under `app/`):

```bash
flutter build web --release --base-href /demos/Flutter_Shop_Admin/app/

mkdir -p /tmp/site/demos/Flutter_Shop_Admin
cp -R showcase/. /tmp/site/demos/Flutter_Shop_Admin/
cp -R build/web /tmp/site/demos/Flutter_Shop_Admin/app
cd /tmp/site && python3 -m http.server 8000
# Open http://localhost:8000/demos/Flutter_Shop_Admin/
```

## Deployment

The [`deploy-demo.yml`](.github/workflows/deploy-demo.yml) workflow runs on every push to `main` (and manually from Actions):

1. Runs `flutter analyze` and `flutter test`.
2. Builds the web app with the `/demos/Flutter_Shop_Admin/app/` base path.
3. Copies `showcase/` and the built app into `demos/Flutter_Shop_Admin/` of the [RaulEstevezA.github.io](https://github.com/RaulEstevezA/RaulEstevezA.github.io) repository, which GitHub Pages serves.

It needs the `PORTFOLIO_DEPLOY_TOKEN` Actions secret: a fine-grained token with **Contents: Read and write** permission on `RaulEstevezA.github.io` only.

The website's `demos/Flutter_Shop_Admin/` folder is fully replaced on every deployment, so it must not be edited by hand.

## Credits

Project based on Fernando Herrera's **"Flutter de Cero a Experto"** course. Details are in the [main repository](https://github.com/RaulEstevezA/Flutter_Shop_Admin).

## Developer

**Raul Estevez**

- [Personal Website](https://raulesteveza.github.io/)
- [LinkedIn Profile](https://www.linkedin.com/in/raulesteveza/)

[Back to main README](./README.md)
