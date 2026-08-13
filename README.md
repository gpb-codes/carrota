<div align="center">

  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:151B24,30:4EC983,60:1C8742,85:E1A035,100:00BCC5&height=200&section=header&text=CARROTA&fontSize=48&fontColor=1C8742&animation=fadeIn&fontAlignY=35&desc=ASISTENTE%20PARA%20TU%20NEGOCIO%20%7C%20VENTAS%20%7C%20INVENTARIO%20%7C%20CIERRE%20DE%20DIA&descSize=14&descAlignY=55&descAlign=center" width="100%" />

  <br/>

  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=18&duration=3000&pause=1000&color=1C8742&center=true&vCenter=true&multiline=true&repeat=true&width=600&height=100&lines=Registra+ventas+conversando+con+Lumo;Inventario+y+cierre+de+caja+sin+esfuerzo;Feed+de+productos+estilo+TikTok+Shop" alt="Typing SVG" />

  <br/>

  <a href="https://github.com/gpb-codes/carrota">
    <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" />
  </a>
  <a href="https://img.shields.io/badge/Flutter-1C8742?logo=flutter&logoColor=white&style=for-the-badge">
    <img src="https://img.shields.io/badge/Flutter-1C8742?style=for-the-badge&logo=flutter&logoColor=white" />
  </a>
  <a href="https://img.shields.io/badge/Node.js-00BCC5?style=for-the-badge&logo=nodedotjs&logoColor=white">
    <img src="https://img.shields.io/badge/Node.js-00BCC5?style=for-the-badge&logo=nodedotjs&logoColor=white" />
  </a>
  <a href="https://img.shields.io/badge/MIT-4EC983?style=for-the-badge">
    <img src="https://img.shields.io/badge/MIT-4EC983?style=for-the-badge" />
  </a>

</div>

<br/>

---

## ¿Qué es Carrota?

> Un **asistente para tu negocio**: registras ventas, llevas el inventario y preparas el cierre del día conversando con **Lumo**.

Carrota reemplaza la libreta, el cuaderno de deudas y la hoja de cálculo. La app funciona **offline** con datos de ejemplo y, cuando hay un servidor conectado, sincroniza catálogo, stock, ventas, entregas, memoria y compra sugerida.

<br/>

---

## Características

### Lumo — asistente conversacional

Conversa para registrar ventas, consultar precios, deudas y resúmenes. Lumo recuerda tu negocio: clientes, productos y movimientos.

- Onboarding conversacional en tres etapas (`businessName → businessType → completed`), con validación, envío por botón o teclado y autoscroll.
- Ventas por chat: escribís "vendí dos tomates y una lechuga" y Lumo prepara la propuesta con pago (efectivo, tarjeta o transferencia) y **deshacer**.
- Respuestas por voz, cámara para documentos y escáner de código de barras integrado.

### Tienda — feed estilo TikTok Shop

- Feed de productos con likes, comentarios, guardar y compartir.
- Agregá productos directo a tu venta desde el feed.
- Scanner de códigos de barras.

### Inventario

- Control de stock y estado de cada producto.
- Recibí mercadería con la cámara o con el escáner.
- **Compra sugerida**: el servidor te dice qué comprar según el ritmo de ventas (insights de stock bajo).

### Cierre y negocio

- Resumen diario (Hoy): ventas, métodos de pago, caja, top productos y alertas.
- Memoria del negocio y timeline de eventos.
- Panel (Negocio) para cerrar el día en segundos.

<br/>

---

## Stack tecnológico

| | | | | | | | |
|---|---|---|---|---|---|---|---|
| <img src="https://skillicons.dev/icons?i=flutter" width="48" /><br/>Flutter | <img src="https://skillicons.dev/icons?i=dart" width="48" /><br/>Dart | <img src="https://skillicons.dev/icons?i=nodejs" width="48" /><br/>Node.js | <img src="https://skillicons.dev/icons?i=sqlite" width="48" /><br/>SQLite | <img src="https://skillicons.dev/icons?i=android" width="48" /><br/>Android | <img src="https://skillicons.dev/icons?i=git" width="48" /><br/>Git | <img src="https://skillicons.dev/icons?i=github" width="48" /><br/>GitHub | <img src="https://skillicons.dev/icons?i=npm" width="48" /><br/>npm |

