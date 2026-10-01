# Flutter Shop Admin · Web Demo

> [!IMPORTANT]
> **This is not the main Flutter Shop Admin repository.**
> This repository only contains the **web demo** published on my website.
> The full project (source code, the original version working against the REST API, and instructions to download and run the app) lives here:
>
> **[RaulEstevezA/Flutter_Shop_Admin](https://github.com/RaulEstevezA/Flutter_Shop_Admin)** · Backend: [RaulEstevezA/Flutter_Shop_Admin_Backend](https://github.com/RaulEstevezA/Flutter_Shop_Admin_Backend)

**Live demo:** [raulesteveza.github.io/demos/Flutter_Shop_Admin](https://raulesteveza.github.io/demos/Flutter_Shop_Admin/)

- 🇬🇧 **English:** [About this demo repository](./README_en.md)
- 🇪🇸 **Español:** [Sobre este repositorio de demo](./README_es.md)

## What is this repository?

A copy of Flutter Shop Admin adapted to run **in the browser, on GitHub Pages, without a backend**:

- The NestJS + PostgreSQL REST API is replaced by a **backend simulated inside the app**: initial data is bundled with the app and every visitor's changes (edited or new products, registered users, uploaded photos) are stored **only in their own browser**.
- A demo user is offered on the login screen, and the side menu can **reset the demo data**.
- The app is shown inside a **phone frame** on desktop and full screen on mobile.
- Every push to `main` is **built and deployed automatically** to my website with GitHub Actions.

The app architecture (Clean Architecture, Riverpod, go_router, Formz) is the same as in the main repository. Only the datasources and some web-specific details change.

## Developer

**Raul Estevez**

- [Personal Website](https://raulesteveza.github.io/)
- [LinkedIn Profile](https://www.linkedin.com/in/raulesteveza/)
