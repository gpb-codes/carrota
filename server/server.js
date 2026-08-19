// Carrota API — backend completo de la app.
// Sin dependencias: usa solo node:http y node:sqlite (Node 22.5+).
//
// Env:
//   PORT     puerto (por defecto 4000; usa 0 para un puerto aleatorio)
//   DB_PATH  ruta de la base (por defecto ./data.db)
//   LUMO_API_KEY   API key para POST /api/lumo (LLM real). Sin key, el
//                  endpoint responde { power: false } y la app cae al
//                  parser local (mock_ai).
//   LUMO_BASE_URL  base url OpenAI-compatible (por defecto
//                  https://api.openai.com/v1). Puede apuntar a Ollama, etc.
//   LUMO_MODEL     modelo (por defecto gpt-4o-mini)
//
// Cobertura:
//   - Tienda (feed estilo TikTok Shop, likes, comentarios, carrito)
//   - Productos e inventario (catálogo, barcode, ajustes de stock)
//   - Ventas (desde líneas o carrito) y deshacer venta
//   - Entregas de mercadería
//   - Resumen del día, insights, compra sugerida, cierre de caja
//   - Memoria y timeline (eventos)

const http = require('node:http');
const path = require('node:path');
const fs = require('node:fs');
const crypto = require('node:crypto');
const { DatabaseSync } = require('node:sqlite');

const PORT = Number(process.env.PORT) || 4000;
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'data.db');
const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, 'uploads');
const MAX_UPLOAD_BYTES = Number(process.env.MAX_UPLOAD_BYTES) || 30 * 1024 * 1024;
const LUMO_API_KEY = process.env.LUMO_API_KEY || '';
const LUMO_BASE_URL = process.env.LUMO_BASE_URL || 'https://api.openai.com/v1';
const LUMO_MODEL = process.env.LUMO_MODEL || 'gpt-4o-mini';
const db = new DatabaseSync(DB_PATH);

db.exec(`
  PRAGMA journal_mode = WAL;

  CREATE TABLE IF NOT EXISTS products (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, unit TEXT NOT NULL,
    price INTEGER NOT NULL, stock INTEGER NOT NULL, emoji TEXT NOT NULL,
    supplier TEXT, avg_daily INTEGER, barcode TEXT
  );

  CREATE TABLE IF NOT EXISTS videos (
    product_id TEXT PRIMARY KEY REFERENCES products(id),
    caption TEXT NOT NULL, hashtags TEXT NOT NULL,
    c1 INTEGER NOT NULL, c2 INTEGER NOT NULL, base_likes INTEGER NOT NULL,
    url TEXT, owner TEXT, created_at TEXT
  );

  CREATE TABLE IF NOT EXISTS video_state (
    product_id TEXT PRIMARY KEY REFERENCES products(id),
    liked INTEGER NOT NULL DEFAULT 0, saved INTEGER NOT NULL DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS comments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id TEXT NOT NULL REFERENCES products(id),
    author TEXT NOT NULL, initial TEXT NOT NULL, text TEXT NOT NULL,
    created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS cart (
    product_id TEXT PRIMARY KEY REFERENCES products(id),
    qty INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS sales (
    id TEXT PRIMARY KEY, total INTEGER NOT NULL, payment TEXT NOT NULL,
    auth_code TEXT, at TEXT NOT NULL, created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS sale_lines (
    sale_id TEXT NOT NULL REFERENCES sales(id),
    product_id TEXT NOT NULL, qty INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS deliveries (
    id TEXT PRIMARY KEY, supplier TEXT, total INTEGER,
    at TEXT NOT NULL, created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS delivery_lines (
    delivery_id TEXT NOT NULL REFERENCES deliveries(id),
    product_id TEXT NOT NULL, qty INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY, kind TEXT NOT NULL, title TEXT NOT NULL,
    detail TEXT, tag TEXT, at TEXT NOT NULL, created_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS closes (
    id TEXT PRIMARY KEY, total INTEGER NOT NULL, ops INTEGER NOT NULL,
    cash INTEGER NOT NULL, card INTEGER NOT NULL, transfer INTEGER NOT NULL,
    combined INTEGER NOT NULL, note TEXT, at TEXT NOT NULL,
    created_at TEXT NOT NULL
  );
`);

// Migraciones ligeras por si existe una DB creada por una versión anterior.
const ensureColumn = (table, column, ddl) => {
  const cols = db.prepare(`PRAGMA table_info(${table})`).all().map((c) => c.name);
  if (!cols.includes(column)) db.exec(`ALTER TABLE ${table} ADD COLUMN ${ddl}`);
};
ensureColumn('products', 'barcode', 'barcode TEXT');
ensureColumn('sales', 'created_at', 'created_at TEXT');
ensureColumn('videos', 'url', 'url TEXT');
ensureColumn('videos', 'owner', 'owner TEXT');
ensureColumn('videos', 'created_at', 'created_at TEXT');

if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const H = 3600 * 1000;
const DAY = 24 * H;

