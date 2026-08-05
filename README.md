# Carrota

Asistente para tu negocio: registra ventas, lleva el inventario y prepara el cierre del día conversando con Lumo.

Hecho con Flutter (app) + Node.js sin dependencias (backend en `server/`).

## Funciones

- Ventas por chat
- Inventario y cierre de caja
- Resumen diario (Hoy), memoria del negocio y panel (Negocio)
- Feed de productos estilo TikTok Shop: likes, comentarios, guardar, compartir y agregar a tu venta
- Escáner de código de barras y cámara para recibir mercadería

## Arquitectura

- **`lib/`** — app Flutter. Con servidor conectado sincroniza catálogo, stock,
  ventas, entregas, memoria y compra sugerida; sin servidor funciona offline
  con datos de ejemplo.
- **`server/`** — API Node.js (`node:http` + `node:sqlite`, sin dependencias):
  Tienda, carrito, ventas (con deshacer), entregas, productos, resumen,
  insights, compra sugerida, cierre y eventos. Detalles en `server/README.md`.

## Empezar

```sh
# backend
node server/server.js

# app (en otra terminal)
flutter pub get
flutter run
```

La app se conecta por defecto a `http://192.168.1.33:4000`; sobreescribe con
`--dart-define=API_URL=http://127.0.0.1:4000`.

## Tests

```sh
npm test --prefix server   # backend (node --test, DB temporal)
flutter test               # app
```

## Licencia

MIT