> Backend en **Node.js puro** — `node:http` + `node:sqlite`, cero dependencias.

<br/>

---

## Arquitectura

| # | Componente | Descripción |
|---|---|---|
| 01 | **App Flutter** | Multiplataforma (Android + web). Con servidor conectado sincroniza catálogo, stock, ventas, entregas, memoria y compra sugerida; sin servidor funciona offline con datos de ejemplo. |
| 02 | **API Node.js** | `node:http` + `node:sqlite` sin dependencias: tienda, carrito, ventas (con deshacer), entregas, productos, resumen, insights, compra sugerida, cierre y eventos. |
| 03 | **SQLite local** | Base de datos embebida con datos de ejemplo iniciales; los tests usan una DB temporal. |
| 04 | **Lumo (IA)** | Asistente conversacional con memoria del negocio: clientes, productos y movimientos. |

<br/>

---

## Estructura del proyecto

```text
carrota/
├── lib/                          # App Flutter
│   ├── main.dart                 # Punto de entrada
│   ├── app/                      # Shell, tema y widgets compartidos
│   │   ├── app.dart              # CarrotaApp + _Shell (navegación por pestañas)
│   │   ├── theme.dart            # Paleta, tipografías y ThemeData
│   │   └── widgets/              # brand, composer, bottom_nav, sheet
│   ├── core/                     # Estado global y datos
│   │   ├── store.dart            # LumoStore (chat, ventas, carrito, inventario)
│   │   ├── api.dart              # Cliente HTTP del backend
│   │   ├── data.dart             # Datos de ejemplo
│   │   └── mock_ai.dart          # Intención y parseo de ventas
│   └── features/                 # Funcionalidad por dominio
│       ├── onboarding/           # Bienvenida conversacional (etapas, provider, widgets)
│       ├── home/                 # Inicio (chat con Lumo)
│       ├── hoy/                  # Resumen diario
│       ├── tienda/               # Feed estilo TikTok Shop
│       ├── memoria/              # Memoria del negocio
│       ├── negocio/              # Panel y cierre
│       └── sheets/               # Cartas: carrito, cierre, cámara, scanner, voz, etc.
├── server/                       # API Node.js (cero dependencias)
│   ├── server.js                 # Servidor + SQLite
│   └── test/server.test.js
└── test/                         # Pruebas de la app
    ├── core_test.dart
    └── features/onboarding/      # provider + pantalla de bienvenida
```

<br/>

---

## Requisitos

| Herramienta | Versión |
|---|---|
| Flutter | 3.44 (Dart 3.12) |
| Node.js | 22.5 o superior (para `node:sqlite`) |

<br/>

---

## Puesta en marcha

### 1. Levantar el backend

```sh
node server/server.js
```

Escucha en `http://0.0.0.0:4000` y crea la base `server/data.db` sola con datos de ejemplo. Variables de entorno: `PORT` (por defecto `4000`) y `DB_PATH` (por defecto `./data.db`).

### 2. Correr la app

```sh
flutter pub get
flutter run
```

La app se conecta por defecto a `http://192.168.1.33:4000`. Si tu servidor corre en esta máquina, sobreescribí el destino en el arranque:

```sh
flutter run --dart-define=API_URL=http://127.0.0.1:4000
```

Si el servidor no responde, la app sigue funcionando offline con datos locales.

<br/>

---

## Pruebas y calidad

```sh
flutter analyze                       # análisis estático, debe quedar sin avisos
dart format --output=none --set-exit-if-changed lib test   # formato
flutter test                          # pruebas de la app
npm test --prefix server              # backend (node --test, DB temporal)
```

> **42 tests** — 21 backend + 21 app.

**Regla práctica:** una tarea no está terminada solo porque la pantalla "se ve bien"; debe pasar formato, análisis, pruebas y una ejecución manual del flujo principal.

<br/>

---

## Onboarding conversacional