const seed = () => {
  const products = [
    ['tomate', 'Tomate saladet', 'kg', 30, 42, '🍅', 'Huerto Norte', 12, '7501055300017'],
    ['lechuga', 'Lechuga italiana', 'pieza', 28, 4, '🥬', 'Huerto Norte', 6, '7501055300024'],
    ['zanahoria', 'Zanahoria', 'kg', 20, 18, '🥕', 'Milpa Verde', 5, '7501055300031'],
    ['cilantro', 'Cilantro', 'manojo', 12, 3, '🌿', 'Milpa Verde', 8, '7501055300048'],
    ['espinaca', 'Espinaca', 'bolsa', 28, 14, '🥗', 'Huerto Norte', 6, '7501055300055'],
    ['aguacate', 'Aguacate', 'kg', 55, 22, '🥑', 'Milpa Verde', 4, '7501055300062'],
    ['limon', 'Limón', 'kg', 32, 30, '🍋', 'Cítricos del Bajío', 7, '7501055300079'],
    ['mermelada', 'Mermelada artesanal', 'frasco', 95, 12, '🍯', 'Taller La Abeja', 2, '7501055300086'],
  ];
  const videos = [
    ['aguacate', 'Aguacate de Milpa Verde. Cremoso y listo para hoy.', '#aguacate,#fresco,#milpaverde', 0xFF9BC94C, 0xFF2F6B2F, 2104],
    ['tomate', 'Tomate saladet recién llegado de Huerto Norte.', '#tomate,#huertonorte,#saladet', 0xFFE5533D, 0xFF8F1D10, 1240],
    ['limon', 'Limón amarillo, perfecto para la limonada de la tarde.', '#limon,#citricosdelbajio', 0xFFF5D23C, 0xFFC77D0F, 678],
    ['lechuga', 'Lechuga italiana fresca y crujiente, sin pesticidas.', '#lechuga,#verde,#italiana', 0xFF7BC26B, 0xFF24663A, 856],
    ['mermelada', 'Mermelada artesanal del Taller La Abeja.', '#mermelada,#artesanal,#laabeja', 0xFFE8A64A, 0xFF8F4E17, 342],
    ['zanahoria', 'Zanahoria dulce, perfecta para el caldo de la semana.', '#zanahoria,#fresco', 0xFFF59E3C, 0xFFC54813, 512],
  ];
  const comments = [
    ['aguacate', 'Luis', 'L', 'El mejor aguacate de la zona 🥑', 1],
    ['aguacate', 'Karen', 'K', '¿Hacen envíos a la colonia Centro?', 3],
    ['tomate', 'María', 'M', '¿El kilo sigue a $30? 🙌', 2],
    ['tomate', 'Chef Ana', 'A', 'El de la semana pasada estaba muy bueno', 5],
    ['lechuga', 'Don Pepe', 'D', 'Fresca, la llevo cada martes', 4],
    ['limon', 'Sofía', 'S', 'Perfecto para la limonada de la tarde 🍋', 6],
  ];

  const insert = db.prepare(
    'INSERT INTO products (id, name, unit, price, stock, emoji, supplier, avg_daily, barcode) VALUES (?,?,?,?,?,?,?,?,?)');
  for (const p of products) insert.run(...p);

  const insertV = db.prepare(
    'INSERT INTO videos (product_id, caption, hashtags, c1, c2, base_likes) VALUES (?,?,?,?,?,?)');
  for (const v of videos) insertV.run(...v);

  const insertC = db.prepare(
    'INSERT INTO comments (product_id, author, initial, text, created_at) VALUES (?,?,?,?,?)');
  const now = Date.now();
  for (const [pid, author, initial, text, hoursAgo] of comments) {
    insertC.run(pid, author, initial, text, new Date(now - hoursAgo * H).toISOString());
  }

  // Eventos base (timeline + memoria), espejo del seed de la app.
  const ev = db.prepare(
    'INSERT INTO events (id, kind, title, detail, tag, at, created_at) VALUES (?,?,?,?,?,?,?)');
  const iso = (ms) => new Date(ms).toISOString();
  ev.run('e1', 'tl', 'Cierre diario preparado.', 'Ventas totales: $8,250.', 'Cierre', '18:42', iso(now - DAY));
  ev.run('e2', 'tl', 'Llegaron 20 kg de tomate de Huerto Norte.', null, 'Inventario', '17:15', iso(now));
  ev.run('e3', 'tl', 'Venta con tarjeta por $280.', 'Autorización: 683194.', 'Venta', '16:38', iso(now));
  ev.run('e4', 'tl', 'El precio de la lechuga cambió de $25 a $28.', null, 'Precio', '14:20', iso(now));
  ev.run('e5', 'tl', 'El cilantro llegó a nivel crítico.', null, 'Alerta', '11:05', iso(now));
  ev.run('m1', 'mem', 'Registraste una entrada de 20 kg de tomate de Huerto Norte.',
    'Factura por $1,450. Se actualizó el inventario automáticamente.', 'Registrado', '17:15', iso(now));
  ev.run('m2', 'mem', 'Cambiaste el precio de la lechuga de $25 a $28.',
    'El cambio se aplicó a todas las ventas siguientes.', 'Registrado', '12:00', iso(now - 2 * DAY));
  ev.run('m3', 'mem', 'Las ventas de cilantro aumentaron 18 %.',
    'Comparado con la semana anterior.', 'Calculado', '10:00', iso(now - 7 * DAY));
  ev.run('m4', 'Patrón observado', 'Normalmente recibes mercadería los lunes y jueves.',
    'He notado este patrón en las últimas 6 semanas.', 'Patrón observado', '08:00', iso(now - DAY));
};

const count = db.prepare('SELECT COUNT(*) AS n FROM products').get().n;
if (count === 0) {
  db.exec('BEGIN');
  try {
    seed();
    db.exec('COMMIT');
  } catch (e) {
    db.exec('ROLLBACK');
    throw e;
  }
}

// ---------- helpers ----------

const PAYMENTS = ['efectivo', 'tarjeta', 'transferencia', 'combinado'];

const ago = (iso) => {
  const diff = Date.now() - new Date(iso).getTime();
  const m = Math.floor(diff / 60000);
  if (m < 1) return 'ahora';
  if (m < 60) return `hace ${m} min`;
  const h = Math.floor(m / 60);
  if (h < 24) return `hace ${h} h`;
  const d = Math.floor(h / 24);
  return d === 1 ? 'hace 1 día' : `hace ${d} días`;
};

const timeNow = () => {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

const mxn = (n) => {
  const s = Math.abs(n).toString();
  let out = '';
  for (let i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 === 0) out += ',';
    out += s[i];
  }
  return `${n < 0 ? '-' : ''}$${out}`;
};

const isToday = (iso) => new Date(iso).toDateString() === new Date().toDateString();

