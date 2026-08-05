# Carrota API

Backend completo de la app Carrota: Tienda (estilo TikTok Shop), ventas,
inventario, entregas, resumen del día, insights y cierre de caja.

Sin dependencias: usa solo `node:http` y `node:sqlite` (Node 22.5+).

## Correr

```sh
node server.js          # o: npm start
```

Escucha en `http://0.0.0.0:4000`. La base de datos se crea sola en `data.db`
con datos de ejemplo. Variables de entorno:

| Variable | Por defecto | Descripción |
| --- | --- | --- |
| `PORT` | `4000` | Puerto (`0` = puerto aleatorio) |
| `DB_PATH` | `./data.db` | Ruta del archivo SQLite |

## Tests

```sh
npm test                # node --test (usa una DB temporal)
```

## Endpoints

### Salud
| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/api/health` | Estado del servidor |

### Tienda (feed, likes, comentarios)
| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/api/feed` | Feed de videos (stock, likes, comentarios, liked/saved) |
| POST | `/api/videos/:id/like` | Alterna like |
| POST | `/api/videos/:id/save` | Alterna guardado |
| GET | `/api/videos/:id/comments` | Lista comentarios |
| POST | `/api/videos/:id/comments` | Agrega comentario `{text}` |

### Carrito
| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/api/cart` | Carrito (items, count, total) |
| POST | `/api/cart` | Agrega `{productId, qty}` (no excede stock) |
| PUT | `/api/cart/:id` | Cambia cantidad `{qty}` (0 elimina) |
| DELETE | `/api/cart/:id` | Elimina línea |
| DELETE | `/api/cart` | Vacía carrito |

### Productos e inventario
| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/api/products` | Catálogo completo |
| GET | `/api/products/:id` | Un producto |
| GET | `/api/products/barcode/:code` | Busca por código de barras |
| POST | `/api/products` | Crea producto `{id?, name, unit, price, stock, emoji, supplier, avg_daily, barcode}` |
| PUT | `/api/products/:id` | Actualiza campos parciales |
| POST | `/api/products/:id/stock` | Ajusta stock `{delta}` (puede ser negativo) |

### Ventas
| Método | Ruta | Descripción |
| --- | --- | --- |
| POST | `/api/sales` | Registra venta con `{lines: [{product_id, qty}], payment, authCode}`; sin `lines` usa el carrito |
| GET | `/api/sales` | Últimas 50 ventas con sus líneas |
| DELETE | `/api/sales/:id` | Deshace la venta (restaura stock e inventario) |

`payment` válido: `efectivo | tarjeta | transferencia | combinado` (por defecto `efectivo`).

### Entregas
| Método | Ruta | Descripción |
| --- | --- | --- |
| POST | `/api/deliveries` | Registra entrega `{supplier, total, lines}`; suma stock y crea eventos |

### Resumen / insights / compra / cierre / memoria
| Método | Ruta | Descripción |
| --- | --- | --- |
| GET | `/api/summary` | Ventas del día, por método, top productos, caja, alertas, valor de inventario |
| GET | `/api/insights` | Productos con stock bajo y recomendación de recompra |
| GET | `/api/shopping` | Lista de compra sugerida para mañana |
| POST | `/api/closing` | Cierre del día `{note?}`; guarda snapshot y eventos |
| GET | `/api/closes` | Cierres recientes |
| GET | `/api/events?type=tl|mem` | Timeline o memoria del negocio |
| GET | `/api/business` | Métricas del negocio (moneda, inventario, ventas 30 días) |

## App Flutter

La app usa `API_URL` (dart-define) para conectarse; por defecto
`http://192.168.1.33:4000`. Si el servidor no responde, la app funciona
offline con datos locales.