La primera vez que abre la app, **Lumo** conversa para conocer tu negocio en un flujo de tres etapas: `businessName → businessType → completed`.

```text
lib/features/onboarding/
├── models/
│   ├── chat_message_model.dart      # MessageType + ChatMessage (la burbuja depende del tipo)
│   └── onboarding_step.dart         # etapas del flujo
├── provider/
│   └── conversation_provider.dart   # máquina de estados + submitAnswer + validación
├── screens/
│   └── welcome_screen.dart          # coordina proveedor, scroll y acción final
└── widgets/
    ├── onboarding_input.dart        # campo + botón (no conoce el proveedor)
    ├── chat_bubble.dart             # Lumo a la izquierda, usuario a la derecha
    └── lumo_header.dart             # cabecera de marca
```

### Decisiones de diseño

- El estado vive en `ConversationProvider` (`ChangeNotifier`); los widgets solo reciben datos y callbacks, y la pantalla escucha con `ListenableBuilder` — sin dependencias extra.
- `submitAnswer` descarta respuestas vacías con un mensaje de validación y transita por un `switch` sobre `OnboardingStep`; al completar, el campo se reemplaza por la acción final.
- La lista de mensajes se entrega como `List.unmodifiable` (no se puede mutar desde afuera); el chat se autodesplaza al último mensaje y el envío funciona con botón y con la tecla `Done` del teclado.
- Las burbujas se limitan al 76% del ancho de pantalla, adaptándose de 360 a 1024 px.

<br/>

---

## API de Carrota (resumen)

| Grupo | Endpoints principales |
|---|---|
| Salud | `GET /api/health` |
| Tienda | `GET /api/feed` · `POST /api/videos/:id/like` · `POST /api/videos/:id/save` · `GET|POST /api/videos/:id/comments` |
| Carrito | `GET|POST /api/cart` · `PUT|DELETE /api/cart/:id` · `DELETE /api/cart` |
| Productos | `GET|POST /api/products` · `GET|PUT /api/products/:id` · `GET /api/products/barcode/:code` · `POST /api/products/:id/stock` |
| Ventas | `POST|GET /api/sales` · `DELETE /api/sales/:id` (deshacer) |
| Entregas | `POST /api/deliveries` |
| Análisis | `GET /api/summary` · `GET /api/insights` · `GET /api/shopping` · `POST /api/closing` · `GET /api/closes` · `GET /api/events` · `GET /api/business` |

Detalle completo en [`server/README.md`](server/README.md).

<br/>

---

## Roadmap

### Hecho
- [x] App Flutter multiplataforma (Android + web)
- [x] API Node.js sin dependencias con SQLite
- [x] Onboarding conversacional con máquina de estados y pruebas
- [x] Feed de productos estilo TikTok Shop
- [x] Escáner de código de barras y cámara para mercadería
- [x] Carrito, ventas con deshacer, entregas y cierre
- [x] Resumen diario, memoria del negocio y panel

### En desarrollo
- [ ] Instalación en dispositivo Android (Redmi Note 9)
- [ ] Sincronización multi-dispositivo
- [ ] Insights y compra sugerida avanzados
- [ ] Persistencia local del onboarding (no repetir la bienvenida en cada reinicio)

<br/>

---

## Contacto

<div align="center">

| | | |
|---|---|---|
| <a href="https://github.com/gpb-codes/carrota"><img src="https://img.shields.io/badge/Repos-181717?style=for-the-badge&logo=github&logoColor=white" /></a> | <a href="https://github.com/gpb-codes"><img src="https://img.shields.io/badge/Gabriel_Pedreros-151B24?style=for-the-badge&logo=code&logoColor=white" /></a> | <img src="https://img.shields.io/badge/MIT-4EC983?style=for-the-badge" /> |

</div>

<br/>

---

<div align="center">

  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:151B24,25:4EC983,50:1C8742,75:E1A035,100:00BCC5&height=100&section=footer&text=VENDES%2C+LUMO+LLEVA+LA+CUENTA&fontSize=14&fontColor=4EC983&animation=fadeIn" width="100%" />

  <br/>

  <sub>**v1.1** · Actualizado 2026 · Operacional</sub>

</div>