const mapProduct = (p) => ({
  id: p.id,
  name: p.name,
  unit: p.unit,
  price: p.price,
  stock: p.stock,
  emoji: p.emoji,
  supplier: p.supplier,
  avgDaily: p.avg_daily,
  barcode: p.barcode,
});

const productById = (id) => db.prepare('SELECT * FROM products WHERE id = ?').get(id);
const productName = (id) => productById(id)?.name || id;
const stockOf = (id) => productById(id)?.stock || 0;

const VIDEO_SELECT = `SELECT p.*, v.caption, v.hashtags, v.c1, v.c2, v.base_likes,
                             v.url, v.owner, v.created_at,
                             COALESCE(s.liked, 0) AS liked, COALESCE(s.saved, 0) AS saved
                      FROM videos v JOIN products p ON p.id = v.product_id
                      LEFT JOIN video_state s ON s.product_id = v.product_id`;

const commentCount = db.prepare('SELECT COUNT(*) AS n FROM comments WHERE product_id = ?');

const rowToVideo = (r) => ({
  productId: r.id,
  name: r.name,
  unit: r.unit,
  price: r.price,
  stock: r.stock,
  emoji: r.emoji,
  supplier: r.supplier,
  caption: r.caption,
  hashtags: r.hashtags ? r.hashtags.split(',') : [],
  c1: r.c1,
  c2: r.c2,
  likes: r.base_likes + r.liked,
  comments: commentCount.get(r.id).n,
  liked: r.liked === 1,
  saved: r.saved === 1,
  url: r.url,
  owner: r.owner,
  createdAt: r.created_at,
});

const videoRow = (id) => db.prepare(`${VIDEO_SELECT} WHERE v.product_id = ?`).get(id);

const videoPayload = (id) => {
  const r = videoRow(id);
  return r ? rowToVideo(r) : null;
};

const feed = () =>
  db.prepare(`${VIDEO_SELECT} ORDER BY v.base_likes DESC`).all().map(rowToVideo);

const cartItems = () =>
  db
    .prepare(`SELECT c.product_id AS productId, c.qty,
                     p.name, p.price, p.unit, p.emoji
              FROM cart c JOIN products p ON p.id = c.product_id`)
    .all();

const cartTotal = () =>
  db
    .prepare(`SELECT COALESCE(SUM(c.qty * p.price), 0) AS t
              FROM cart c JOIN products p ON p.id = c.product_id`)
    .get().t;

const cartPayload = () => ({
  items: cartItems(),
  count: cartItems().reduce((a, i) => a + i.qty, 0),
  total: cartTotal(),
});

/// Parsea body.lines → [{productId, qty}], valida productos y fusiona repetidos.
/// Devuelve null si no hay líneas, o { error } si un producto no existe.
const parseLines = (body) => {
  const raw = Array.isArray(body?.lines) ? body.lines : [];
  if (raw.length === 0) return null;
  const merged = {};
  for (const l of raw) {
    const pid = l?.product_id || l?.productId;
    if (typeof pid !== 'string' || !pid) return { error: 'each line needs product_id/productId' };
    if (!productById(pid)) return { error: `unknown product: ${pid}` };
    const qty = Math.max(1, parseInt(l?.qty, 10) || 1);
    merged[pid] = (merged[pid] || 0) + qty;
  }
  return Object.entries(merged).map(([productId, qty]) => ({ productId, qty }));
};

const totalOfLines = (lines) =>
  lines.reduce((acc, l) => acc + (productById(l.productId)?.price || 0) * l.qty, 0);

const salesList = () => {
  const rows = db
    .prepare('SELECT id, total, payment, auth_code, at, created_at FROM sales ORDER BY created_at DESC, rowid DESC LIMIT 50')
    .all();
  const lineStmt = db.prepare('SELECT product_id, qty FROM sale_lines WHERE sale_id = ?');
  return rows.map((s) => ({
    id: s.id,
    total: s.total,
    payment: s.payment,
    authCode: s.auth_code,
    at: s.at,
    lines: lineStmt.all(s.id).map((l) => ({ productId: l.product_id, qty: l.qty })),
  }));
};

const todaySales = () =>
  db.prepare('SELECT * FROM sales').all().filter((s) => isToday(s.created_at));

const summary = () => {
  const sales = todaySales();
  const total = sales.reduce((a, s) => a + s.total, 0);
  const byPayment = { efectivo: 0, tarjeta: 0, transferencia: 0, combinado: 0 };
  for (const s of sales) byPayment[s.payment] = (byPayment[s.payment] || 0) + s.total;

  const ids = sales.map((s) => s.id);
  const byProd = {};
  if (ids.length) {
    const ph = ids.map(() => '?').join(',');
    const lines = db.prepare(`SELECT product_id, qty FROM sale_lines WHERE sale_id IN (${ph})`).all(...ids);
    for (const l of lines) byProd[l.product_id] = (byProd[l.product_id] || 0) + l.qty;
  }
  const topProducts = Object.entries(byProd)
    .map(([productId, qty]) => {
      const p = productById(productId);
      return { productId, name: p?.name || productId, emoji: p?.emoji || null, qty };
    })
    .sort((a, b) => b.qty - a.qty)
    .slice(0, 5);

  const products = db.prepare('SELECT * FROM products').all();
  const lowStock = products.filter((p) => p.avg_daily && p.stock < p.avg_daily);

  return {
    date: new Date().toISOString().slice(0, 10),
    salesTotal: total,
    salesCount: sales.length,
    byPayment,
    cash: byPayment.efectivo,
    topProducts,
    openAuth: sales.filter((s) => s.payment === 'tarjeta' && !s.auth_code).length,
    inventoryValue: products.reduce((a, p) => a + p.stock * p.price, 0),
    lowStockCount: lowStock.length,
  };
};

const insights = () => {
  const out = [];
  for (const p of db.prepare('SELECT * FROM products').all()) {
    const avg = p.avg_daily || 0;
    if (p.stock === 0) {
      out.push({
        productId: p.id, name: p.name, emoji: p.emoji, stock: 0, avgDaily: avg, daysLeft: 0,
        urgency: 'critical',
        reason: 'Sin existencias.',
        recommendation: `Comprar ${Math.max(avg, 6)} ${p.unit}${avg ? ' (vendes ' + avg + '/día)' : ''}`,
      });
    } else if (avg > 0 && p.stock < avg) {
      const restock = Math.max(avg * 2 - p.stock, avg);
      out.push({
        productId: p.id, name: p.name, emoji: p.emoji, stock: p.stock, avgDaily: avg,
        daysLeft: +(p.stock / avg).toFixed(1), urgency: 'low',
        reason: `Quedan ${p.stock} ${p.unit} y normalmente vendes ${avg} por día.`,
        recommendation: `Comprar ${restock} ${p.unit}`,
      });
    }
  }
  return out.sort((a, b) => a.daysLeft - b.daysLeft);
};

const addEvent = (kind, title, detail, tag) => {
  db.prepare('INSERT INTO events (id, kind, title, detail, tag, at, created_at) VALUES (?,?,?,?,?,?,?)')
    .run(
      `ev${Date.now().toString(36)}${Math.floor(Math.random() * 1296).toString(36)}`,
      kind, title, detail || null, tag || null, timeNow(), new Date().toISOString());
};

const groupOf = (kind, created_at) => {
  if (kind === 'Patrón observado') return 'Patrón observado';
  const d = new Date(created_at);
  const now = new Date();
  const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const startEv = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diff = Math.round((startToday - startEv) / DAY);
  if (diff <= 0) return 'Hoy';
  if (diff === 1) return 'Ayer';
  if (diff <= 7) return `Hace ${diff} días`;
  if (diff <= 14) return 'La semana pasada';
  return `Hace ${diff} días`;
};

const whenOf = (e) => {
  const g = groupOf(e.kind, e.created_at);
  if (g === 'Hoy') return e.at;
  if (g === 'Ayer') return 'ayer';
  if (g === 'Patrón observado') return 'patrón';
  const m = g.match(/^Hace (\d+) días$/);
  if (m) return `hace ${m[1]} días`;
  if (g === 'La semana pasada') return 'la semana pasada';
  return g;
};

const eventsList = (type) => {
  let rows;
  if (type === 'tl') {
    rows = db.prepare("SELECT * FROM events WHERE kind = 'tl' ORDER BY created_at DESC, rowid DESC").all();
  } else if (type === 'mem') {
    rows = db.prepare("SELECT * FROM events WHERE kind IN ('mem', 'Patrón observado') ORDER BY created_at DESC, rowid DESC").all();
  } else {
    rows = db.prepare('SELECT * FROM events ORDER BY created_at DESC, rowid DESC').all();
  }
  return rows.map((e) =>
    e.kind === 'tl'
      ? { id: e.id, time: e.at, title: e.title, detail: e.detail, tag: e.tag }
      : {
          id: e.id,
          when: whenOf(e),
          group: groupOf(e.kind, e.created_at),
          title: e.title,
          detail: e.detail,
          kind: e.kind,
        });
};

const business = () => {
  const products = db.prepare('SELECT * FROM products').all();
  const sales = db.prepare('SELECT * FROM sales').all();
  const since = Date.now() - 30 * DAY;
  const last30 = sales.filter((s) => new Date(s.created_at).getTime() >= since);
  return {
    name: 'Carrota',
    tagline: 'Huerto urbano y sostenible',
    currency: 'MXN',
    timezone: 'CDMX',
    productCount: products.length,
    inventoryValue: products.reduce((a, p) => a + p.stock * p.price, 0),
    sales30d: last30.reduce((a, s) => a + s.total, 0),
    salesCount30d: last30.length,
    lowStockCount: products.filter((p) => p.avg_daily && p.stock < p.avg_daily).length,
  };
};

const videoExists = (id) => !!db.prepare('SELECT 1 FROM videos WHERE product_id = ?').get(id);

function send(res, code, body) {
  const payload = JSON.stringify(body);
  res.writeHead(code, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(payload);
}

function readBody(req, limit = 1e6) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (c) => {
      raw += c;
      if (raw.length > limit) reject(new Error('body too large'));
    });
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch {
        reject(new Error('bad json'));
      }
    });
    req.on('error', reject);
  });
}

// ---------- subida de archivos (videos de la tienda) ----------

const UPLOAD_EXTS = new Set(['mp4', 'webm', 'mov', 'm4v']);
const MIME_BY_EXT = {
  mp4: 'video/mp4',
  webm: 'video/webm',
  mov: 'video/quicktime',
  m4v: 'video/mp4',
};

const extOf = (filename) => {
  const m = String(filename || '').toLowerCase().match(/\.([a-z0-9]+)$/);
  return m && UPLOAD_EXTS.has(m[1]) ? m[1] : null;
};

const saveUpload = (base64, filename) => {
  const ext = extOf(filename);
  if (!ext) return { error: `unsupported extension (allowed: ${[...UPLOAD_EXTS].join(', ')})` };
  const buf = Buffer.from(String(base64 || ''), 'base64');
  if (buf.length === 0) return { error: 'empty file' };
  if (buf.length > MAX_UPLOAD_BYTES) return { error: `file too large (max ${Math.round(MAX_UPLOAD_BYTES / 1e6)} MB)` };
  const name = `vid_${Date.now().toString(36)}_${crypto.randomBytes(3).toString('hex')}.${ext}`;
  fs.writeFileSync(path.join(UPLOAD_DIR, name), buf);
  return { url: `/uploads/${name}` };
};

const routes = [
  // ---------- salud ----------
  ['GET', /^\/api\/health$/, async () => ({ ok: true, uptime: process.uptime() })],

  // ---------- tienda: feed / like / save / comentarios ----------
  ['GET', /^\/api\/feed$/, async () => ({ videos: feed() })],

  ['POST', /^\/api\/videos\/([^/]+)\/like$/, async (_, m) => {
    const id = m[1];
    if (!videoExists(id)) return { error: 'video not found', status: 404 };
    const cur = db.prepare('SELECT liked FROM video_state WHERE product_id = ?').get(id);
    const liked = cur ? !cur.liked : true;
    db.prepare(`INSERT INTO video_state (product_id, liked) VALUES (?, ?)
                ON CONFLICT(product_id) DO UPDATE SET liked = excluded.liked`).run(id, liked ? 1 : 0);
    const base = db.prepare('SELECT base_likes FROM videos WHERE product_id = ?').get(id).base_likes;
    return { liked, likes: base + (liked ? 1 : 0) };
  }],

  ['POST', /^\/api\/videos\/([^/]+)\/save$/, async (_, m) => {
    const id = m[1];
    if (!videoExists(id)) return { error: 'video not found', status: 404 };
    const cur = db.prepare('SELECT saved FROM video_state WHERE product_id = ?').get(id);
    const saved = cur ? !cur.saved : true;
    db.prepare(`INSERT INTO video_state (product_id, saved) VALUES (?, ?)
                ON CONFLICT(product_id) DO UPDATE SET saved = excluded.saved`).run(id, saved ? 1 : 0);
    return { saved };
  }],

  ['GET', /^\/api\/videos\/([^/]+)\/comments$/, async (_, m) => {
    if (!videoExists(m[1])) return { error: 'video not found', status: 404 };
    return {
      comments: db
        .prepare('SELECT id, author, initial, text, created_at FROM comments WHERE product_id = ? ORDER BY created_at DESC')
        .all(m[1])
        .map((c) => ({ id: c.id, author: c.author, initial: c.initial, text: c.text, ago: ago(c.created_at) })),
    };
  }],

  ['POST', /^\/api\/videos\/([^/]+)\/comments$/, async (body, m) => {
    const id = m[1];
    if (!videoExists(id)) return { error: 'video not found', status: 404 };
    const text = (body.text || '').toString().trim();
    if (!text) return { error: 'text required' };
    const author = 'Jorge';
    const initial = 'J';
    const r = db
      .prepare('INSERT INTO comments (product_id, author, initial, text, created_at) VALUES (?,?,?,?,?)')
      .run(id, author, initial, text, new Date().toISOString());
    return {
      comment: { id: r.lastInsertRowid, author, initial, text, ago: 'ahora' },
    };
  }],

  // ---------- tienda: CRUD de videos del negocio ----------

  ['GET', /^\/api\/videos\/mine$/, async () => ({
    videos: db
      .prepare(`${VIDEO_SELECT} WHERE v.owner = 'owner' ORDER BY v.created_at DESC`)
      .all()
      .map(rowToVideo),
  })],

  ['POST', /^\/api\/videos\/upload$/, async (body) => {
    const r = saveUpload(body.data, body.filename);
    if (r.error) return { error: r.error };
    return { url: r.url };
  }],

  ['POST', /^\/api\/videos$/, async (body) => {
    let pid = String(body.productId || '');
    if (pid) {
      if (!productById(pid)) return { error: 'unknown product', status: 404 };
    } else {
      const p = body.product;
      if (!p || !p.id || !p.name) {
        return { error: 'productId or product {id, name, unit, price, stock, emoji} required' };
      }
      if (productById(p.id)) return { error: 'product already exists', status: 409 };
      pid = String(p.id);
      db.prepare('INSERT INTO products (id, name, unit, price, stock, emoji, supplier) VALUES (?,?,?,?,?,?,?)')
        .run(pid, String(p.name), String(p.unit || 'pieza'),
          Math.max(0, parseInt(p.price, 10) || 0), Math.max(0, parseInt(p.stock, 10) || 0),
          String(p.emoji || '📦'), p.supplier ? String(p.supplier) : null);
    }
    if (videoExists(pid)) return { error: 'video already exists for this product', status: 409 };
    const caption = String(body.caption || '').trim();
    if (!caption) return { error: 'caption required' };
    const hashtags = Array.isArray(body.hashtags)
      ? body.hashtags.map(String).join(',')
      : String(body.hashtags || '').split(',').map((t) => t.trim()).filter(Boolean).join(',');
    const c1 = parseInt(body.c1, 10) || 0xFF7BC26B;
    const c2 = parseInt(body.c2, 10) || 0xFF24663A;
    const url = body.url ? String(body.url) : null;
    const owner = body.owner === 'seed' ? 'seed' : 'owner';
    db.prepare('INSERT INTO videos (product_id, caption, hashtags, c1, c2, base_likes, url, owner, created_at) VALUES (?,?,?,?,?,0,?,?,?)')
      .run(pid, caption, hashtags, c1, c2, url, owner, new Date().toISOString());
    addEvent('tl', 'Publicaste un video en la Tienda.', caption, 'Tienda');
    return { video: videoPayload(pid) };
  }],

  ['GET', /^\/api\/videos\/([^/]+)$/, async (_, m) => {
    const v = videoPayload(m[1]);
    if (!v) return { error: 'video not found', status: 404 };
    return { video: v };
  }],

  ['PUT', /^\/api\/videos\/([^/]+)$/, async (body, m) => {
    const id = m[1];
    if (!videoExists(id)) return { error: 'video not found', status: 404 };
    const sets = [];
    const vals = [];
    if (body.caption !== undefined) { sets.push('caption = ?'); vals.push(String(body.caption)); }
    if (body.hashtags !== undefined) {
      sets.push('hashtags = ?');
      vals.push(Array.isArray(body.hashtags) ? body.hashtags.map(String).join(',') : String(body.hashtags));
    }
    if (body.c1 !== undefined) { sets.push('c1 = ?'); vals.push(parseInt(body.c1, 10)); }
    if (body.c2 !== undefined) { sets.push('c2 = ?'); vals.push(parseInt(body.c2, 10)); }
    if (body.url !== undefined) { sets.push('url = ?'); vals.push(body.url === null ? null : String(body.url)); }
    if (sets.length) db.prepare(`UPDATE videos SET ${sets.join(', ')} WHERE product_id = ?`).run(...vals, id);
    const psets = [];
    const pvals = [];
    if (body.name !== undefined) { psets.push('name = ?'); pvals.push(String(body.name)); }
    if (body.unit !== undefined) { psets.push('unit = ?'); pvals.push(String(body.unit)); }
    if (body.emoji !== undefined) { psets.push('emoji = ?'); pvals.push(String(body.emoji)); }
    if (body.supplier !== undefined) { psets.push('supplier = ?'); pvals.push(body.supplier === null ? null : String(body.supplier)); }
    if (body.price !== undefined) { psets.push('price = ?'); pvals.push(Math.max(0, parseInt(body.price, 10) || 0)); }
    if (body.stock !== undefined) { psets.push('stock = ?'); pvals.push(Math.max(0, parseInt(body.stock, 10) || 0)); }
    if (psets.length) db.prepare(`UPDATE products SET ${psets.join(', ')} WHERE id = ?`).run(...pvals, id);
    return { video: videoPayload(id) };
  }],

  ['DELETE', /^\/api\/videos\/([^/]+)$/, async (_, m) => {
    const id = m[1];
    if (!videoExists(id)) return { error: 'video not found', status: 404 };
    db.prepare('DELETE FROM videos WHERE product_id = ?').run(id);
    db.prepare('DELETE FROM video_state WHERE product_id = ?').run(id);
    db.prepare('DELETE FROM comments WHERE product_id = ?').run(id);
    addEvent('tl', 'Quitaste un video de la Tienda.', null, 'Tienda');
    return { ok: true };
  }],

  // ---------- carrito ----------
  ['GET', /^\/api\/cart$/, async () => cartPayload()],

  ['POST', /^\/api\/cart$/, async (body) => {
    const id = String(body.productId || body.product_id || '');
    const qty = Math.max(1, parseInt(body.qty || 1, 10) || 1);
    if (!productById(id)) return { error: 'unknown product' };
    const stock = stockOf(id);
    db.prepare(`INSERT INTO cart (product_id, qty) VALUES (?, ?)
                ON CONFLICT(product_id) DO UPDATE SET qty = MIN(cart.qty + excluded.qty, ?)`)
      .run(id, Math.min(qty, stock), stock);
    return cartPayload();
  }],

  ['PUT', /^\/api\/cart\/([^/]+)$/, async (body, m) => {
    const id = m[1];
    if (!productById(id)) return { error: 'unknown product', status: 404 };
    const qty = parseInt(body.qty, 10) || 0;
    if (qty <= 0) {
      db.prepare('DELETE FROM cart WHERE product_id = ?').run(id);
    } else {
      db.prepare('UPDATE cart SET qty = MIN(?, ?) WHERE product_id = ?').run(qty, stockOf(id), id);
    }
    return cartPayload();
  }],

  ['DELETE', /^\/api\/cart\/([^/]+)$/, async (_, m) => {
    db.prepare('DELETE FROM cart WHERE product_id = ?').run(m[1]);
    return cartPayload();
  }],

  ['DELETE', /^\/api\/cart$/, async () => {
    db.exec('DELETE FROM cart');
    return cartPayload();
  }],

  // ---------- productos e inventario ----------
  ['GET', /^\/api\/products$/, async () => ({
    products: db.prepare('SELECT * FROM products ORDER BY id').all().map(mapProduct),
  })],

  ['GET', /^\/api\/products\/barcode\/([^/]+)$/, async (_, m) => {
    const p = db.prepare('SELECT * FROM products WHERE barcode = ?').get(m[1]);
    if (!p) return { error: 'product not found', status: 404 };
    return { product: mapProduct(p) };
  }],

  ['GET', /^\/api\/products\/([^/]+)$/, async (_, m) => {
    const p = productById(m[1]);
    if (!p) return { error: 'product not found', status: 404 };
    return { product: mapProduct(p) };
  }],

  ['POST', /^\/api\/products$/, async (body) => {
    const name = String(body.name || '').trim();
    if (!name) return { error: 'name required' };
    const id = body.id ? String(body.id) : `p${Date.now().toString(36)}`;
    if (productById(id)) return { error: 'id already exists', status: 409 };
    db.prepare('INSERT INTO products (id, name, unit, price, stock, emoji, supplier, avg_daily, barcode) VALUES (?,?,?,?,?,?,?,?,?)')
      .run(
        id,
        name,
        String(body.unit || 'pieza'),
        Math.max(0, parseInt(body.price, 10) || 0),
        Math.max(0, parseInt(body.stock, 10) || 0),
        String(body.emoji || '🛒'),
        body.supplier ? String(body.supplier) : null,
        body.avg_daily !== undefined ? Math.max(0, parseInt(body.avg_daily, 10) || 0) : null,
        body.barcode ? String(body.barcode) : null);
    return { product: mapProduct(productById(id)) };
  }],

  ['PUT', /^\/api\/products\/([^/]+)$/, async (body, m) => {
    const id = m[1];
    const p = productById(id);
    if (!p) return { error: 'product not found', status: 404 };
    const sets = [];
    const vals = [];
    const num = (v, d) => {
      const n = parseInt(v, 10);
      return Number.isFinite(n) ? n : d;
    };
    if (body.name !== undefined) { sets.push('name = ?'); vals.push(String(body.name)); }
    if (body.unit !== undefined) { sets.push('unit = ?'); vals.push(String(body.unit)); }
    if (body.emoji !== undefined) { sets.push('emoji = ?'); vals.push(String(body.emoji)); }
    if (body.supplier !== undefined) { sets.push('supplier = ?'); vals.push(body.supplier === null ? null : String(body.supplier)); }
    if (body.barcode !== undefined) { sets.push('barcode = ?'); vals.push(body.barcode === null ? null : String(body.barcode)); }
    if (body.price !== undefined) { sets.push('price = ?'); vals.push(Math.max(0, num(body.price, p.price))); }
    if (body.stock !== undefined) { sets.push('stock = ?'); vals.push(Math.max(0, num(body.stock, p.stock))); }
    if (body.avg_daily !== undefined) { sets.push('avg_daily = ?'); vals.push(Math.max(0, num(body.avg_daily, p.avg_daily))); }
    if (sets.length) db.prepare(`UPDATE products SET ${sets.join(', ')} WHERE id = ?`).run(...vals, id);
    return { product: mapProduct(productById(id)) };
  }],

  ['POST', /^\/api\/products\/([^/]+)\/stock$/, async (body, m) => {
    const id = m[1];
    if (!productById(id)) return { error: 'product not found', status: 404 };
    const delta = parseInt(body.delta, 10);
    if (!Number.isFinite(delta)) return { error: 'delta required (integer)' };
    db.prepare('UPDATE products SET stock = MAX(0, stock + ?) WHERE id = ?').run(delta, id);
    return { product: mapProduct(productById(id)) };
  }],

  // ---------- ventas ----------
  ['POST', /^\/api\/sales$/, async (body) => {
    let lines = parseLines(body);
    let fromCart = false;
    if (!lines) {
      const items = cartItems();
      if (items.length === 0) return { error: 'cart is empty and no lines provided' };
      lines = items.map((i) => ({ productId: i.productId, qty: i.qty }));
      fromCart = true;
    }
    if (lines.error) return lines;
    const payment = PAYMENTS.includes(body.payment) ? body.payment : 'efectivo';
    const authCode = body.authCode ? String(body.authCode) : null;
    const total = totalOfLines(lines);
    const id = `s${Date.now().toString(36)}${Math.floor(Math.random() * 46656).toString(36)}`;
    const at = timeNow();

    db.exec('BEGIN');
    try {
      db.prepare('INSERT INTO sales (id, total, payment, auth_code, at, created_at) VALUES (?,?,?,?,?,?)')
        .run(id, total, payment, authCode, at, new Date().toISOString());
      const insLine = db.prepare('INSERT INTO sale_lines (sale_id, product_id, qty) VALUES (?,?,?)');
      const updStock = db.prepare('UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?');
      for (const l of lines) {
        insLine.run(id, l.productId, l.qty);
        updStock.run(l.qty, l.productId);
      }
      if (fromCart) db.exec('DELETE FROM cart');
      db.exec('COMMIT');
    } catch (e) {
      db.exec('ROLLBACK');
      throw e;
    }

    addEvent('tl', `Venta por ${mxn(total)} (${payment}).`, authCode ? `Autorización: ${authCode}.` : null, 'Venta');
    addEvent('mem', `Registraste una venta de ${mxn(total)}.`,
      lines.map((l) => `${l.qty} × ${productName(l.productId)}`).join(', '), 'Registrado');
    return { sale: { id, total, payment, authCode, at, lines } };
  }],

  ['GET', /^\/api\/sales$/, async () => ({ sales: salesList() })],

  ['DELETE', /^\/api\/sales\/([^/]+)$/, async (_, m) => {
    const id = m[1];
    const sale = db.prepare('SELECT * FROM sales WHERE id = ?').get(id);
    if (!sale) return { error: 'sale not found', status: 404 };
    const lines = db.prepare('SELECT product_id, qty FROM sale_lines WHERE sale_id = ?').all(id);
    db.exec('BEGIN');
    try {
      const upd = db.prepare('UPDATE products SET stock = stock + ? WHERE id = ?');
      for (const l of lines) upd.run(l.qty, l.product_id);
      db.prepare('DELETE FROM sale_lines WHERE sale_id = ?').run(id);
      db.prepare('DELETE FROM sales WHERE id = ?').run(id);
      db.exec('COMMIT');
    } catch (e) {
      db.exec('ROLLBACK');
      throw e;
    }
    addEvent('tl', `Deshiciste una venta por ${mxn(sale.total)}.`, null, 'Venta');
    addEvent('mem', `Deshiciste una venta de ${mxn(sale.total)}.`, 'El inventario y la caja volvieron al estado anterior.', 'Registrado');
    return { ok: true };
  }],

  // ---------- entregas ----------
  ['POST', /^\/api\/deliveries$/, async (body) => {
    const lines = parseLines(body);
    if (!lines) return { error: 'lines required' };
    if (lines.error) return lines;
    const supplier = body.supplier ? String(body.supplier) : null;
    const total = body.total !== undefined && body.total !== null
      ? Math.max(0, parseInt(body.total, 10) || 0)
      : null;
    const id = `d${Date.now().toString(36)}${Math.floor(Math.random() * 46656).toString(36)}`;
    const at = timeNow();

    db.exec('BEGIN');
    try {
      db.prepare('INSERT INTO deliveries (id, supplier, total, at, created_at) VALUES (?,?,?,?,?)')
        .run(id, supplier, total, at, new Date().toISOString());
      const insLine = db.prepare('INSERT INTO delivery_lines (delivery_id, product_id, qty) VALUES (?,?,?)');
      const upd = db.prepare('UPDATE products SET stock = stock + ? WHERE id = ?');
      for (const l of lines) {
        insLine.run(id, l.productId, l.qty);
        upd.run(l.qty, l.productId);
      }
      db.exec('COMMIT');
    } catch (e) {
      db.exec('ROLLBACK');
      throw e;
    }

    const totalQty = lines.reduce((a, l) => a + l.qty, 0);
    const from = supplier ? ` de ${supplier}` : '';
    addEvent('tl', `Llegaron ${totalQty} unidades de mercadería${from}.`, null, 'Inventario');
    addEvent('mem', `Registraste una entrada de ${totalQty} unidades de mercadería${from}.`,
      total != null ? `Factura por ${mxn(total)}. Se actualizó el inventario automáticamente.` : 'Se actualizó el inventario automáticamente.',
      'Registrado');
    return { delivery: { id, supplier, total, at, lines } };
  }],

  // ---------- resumen / insights / compra / cierre / eventos / negocio ----------
  ['GET', /^\/api\/summary$/, async () => ({ summary: summary() })],

  ['GET', /^\/api\/insights$/, async () => ({ insights: insights() })],

  ['GET', /^\/api\/shopping$/, async () => ({
    items: insights().map((i) => ({
      productId: i.productId,
      name: i.name,
      emoji: i.emoji,
      qty: parseInt(i.recommendation.replace(/\D/g, ''), 10) || 1,
      reason: i.reason,
    })),
  })],

  ['POST', /^\/api\/closing$/, async (body) => {
    const s = summary();
    const id = `c${Date.now().toString(36)}${Math.floor(Math.random() * 46656).toString(36)}`;
    const at = timeNow();
    const note = body.note ? String(body.note) : null;
    db.prepare('INSERT INTO closes (id, total, ops, cash, card, transfer, combined, note, at, created_at) VALUES (?,?,?,?,?,?,?,?,?,?)')
      .run(id, s.salesTotal, s.salesCount, s.byPayment.efectivo, s.byPayment.tarjeta,
        s.byPayment.transferencia, s.byPayment.combinado, note, at, new Date().toISOString());
    addEvent('tl', 'Cierre del día registrado.', `Ventas totales: ${mxn(s.salesTotal)} (${s.salesCount} operaciones).`, 'Cierre');
    addEvent('mem', 'Preparaste el cierre del día.', `Caja en efectivo: ${mxn(s.byPayment.efectivo)}.`, 'Registrado');
    return {
      close: {
        id, total: s.salesTotal, ops: s.salesCount,
        cash: s.byPayment.efectivo, card: s.byPayment.tarjeta,
        transfer: s.byPayment.transferencia, combined: s.byPayment.combinado,
        note, at,
      },
    };
  }],

  ['GET', /^\/api\/closes$/, async () => ({
    closes: db.prepare('SELECT id, total, ops, cash, card, transfer, combined, note, at FROM closes ORDER BY created_at DESC, rowid DESC LIMIT 30').all(),
  })],

  ['GET', /^\/api\/events$/, async (_, __, url) => {
    const type = new URL(url, 'http://x').searchParams.get('type');
    return { events: eventsList(type === 'tl' ? 'tl' : type === 'mem' ? 'mem' : null) };
  }],

  ['GET', /^\/api\/business$/, async () => ({ business: business() })],

  ['POST', /^\/api\/lumo$/, async (body) => {
    if (!LUMO_API_KEY) {
      return { power: false, reply: null };
    }
    const text = body.text ? String(body.text) : '';
    if (!text.trim()) return { power: false, reply: null };
    const history = Array.isArray(body.history) ? body.history.slice(-10) : [];
    const s = summary();
    const low = insights().slice(0, 5);
    const system = [
      'Eres Lumo, la asistente de Carrota, una frutería/tienda local mexicana.',
      'Respondes en español, breve y con consejos prácticos sobre su negocio.',
      `Hoy: ventas ${mxn(s.salesTotal)} en ${s.salesCount} operaciones; efectivo ${mxn(s.byPayment.efectivo)}.`,
      low.length
        ? `Inventario urgente: ${low.map((i) => `${i.name} (${i.stock} ${i.unit} / vende ${i.avgDaily}/día) → ${i.recommendation}`).join('; ')}`
        : 'Inventario en orden.',
      'Si la pregunta es una venta ("vendí X"), NO la registres: responde que confirme la venta con el menú de voz y ayuda solo con lo que pida.',
    ].join('\n');
    const messages = [
      { role: 'system', content: system },
      ...history,
      { role: 'user', content: text },
    ];
    const res = await fetch(`${LUMO_BASE_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${LUMO_API_KEY}`,
      },
      body: JSON.stringify({ model: LUMO_MODEL, messages, temperature: 0.6, max_tokens: 300 }),
    });
    if (!res.ok) {
      console.error(`lumo upstream ${res.status}: ${await res.text()}`);
      return { power: false, reply: null, error: `upstream ${res.status}` };
    }
    const data = await res.json();
    const reply = data?.choices?.[0]?.message?.content || null;
    return reply ? { power: true, reply: reply.trim() } : { power: false, reply: null };
  }],
];
const server = http.createServer(async (req, res) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.url} <- ${req.socket.remoteAddress}`);
  const url = req.url.split('?')[0];
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return res.end();
  }
  if (req.method === 'GET' && url.startsWith('/uploads/')) {
    const name = path.basename(url);
    const file = path.join(UPLOAD_DIR, name);
    if (!name || !fs.existsSync(file)) return send(res, 404, { error: 'not found' });
    const ext = name.split('.').pop();
    res.writeHead(200, {
      'Content-Type': MIME_BY_EXT[ext] || 'application/octet-stream',
      'Access-Control-Allow-Origin': '*',
    });
    return fs.createReadStream(file).pipe(res);
  }
  try {
    for (const [method, pattern, handler] of routes) {
      if (req.method !== method) continue;
      const m = url.match(pattern);
      if (!m) continue;
      let body = {};
      if (req.method === 'POST' || req.method === 'PUT') {
        const limit = url === '/api/videos/upload' ? MAX_UPLOAD_BYTES * 2 : 1e6;
        try {
          body = await readBody(req, limit);
        } catch (e) {
          const tooLarge = e.message === 'body too large';
          return send(res, tooLarge ? 413 : 400, { error: tooLarge ? 'body too large' : 'invalid JSON body' });
        }
      }
      const result = await handler(body, m, req.url);
      if (result && result.error) return send(res, result.status || 400, result);
      return send(res, 200, result);
    }
    send(res, 404, { error: 'not found' });
  } catch (e) {
    console.error(e);
    send(res, 500, { error: String(e) });
  }
});

server.listen(PORT, '0.0.0.0', () => {
  const port = server.address().port;
  console.log(`Carrota API escuchando en http://0.0.0.0:${port}`);
  console.log(`DB: ${DB_PATH}`);
  console.log(`LISTENING ${port}`);
});
